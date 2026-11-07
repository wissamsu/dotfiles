local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local curl = require("plenary.curl")

local M = {}

local URL = "https://search.maven.org/solrsearch/select"
local DEPS_URL = "https://api.deps.dev" -- stars / dependents / license / advisories
local SCOPES = { "compile", "test", "provided", "runtime", "import" }
local ATTEMPTS = 10
local cache = {} -- query -> docs, lasts until Neovim restarts

-- Sections whose <dependencies> blocks should NOT be touched
local SKIP_TAGS = { "dependencyManagement", "pluginManagement", "build", "profiles", "reporting" }

local function err(msg)
  vim.notify("MvnSearch: " .. msg, vim.log.levels.ERROR)
end

local function snippet(s)
  s = tostring(s or ""):gsub("%s+", " ")
  return #s > 200 and (s:sub(1, 200) .. "...") or s
end

local function coords(d)
  return ("%s:%s:%s"):format(d.g, d.a, d.latestVersion or "?")
end

-- Build the dependency as a list of lines, indented with `indent`/`unit`
local function dep_lines(d, scope, indent, unit)
  local lines = {
    indent .. "<dependency>",
    indent .. unit .. "<groupId>" .. d.g .. "</groupId>",
    indent .. unit .. "<artifactId>" .. d.a .. "</artifactId>",
    indent .. unit .. "<version>" .. (d.latestVersion or "") .. "</version>",
  }
  -- compile is Maven's default, so omit it
  if scope ~= "compile" then
    table.insert(lines, indent .. unit .. "<scope>" .. scope .. "</scope>")
  end
  table.insert(lines, indent .. "</dependency>")
  return lines
end

---------------------------------------------------------------------------
-- Formatting helpers
---------------------------------------------------------------------------

-- "today", "5d ago", "3mo ago", "2.4y ago" from a Unix time in milliseconds
local function ago(ms)
  if type(ms) ~= "number" then return "?" end
  local days = math.floor((os.time() - ms / 1000) / 86400)
  if days < 1 then return "today" end
  if days < 30 then return days .. "d ago" end
  if days < 365 then return math.floor(days / 30) .. "mo ago" end
  return ("%.1fy ago"):format(days / 365)
end

-- 1234 -> "1.2k", 2500000 -> "2.5M"
local function human(n)
  if type(n) ~= "number" then return "?" end
  if n >= 1e6 then return ("%.1fM"):format(n / 1e6) end
  if n >= 1e3 then return ("%.1fk"):format(n / 1e3) end
  return ("%d"):format(n)
end

