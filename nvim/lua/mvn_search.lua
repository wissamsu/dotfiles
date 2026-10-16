-- lua/mvn_search.lua
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

local function err(msg)
  vim.notify("MvnSearch: " .. msg, vim.log.levels.ERROR)
end

local function snippet(s)
  s = tostring(s or ""):gsub("%s+", " ")
  return #s > 200 and (s:sub(1, 200) .. "...") or s
end

local function to_xml(d, scope)
  return ("<dependency>\n  <groupId>%s</groupId>\n  <artifactId>%s</artifactId>\n  <version>%s</version>\n  <scope>%s</scope>\n</dependency>")
      :format(d.g, d.a, d.latestVersion, scope)
end

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
          vim.fn.setreg("+", to_xml(sel.value, scope))
          vim.notify("Dependency (" .. scope .. ") copied to clipboard")
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
