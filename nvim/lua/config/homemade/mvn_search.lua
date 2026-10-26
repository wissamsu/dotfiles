local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local curl = require("plenary.curl")

local M = {}

local URL = "https://search.maven.org/solrsearch/select"
local SCOPES = { "compile", "test", "provided", "runtime" }
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
    query = { q = query, rows = 30, wt = "json" },
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

local function show_picker(query, docs)
  if #docs == 0 then
    return vim.notify("MvnSearch: no results for '" .. query .. "'", vim.log.levels.WARN)
  end

  pickers.new({}, {
    prompt_title = "Maven: " .. query,
    finder = finders.new_table({
      results = docs,
      entry_maker = function(d)
        local s = ("%s:%s:%s"):format(d.g, d.a, d.latestVersion or "?")
        return { value = d, display = s, ordinal = s }
      end,
    }),
    sorter = conf.generic_sorter({}),
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
    cache[query] = docs
    show_picker(query, docs)
  end)
end

return M