local function urlenc(s)
  return (tostring(s):gsub("[^%w%-%._~]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

---------------------------------------------------------------------------
-- pom.xml handling
---------------------------------------------------------------------------

local function find_pom()
  local name = vim.api.nvim_buf_get_name(0)
  if name:match("pom%.xml$") then
    return name
  end
  local start = (name ~= "" and vim.fs.dirname(name)) or vim.loop.cwd()
  return vim.fs.find("pom.xml", { upward = true, path = start })[1]
end

-- Guess the indentation unit used by the file (defaults to 4 spaces)
local function detect_unit(lines)
  for _, l in ipairs(lines) do
    local ws = l:match("^(%s+)<")
    if ws then return ws end
  end
  return "    "
end

-- Locate the project-level <dependencies> block.
-- Returns open_line, close_line (1-based). If self-closing, both are equal.
local function find_dependencies(lines)
  local depth, open_i = 0, nil
  for i, line in ipairs(lines) do
    for _, tag in ipairs(SKIP_TAGS) do
      local opens = select(2, line:gsub("<" .. tag .. ">", ""))
      local closes = select(2, line:gsub("</" .. tag .. ">", ""))
      depth = depth + opens - closes
    end
    if depth == 0 then
      if not open_i then
        if line:match("^%s*<dependencies>%s*$") then
          open_i = i
        elseif line:match("^%s*<dependencies%s*/>%s*$") then
          return i, i
        end
      elseif line:match("</dependencies>") then
        return open_i, i
      end
    end
  end
  return nil, nil
end

local function already_declared(lines, open_i, close_i, d)
  local block = table.concat(lines, "\n", open_i, close_i)
  for body in block:gmatch("<dependency>(.-)</dependency>") do
    local g = body:match("<groupId>%s*(.-)%s*</groupId>")
    local a = body:match("<artifactId>%s*(.-)%s*</artifactId>")
    if g == d.g and a == d.a then return true end
  end
  return false
end

local function add_to_pom(d, scope)
  local path = find_pom()
  if not path then
    return err("no pom.xml found (looked upward from the current file)")
  end

  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local unit = detect_unit(lines)
  local label = ("%s:%s:%s"):format(d.g, d.a, d.latestVersion or "?")

  local open_i, close_i = find_dependencies(lines)

  if open_i and open_i ~= close_i then
    -- Normal case: existing <dependencies> ... </dependencies>
    if already_declared(lines, open_i, close_i, d) then
      return vim.notify(("MvnSearch: %s:%s is already in %s"):format(d.g, d.a, vim.fn.fnamemodify(path, ":.")),
        vim.log.levels.WARN)
    end
    local base = lines[close_i]:match("^(%s*)") or ""
    local child = base .. unit
    -- Prefer the indentation of an existing <dependency> if there is one
    for i = open_i + 1, close_i - 1 do
      local ws = lines[i]:match("^(%s*)<dependency>")
      if ws then
        child = ws
        break
      end
    end
    local child_unit = child:sub(#base + 1)
    if child_unit == "" then child_unit = unit end
    vim.api.nvim_buf_set_lines(bufnr, close_i - 1, close_i - 1, false, dep_lines(d, scope, child, child_unit))
  elseif open_i then
    -- Self-closing <dependencies/>: expand it
    local base = lines[open_i]:match("^(%s*)") or ""
    local new = { base .. "<dependencies>" }
    vim.list_extend(new, dep_lines(d, scope, base .. unit, unit))
    table.insert(new, base .. "</dependencies>")
    vim.api.nvim_buf_set_lines(bufnr, open_i - 1, open_i, false, new)
  else
    -- No <dependencies> block: create one before </project>
    local proj_close
    for i = #lines, 1, -1 do
      if lines[i]:match("</project>") then
        proj_close = i
        break
      end
    end
    if not proj_close then
      return err("couldn't find </project> in " .. path)
    end
    local new = { unit .. "<dependencies>" }
    vim.list_extend(new, dep_lines(d, scope, unit .. unit, unit))
    table.insert(new, unit .. "</dependencies>")
    vim.api.nvim_buf_set_lines(bufnr, proj_close - 1, proj_close - 1, false, new)
  end

  -- Save the pom (works whether or not the buffer is currently visible)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent write")
  end)
  vim.notify(("Added %s (%s) to %s"):format(label, scope, vim.fn.fnamemodify(path, ":.")))
end

---------------------------------------------------------------------------
-- Maven Central search
---------------------------------------------------------------------------

-- Fast-fail fetch: abort slow requests at curl level and retry
local function fetch(query, attempt, on_done)
  local function retry_or_fail(msg)
    if attempt < ATTEMPTS then
      return fetch(query, attempt + 1, on_done)
    end
    err(("%s (after %d attempts)"):format(msg, ATTEMPTS))
  end

  curl.get(URL, {
    query = { q = query, rows = 100, wt = "json" },
    headers = { accept = "application/json" },
    raw = { "--ipv4", "--connect-timeout", "2", "--max-time", "3" },
    on_error = vim.schedule_wrap(function(e)
      retry_or_fail(("request failed (exit %s): %s"):format(
        tostring(e.exit), snippet(e.stderr or e.message)))
    end),
    callback = vim.schedule_wrap(function(res)
      if not res or res.status ~= 200 then
        return retry_or_fail(("HTTP %s: %s"):format(
          tostring(res and res.status), snippet(res and res.body)))
      end
      local ok, data = pcall(vim.json.decode, res.body)
      if not ok or type(data) ~= "table" or type(data.response) ~= "table"
          or type(data.response.docs) ~= "table" then
        return retry_or_fail("bad response: " .. snippet(res.body))
      end
      on_done(data.response.docs)
    end),
  })
end

---------------------------------------------------------------------------
-- Popularity / health stats (deps.dev)
--
-- Maven Central itself only tells us when the latest version was released
-- and how many versions exist (both already in the search response). Stars,
-- usage and the rest come from deps.dev, fetched lazily for whichever entry
-- is highlighted and cached for the rest of the session.
---------------------------------------------------------------------------

local stats_cache = {}   -- "g:a:version" -> stats table
local stats_waiting = {} -- same key -> callbacks waiting on an in-flight lookup

-- GET a JSON document. cb(data) on success, cb(nil, status) otherwise.
-- status is the HTTP code, or nil for transport/parse errors.
local function get_json(url, cb)
  curl.get(url, {
    headers = { accept = "application/json" },
    raw = { "--ipv4", "--connect-timeout", "3", "--max-time", "6" },
    on_error = vim.schedule_wrap(function()
      cb(nil, nil)
    end),
    callback = vim.schedule_wrap(function(res)
      if not res or res.status ~= 200 then
        return cb(nil, res and res.status)
      end
      local ok, data = pcall(vim.json.decode, res.body)
      if not ok or type(data) ~= "table" then
        return cb(nil, nil)
      end
      cb(data)
    end),
  })
end

-- Prefer the SOURCE_REPO project, fall back to whatever project is listed
local function pick_repo(projects)
  local fallback
  for _, p in ipairs(projects or {}) do
    local id = p.projectKey and p.projectKey.id
    if id then
      if p.relationType == "SOURCE_REPO" then return id end
      fallback = fallback or id
    end
  end
  return fallback
end

local function load_stats(d, cb)
  local ver = d.latestVersion
  if not ver then return cb({ not_found = true }) end

  local key = coords(d)
  if stats_cache[key] then return cb(stats_cache[key]) end
  if stats_waiting[key] then
    table.insert(stats_waiting[key], cb)
    return
  end
  stats_waiting[key] = { cb }

  local st = {}
  local pending = 2
  local function done()
    pending = pending - 1
    if pending > 0 then return end
    -- don't cache lookups that hit network trouble, so the next view retries
    if not st.network_error then stats_cache[key] = st end
    local waiting = stats_waiting[key]
    stats_waiting[key] = nil
    for _, f in ipairs(waiting) do f(st) end
  end

  local pkg = urlenc(d.g .. ":" .. d.a)
  local version_url = ("%s/v3/systems/maven/packages/%s/versions/%s"):format(DEPS_URL, pkg, urlenc(ver))

  -- 1) version details -> source repo -> project stats (stars, forks, ...)
  get_json(version_url, function(v, status)
    if not v then
      if status == 404 then st.not_found = true else st.network_error = true end
      return done()
    end
    st.licenses = v.licenses
    st.advisories = type(v.advisoryKeys) == "table" and #v.advisoryKeys or 0
    st.deprecated = v.isDeprecated
    local repo = pick_repo(v.relatedProjects)
    if not repo then return done() end
    st.repo = repo
    get_json(DEPS_URL .. "/v3/projects/" .. urlenc(repo), function(p, pstatus)
      if p then
        st.stars, st.forks, st.issues = p.starsCount, p.forksCount, p.openIssuesCount
        st.score = p.scorecard and p.scorecard.overallScore
      elseif pstatus ~= 404 then
        st.network_error = true
      end
      done()
    end)
  end)

  -- 2) dependents: how many other packages depend on this one.
  -- This lives in deps.dev's v3alpha API (not in the stable v3 docs), so treat
  -- it as best-effort: if it's missing or fails, the row is simply left out.
  local dependents_url = ("%s/v3alpha/systems/maven/packages/%s/versions/%s:dependents")
      :format(DEPS_URL, pkg, urlenc(ver))
  get_json(dependents_url, function(x)
    if x then
      st.dependents = x.dependentCount
      st.direct_dependents = x.directDependentCount
    end
    done()
  end)
