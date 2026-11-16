local pickers, finders, previewers, entry_display, conf, actions, action_state

local function load_telescope()
  if pickers then return end
  -- make sure lazy.nvim has put telescope on the runtimepath
  local ok, lazy = pcall(require, "lazy")
  if ok then lazy.load({ plugins = { "telescope.nvim" } }) end

  pickers = require("telescope.pickers")
  finders = require("telescope.finders")
  previewers = require("telescope.previewers")
  entry_display = require("telescope.pickers.entry_display")
  conf = require("telescope.config").values
  actions = require("telescope.actions")
  action_state = require("telescope.actions.state")
end
local M = {}

local cache = {}
local details_cache = {}
local details_waiting = {}

local function err(msg)
  vim.notify("GHAction: " .. msg, vim.log.levels.ERROR)
end

local function val(x)
  if x == nil or x == vim.NIL then return nil end
  return x
end

local function human(n)
  if type(n) ~= "number" then return "?" end
  if n >= 1e6 then return ("%.1fM"):format(n / 1e6) end
  if n >= 1e3 then return ("%.1fk"):format(n / 1e3) end
  return ("%d"):format(n)
end

local function parse_iso(s)
  local y, m, d, H, Mi, S = tostring(s or ""):match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z$")
  if not y then return nil end
  local t = os.time({ year = y, month = m, day = d, hour = H, min = Mi, sec = S })
  return t + (os.time() - os.time(os.date("!*t"))) -- treat as UTC
end

local function ago(epoch)
  if type(epoch) ~= "number" then return "?" end
  local days = math.floor((os.time() - epoch) / 86400)
  if days < 1 then return "today" end
  if days < 30 then return days .. "d ago" end
  if days < 365 then return math.floor(days / 30) .. "mo ago" end
  return ("%.1fy ago"):format(days / 365)
end

local function trunc(s, n)
  s = tostring(s or ""):gsub("%s+", " ")
  return #s > n and (s:sub(1, n) .. "...") or s
end

---------------------------------------------------------------------------
-- gh helpers
---------------------------------------------------------------------------

local function gh(args, cb)
  vim.system(vim.list_extend({ "gh" }, args), { text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      return cb(nil, vim.trim(res.stderr or ""))
    end
    cb(res.stdout)
  end))
end

local function gh_json(args, cb)
  gh(args, function(out, e)
    if not out then return cb(nil, e) end
    local ok, data = pcall(vim.json.decode, out)
    if not ok then return cb(nil, "bad json") end
    cb(data)
  end)
end

local function is_missing(e)
  return e and e:match("404") ~= nil
end

---------------------------------------------------------------------------
-- action.yml parsing (best effort, no yaml dependency)
---------------------------------------------------------------------------

local function unquote(s)
  s = vim.trim(s or "")
  local q = s:match('^"(.*)"$') or s:match("^'(.*)'$")
  if q then return q end
  return (s:gsub("%s+#.*$", ""))
end