end

local function add_row(lines, label, value)
  if value ~= nil and value ~= "" then
    table.insert(lines, ("%-14s %s"):format(label .. ":", value))
  end
end

-- st == nil means "still loading"
local function preview_lines(d, st)
  local lines = { ("%s:%s"):format(d.g, d.a), "" }

  add_row(lines, "Latest", ("%s (%s)"):format(d.latestVersion or "?", ago(d.timestamp)))
  if type(d.timestamp) == "number" then
    add_row(lines, "Released", os.date("%Y-%m-%d", math.floor(d.timestamp / 1000)))
  end
  add_row(lines, "Versions", d.versionCount and human(d.versionCount))
  add_row(lines, "Packaging", d.p)
  table.insert(lines, "")

  if not st then
    table.insert(lines, "Loading from deps.dev ...")
    return lines
  end

  if st.not_found then
    table.insert(lines, "Not indexed by deps.dev (no stars/usage data).")
    return lines
  end

  add_row(lines, "Stars", st.stars and human(st.stars))
  add_row(lines, "Forks", st.forks and human(st.forks))
  add_row(lines, "Open issues", st.issues and human(st.issues))
  if st.dependents then
    local s = human(st.dependents)
    if st.direct_dependents then
      s = s .. (" (%s direct)"):format(human(st.direct_dependents))
    end
    add_row(lines, "Dependents", s)
  end
  add_row(lines, "OpenSSF score", type(st.score) == "number" and ("%.1f / 10"):format(st.score) or nil)
  add_row(lines, "License",
    type(st.licenses) == "table" and #st.licenses > 0 and table.concat(st.licenses, ", ") or nil)
  if st.advisories ~= nil then
    add_row(lines, "Advisories", st.advisories == 0 and "none known for this version"
      or ("%d known for this version"):format(st.advisories))
  end
  if st.deprecated then add_row(lines, "Deprecated", "yes") end
  add_row(lines, "Source", st.repo)

  if not st.repo then
    table.insert(lines, "")
    table.insert(lines, "No linked source repo, so no star/fork data.")
  end
  if st.network_error then
    table.insert(lines, "")
    table.insert(lines, "deps.dev was unreachable for part of this; data may be incomplete.")
  end
  return lines
end

local function stats_previewer()
  return previewers.new_buffer_previewer({
    title = "Details",
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr -- a fresh buffer per entry, wiped when you move on
      local d = entry.value
      local function render(st)
        if vim.api.nvim_buf_is_valid(bufnr) then
          pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, preview_lines(d, st))
        end
      end
      render(nil)
      load_stats(d, render)
    end,
  })