local function parse_action_yml(text)
  local out = { inputs = {} }
  local section, key_indent, cur

  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    if not line:match("^%s*#") and not line:match("^%s*$") then
      local top, rest = line:match("^([%w_%-]+):%s*(.*)$")
      if top then
        section, cur = top, nil
        if top == "name" then out.name = unquote(rest) end
        if top == "description" then out.description = unquote(rest) end
      elseif section == "inputs" then
        local ind, name = line:match("^(%s+)([%w_%-%.]+):%s*$")
        if ind and (not key_indent or #ind == key_indent) then
          key_indent = key_indent or #ind
          cur = { name = name }
          table.insert(out.inputs, cur)
        elseif cur then
          if cur.pending_desc then
            cur.description = vim.trim(line)
            cur.pending_desc = nil
          else
            local ind2, k, v = line:match("^(%s+)([%w_%-]+):%s*(.*)$")
            if k and #ind2 > key_indent then
              if k == "required" then
                cur.required = unquote(v) == "true"
              elseif k == "default" then
                cur.default = unquote(v)
              elseif k == "description" then
                if v:match("^[>|][+-]?$") then
                  cur.pending_desc = true
                else
                  cur.description = unquote(v)
                end
              end
            end
          end
        end
      elseif section == "runs" then
        local u = line:match("^%s+using:%s*(.+)$")
        if u then out.using = unquote(u) end
      end
    end
  end
  return out
end

---------------------------------------------------------------------------
-- details (latest release + action.yml), cached and de-duplicated
---------------------------------------------------------------------------

local function load_details(d, cb)
  local key = d.full_name
  if details_cache[key] then return cb(details_cache[key]) end
  if details_waiting[key] then
    table.insert(details_waiting[key], cb)
    return
  end
  details_waiting[key] = { cb }

  local st = {}
  local pending = 2
  local function done()
    pending = pending - 1
    if pending > 0 then return end
    if not st.network_error then details_cache[key] = st end
    local waiting = details_waiting[key]
    details_waiting[key] = nil
    for _, f in ipairs(waiting) do f(st) end
  end

  gh_json({ "api", ("repos/%s/releases/latest"):format(key) }, function(r, e)
    if r and r.tag_name then
      st.tag, st.released = r.tag_name, val(r.published_at)
      return done()
    end
    if e and not is_missing(e) then st.network_error = true end
    gh_json({ "api", ("repos/%s/tags?per_page=1"):format(key) }, function(t, e2)
      if t and t[1] then
        st.tag = t[1].name
      elseif e2 and not is_missing(e2) then
        st.network_error = true
      end
      done()
    end)
  end)

  local function try(file, fallback)
    gh({ "api", ("repos/%s/contents/%s"):format(key, file),
      "-H", "Accept: application/vnd.github.raw+json" }, function(out, e)
      if out then
        st.action = parse_action_yml(out)
        return done()
      end
      if fallback then return try(fallback) end
      if e and not is_missing(e) then st.network_error = true else st.no_action_file = true end
      done()
    end)
  end
  try("action.yml", "action.yaml")
end

-- v4.2.1 -> v4 if the floating major tag actually exists, else the exact tag
local function resolve_ref(d, st, cb)
  local tag = st.tag
  if not tag then return cb(d.default_branch or "main") end
  local major = tag:match("^(v%d+)%.")
  if not major then return cb(tag) end
  gh({ "api", ("repos/%s/git/ref/tags/%s"):format(d.full_name, major) }, function(out)
    cb(out and major or tag)
  end)
end

---------------------------------------------------------------------------
-- inserting into the workflow (or copying)
---------------------------------------------------------------------------

local function in_workflow(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:match("%.github/workflows/[^/]+%.ya?ml$") ~= nil
end

local function step_indent(buf, row)
  for r = row, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1] or ""
    local ind = line:match("^(%s*)%- ")
    if ind then return ind end
  end
  return "      "
end

local function place(ctx, d, ref, inputs)
  local rel = { "- uses: " .. d.full_name .. "@" .. ref }
  if inputs and #inputs > 0 then
    table.insert(rel, "  with:")
    for _, i in ipairs(inputs) do
      table.insert(rel, ("    %s: "):format(i.name))
    end
  end
  local label = d.full_name .. "@" .. ref

  if vim.api.nvim_buf_is_valid(ctx.buf) and in_workflow(ctx.buf) then
    local indent = step_indent(ctx.buf, ctx.row)
    local new = vim.tbl_map(function(l) return indent .. l end, rel)
    local cur = vim.api.nvim_buf_get_lines(ctx.buf, ctx.row - 1, ctx.row, false)[1] or ""
    local first
    if cur:match("^%s*$") then
      vim.api.nvim_buf_set_lines(ctx.buf, ctx.row - 1, ctx.row, false, new)
      first = ctx.row
    else
      vim.api.nvim_buf_set_lines(ctx.buf, ctx.row, ctx.row, false, new)
      first = ctx.row + 1
    end
    if vim.api.nvim_win_is_valid(ctx.win) and vim.api.nvim_win_get_buf(ctx.win) == ctx.buf then
      pcall(vim.api.nvim_win_set_cursor, ctx.win, { first + #new - 1, #new[#new] })
    end
    vim.notify("GHAction: inserted " .. label)
  else
    local text = table.concat(rel, "\n")
    vim.fn.setreg("+", text)
    vim.fn.setreg('"', text)
    vim.notify("GHAction: copied " .. label)
  end
end

local function apply(ctx, d, with_inputs)
  load_details(d, function(st)
    resolve_ref(d, st, function(ref)
      local inputs
      if with_inputs and st.action then
        inputs = vim.tbl_filter(function(i)
          return i.required and not i.default
        end, st.action.inputs)
      end
      place(ctx, d, ref, inputs)
    end)
  end)
end

---------------------------------------------------------------------------
-- preview
---------------------------------------------------------------------------

local function add_row(lines, label, value)
  if value ~= nil and value ~= "" then
    table.insert(lines, ("%-13s %s"):format(label .. ":", value))
  end
end

local function preview_lines(d, st)
  local lines = { "# " .. d.full_name, "" }

  local desc = val(d.description)
  if desc and desc ~= "" then
    table.insert(lines, desc)
    table.insert(lines, "")
  end

  add_row(lines, "Stars", human(d.stargazers_count))
  add_row(lines, "Forks", human(d.forks_count))
  add_row(lines, "Open issues", human(d.open_issues_count))
  add_row(lines, "Last push", ago(parse_iso(d.pushed_at)))

  local lic = val(d.license) and val(d.license.spdx_id)
  if lic and lic ~= "NOASSERTION" then add_row(lines, "License", lic) end

  local topics = vim.tbl_filter(function(t) return t ~= "github-actions" end, d.topics or {})
  if #topics > 0 then
    add_row(lines, "Topics", table.concat(vim.list_slice(topics, 1, 8), ", "))
  end
  if d.archived then add_row(lines, "Status", "ARCHIVED") end

  if not st then
    table.insert(lines, "")
    table.insert(lines, "Loading from GitHub ...")
    return lines
  end

  if st.tag then
    local when = st.released and (" (" .. ago(parse_iso(st.released)) .. ")") or ""
    add_row(lines, "Latest", st.tag .. when)
  else
    add_row(lines, "Latest", "no releases or tags")
  end
  if st.action then add_row(lines, "Runtime", st.action.using) end
  add_row(lines, "Repo", d.html_url)

  local ref = st.tag and (st.tag:match("^(v%d+)%.") or st.tag) or d.default_branch
  local required = {}
  if st.action then
    for _, i in ipairs(st.action.inputs) do
      if i.required and not i.default then table.insert(required, i) end
    end
  end

  table.insert(lines, "")
  table.insert(lines, "## Usage")
  table.insert(lines, "```yaml")
  table.insert(lines, "- uses: " .. d.full_name .. "@" .. ref)
  if #required > 0 then
    table.insert(lines, "  with:")
    for _, i in ipairs(required) do
      table.insert(lines, ("    %s: "):format(i.name))
    end
  end
  table.insert(lines, "```")

  if st.no_action_file then
    table.insert(lines, "")
    table.insert(lines, "No action.yml at the repo root (monorepo of actions, or not an action).")
  elseif st.action and #st.action.inputs > 0 then
    table.insert(lines, "")
    table.insert(lines, "## Inputs")
    local sorted = vim.deepcopy(st.action.inputs)
    table.sort(sorted, function(a, b)
      return (a.required and 1 or 0) > (b.required and 1 or 0)
    end)
    for n, i in ipairs(sorted) do
      if n > 15 then
        table.insert(lines, ("- ... and %d more"):format(#sorted - 15))
        break
      end
      local s = "- " .. i.name
      if i.required then s = s .. " (required)" end
      if i.default and i.default ~= "" then s = s .. " [default: " .. trunc(i.default, 30) .. "]" end
      if i.description and i.description ~= "" then s = s .. " - " .. trunc(i.description, 100) end
      table.insert(lines, s)
    end
  elseif st.action then
    table.insert(lines, "")
    table.insert(lines, "This action takes no inputs.")
  end

  if st.network_error then
    table.insert(lines, "")
    table.insert(lines, "GitHub was unreachable or rate limited for part of this; data may be incomplete.")
  end
  return lines
end

local function details_previewer()
  return previewers.new_buffer_previewer({
    title = "Details",
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr
      local d = entry.value

      vim.bo[bufnr].filetype = "markdown"
      if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
        vim.wo[self.state.winid].wrap = true
      end

      local function render(st)
        if vim.api.nvim_buf_is_valid(bufnr) then
          pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, preview_lines(d, st))
        end
      end
      render(nil)

      -- debounce so scrolling quickly doesn't fire requests for every row
      self.state.token = (self.state.token or 0) + 1
      local mine = self.state.token
      vim.defer_fn(function()
        if self.state.token == mine then load_details(d, render) end
      end, 150)
    end,
  })
end

---------------------------------------------------------------------------
-- picker
---------------------------------------------------------------------------

local function make_entry_maker(items)
  local width = 20
  for _, d in ipairs(items) do width = math.max(width, #d.full_name) end
  width = math.min(width, 45)

  local displayer = entry_display.create({
    separator = "  ",
    items = { { width = width }, { width = 8 }, { width = 9 }, { remaining = true } },
  })

  return function(d)
    local desc = val(d.description) or ""
    if d.archived then desc = "[archived] " .. desc end
    return {
      value = d,
      ordinal = d.full_name .. " " .. desc,
      display = function()
        return displayer({
          d.full_name,
          { "* " .. human(d.stargazers_count), "Special" },
          { ago(parse_iso(d.pushed_at)),       "Comment" },
          { desc,                              "Comment" },
        })
      end,
    }
  end
end

local function show_picker(ctx, query, items)
  load_telescope()
  if #items == 0 then
    return vim.notify("GHAction: no results for '" .. query .. "'", vim.log.levels.WARN)
  end

  pickers.new({}, {
    prompt_title = "GitHub Actions: " .. query,
    results_title = "<CR> insert  <C-a> +required inputs  <C-o> open",
    finder = finders.new_table({
      results = items,
      entry_maker = make_entry_maker(items),
    }),
    sorter = conf.generic_sorter({}),
    previewer = details_previewer(),
    attach_mappings = function(bufnr, map)
      local function choose(with_inputs)
        return function()
          local sel = action_state.get_selected_entry()
          actions.close(bufnr)
          if sel then apply(ctx, sel.value, with_inputs) end
        end
      end
      actions.select_default:replace(choose(false))
      map({ "i", "n" }, "<C-a>", choose(true))
      map({ "i", "n" }, "<C-o>", function()
        local sel = action_state.get_selected_entry()
        if sel then vim.ui.open(sel.value.html_url) end
      end)
      return true
    end,
  }):find()
end

local SEARCHES = {
  "%s topic:github-actions",
  "%s topic:github-action",
  '%s "GitHub Action" in:description',
}

local MAX_CANDIDATES = 100
local CONCURRENCY = 10
local action_file_cache = {}

-- true if the repo has action.yml / action.yaml at its root.
-- On errors other than 404 (rate limit, network) we keep the repo rather than hide it.
local function has_action_file(repo, cb)
  if action_file_cache[repo] ~= nil then return cb(action_file_cache[repo]) end

  local function try(file, fallback)
    gh({ "api", ("repos/%s/contents/%s"):format(repo, file), "--jq", ".name" }, function(out, e)
      if out then
        action_file_cache[repo] = true
        return cb(true)
      end
      if fallback then return try(fallback) end
      if is_missing(e) then
        action_file_cache[repo] = false
        return cb(false)
      end
      cb(true)
    end)
  end
  try("action.yml", "action.yaml")
end

-- verify candidates with a small worker pool, preserving order
local function filter_actions(items, cb)
  local total = #items
  if total == 0 then return cb({}) end

  local keep, idx, running, finished = {}, 0, 0, 0

  local function launch()
    while running < CONCURRENCY and idx < total do
      idx = idx + 1
      local it = items[idx]
      running = running + 1
      has_action_file(it.full_name, function(ok)
        running = running - 1
        finished = finished + 1
        if ok then keep[it.full_name] = true end
        if finished == total then
          cb(vim.tbl_filter(function(x) return keep[x.full_name] end, items))
        else
          launch()
        end
      end)
    end
  end
  launch()
end

local function search_all(query, cb)
  local merged, seen = {}, {}
  local pending, any_ok, last_err = #SEARCHES, false, nil

  for _, tpl in ipairs(SEARCHES) do
    gh_json({
      "api", "-X", "GET", "search/repositories",
      "-f", "q=" .. tpl:format(query),
      "-f", "sort=stars",
      "-f", "per_page=100",
    }, function(data, e)
      if data and type(data.items) == "table" then
        any_ok = true
        for _, it in ipairs(data.items) do
          if not seen[it.full_name] then
            seen[it.full_name] = true
            table.insert(merged, it)
          end
        end
      else
        last_err = e
      end

      pending = pending - 1
      if pending == 0 then
        if not any_ok then return cb(nil, last_err) end
        table.sort(merged, function(a, b)
          return (a.stargazers_count or 0) > (b.stargazers_count or 0)
        end)
        merged = vim.list_slice(merged, 1, MAX_CANDIDATES)
        filter_actions(merged, function(actions_only)
          cb(actions_only)
        end)
      end
    end)
  end
end
function M.search(query)
  load_telescope()
  if vim.fn.executable("gh") == 0 then
    return err("the `gh` CLI isn't installed (or not on PATH)")
  end

  local ctx = {
    buf = vim.api.nvim_get_current_buf(),
    win = vim.api.nvim_get_current_win(),
    row = vim.api.nvim_win_get_cursor(0)[1],
  }

  query = query or vim.fn.input("Search actions: ")
  if query == "" then return end

  if cache[query] then
    return show_picker(ctx, query, cache[query])
  end

  vim.notify("GHAction: searching '" .. query .. "'...")
  search_all(query, function(items, e)
    if not items then
      return err("search failed: " .. trunc(e or "bad response", 200))
    end
    cache[query] = items
    show_picker(ctx, query, items)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("GHAction", function(o)
    M.search(o.args ~= "" and o.args or nil)
  end, { nargs = "*", desc = "Search GitHub Actions and insert/copy a `uses:` line" })
end

return M