end

---------------------------------------------------------------------------
-- Picker
---------------------------------------------------------------------------

local function make_entry_maker(docs)
  local width = 20
  for _, d in ipairs(docs) do
    width = math.max(width, #coords(d))
  end
  width = math.min(width, 70)

  local displayer = entry_display.create({
    separator = "  ",
    items = { { width = width }, { width = 9 }, { remaining = true } },
  })

  return function(d)
    local c = coords(d)
    return {
      value = d,
      ordinal = c,
      display = function()
        return displayer({
          c,
          { ago(d.timestamp),                              "Comment" },
          { ("%s versions"):format(human(d.versionCount)), "Comment" },
        })
      end,
    }
  end
end

local function show_picker(query, docs)
  if #docs == 0 then
    return vim.notify("MvnSearch: no results for '" .. query .. "'", vim.log.levels.WARN)
  end

  pickers.new({}, {
    prompt_title = "Maven: " .. query,
    finder = finders.new_table({
      results = docs,
      entry_maker = make_entry_maker(docs),
    }),
    sorter = conf.generic_sorter({}),
    previewer = stats_previewer(),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(bufnr)
        if not sel then return end
        vim.ui.select(SCOPES, { prompt = "Scope:" }, function(scope)
          if not scope then return end
          add_to_pom(sel.value, scope)
        end)
      end)
      return true
    end,
  }):find()
end

function M.search(query)
  query = query or vim.fn.input("Maven search: ")
  if query == "" then return end

  if cache[query] then
    return show_picker(query, cache[query])
  end

  vim.notify("MvnSearch: searching '" .. query .. "'...")
  fetch(query, 1, function(docs)
    table.sort(docs, function(a, b)
      return (a.versionCount or 0) > (b.versionCount or 0)
    end)
    cache[query] = docs
    show_picker(query, docs)
  end)
end

return M
