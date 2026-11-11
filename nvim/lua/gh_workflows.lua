-- gh_workflow.lua
-- Put this at ~/.config/nvim/lua/gh_workflow.lua and load it with:
--   require('gh_workflow')
--
-- Commands:
--   :GHWorkflow         pick a template with fff.nvim (search by name/description/category)
--   :GHWorkflow!        same, but refresh the cached templates from GitHub first
--   :GHWorkflowSelect   pick with vim.ui.select (optional query, e.g. :GHWorkflowSelect java maven)
--   :GHWorkflowSelect!  same, refreshing the cache first

local M = {}

local repo_url = 'https://github.com/actions/starter-workflows'
local cache = vim.fn.stdpath('cache') .. '/starter-workflows'
local stage = vim.fn.stdpath('cache') .. '/workflow-picker'
local default_branch = 'main' -- replaces $default-branch in templates

local staged = {}             -- staged file path -> { item = ..., root = ... }

---------------------------------------------------------------------------
-- Template source (sparse clone of actions/starter-workflows, ci/ only)
---------------------------------------------------------------------------

local function sync(update)
  if vim.uv.fs_stat(cache .. '/.git') then
    if update then
      vim.system({ 'git', '-C', cache, 'fetch', '--depth', '1', 'origin' }):wait()
      vim.system({ 'git', '-C', cache, 'reset', '--hard', 'FETCH_HEAD' }):wait()
    end
    return true
  end

  vim.notify('Downloading workflow templates...')
  local r = vim.system({
    'git', 'clone', '--depth', '1', '--filter=blob:none', '--sparse', repo_url, cache,
  }, { text = true }):wait()
  if r.code ~= 0 then
    vim.notify(r.stderr, vim.log.levels.ERROR)
    return false
  end
  vim.system({ 'git', '-C', cache, 'sparse-checkout', 'set', 'ci' }):wait()
  return true
end

local function load_templates()
  local items = {}
  for _, file in ipairs(vim.fn.glob(cache .. '/ci/*.yml', false, true)) do
    local id = vim.fn.fnamemodify(file, ':t:r')
    local info = {}
    local pf = cache .. '/ci/properties/' .. id .. '.properties.json'
    if vim.uv.fs_stat(pf) then
      local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(pf), '\n'))
      if ok and type(decoded) == 'table' then info = decoded end
    end

    local name = type(info.name) == 'string' and info.name or id
    local desc = type(info.description) == 'string' and info.description or ''
    local cats = type(info.categories) == 'table' and table.concat(info.categories, ', ') or ''

    table.insert(items, {
      file = file,
      filename = id .. '.yml',
      name = name,
      desc = desc,
      cats = cats,
      text = table.concat({ name, desc, cats, id }, ' '), -- what fuzzy search matches against
    })
  end
  table.sort(items, function(a, b) return a.name:lower() < b.name:lower() end)
  return items
end

local function template_lines(item)
  local lines = vim.fn.readfile(item.file)
  for i, l in ipairs(lines) do
    lines[i] = (l:gsub('%$default%-branch', default_branch))
  end
  return lines
end

local function project_root()
  return vim.fs.root(0, '.git') or vim.uv.cwd()
end

---------------------------------------------------------------------------
-- Install a template into <root>/.github/workflows/
---------------------------------------------------------------------------

local function install(item, root)
  local dir = (root or project_root()) .. '/.github/workflows'
  local path = dir .. '/' .. item.filename
  if vim.uv.fs_stat(path) then
    vim.notify(path .. ' already exists, opening it', vim.log.levels.WARN)
  else
    vim.fn.mkdir(dir, 'p')
    vim.fn.writefile(template_lines(item), path)
  end
  vim.cmd.edit(path)
end

---------------------------------------------------------------------------
-- fff.nvim picker
-- fff only searches files, so each template is written to a staging dir as a
-- file whose NAME contains "<name> - <description> [<categories>]". fff
-- fuzzy-matches that name and previews the YAML. Opening a staged file is
-- intercepted by the autocmd below, which installs it into the project.
---------------------------------------------------------------------------

local function safe(s)
  return (s:gsub('[/\\:*?"<>|%c]', ' '):gsub('%s+', ' '))
end

local function stage_templates(items, root)
  vim.fn.delete(stage, 'rf')
  vim.fn.mkdir(stage, 'p')
  staged = {}
  for _, item in ipairs(items) do
    local label = safe(string.format('%s - %s [%s]', item.name, item.desc, item.cats))
    local path = stage .. '/' .. label:sub(1, 200) .. '.yml'
    vim.fn.writefile(template_lines(item), path)
    staged[path] = { item = item, root = root }
  end
end

vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = stage .. '/*',
  callback = function(ev)
    local entry = staged[vim.api.nvim_buf_get_name(ev.buf)]
    if not entry then return end
    vim.schedule(function()
      install(entry.item, entry.root)
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.api.nvim_buf_delete(ev.buf, { force = true })
      end
    end)
  end,
})

vim.api.nvim_create_user_command('GHWorkflow', function(opts)
  if not sync(opts.bang) then return end
  stage_templates(load_templates(), project_root())

  local ok, fff = pcall(require, 'fff')
  if ok and fff.find_files_in_dir then
    fff.find_files_in_dir(stage)
  elseif vim.fn.exists(':FFFFind') == 2 then
    vim.cmd('FFFFind ' .. vim.fn.fnameescape(stage))
  else
    vim.notify('fff.nvim not found, try :GHWorkflowSelect instead', vim.log.levels.ERROR)
  end
end, { bang = true })

---------------------------------------------------------------------------
-- vim.ui.select picker (works with any picker that overrides vim.ui.select)
---------------------------------------------------------------------------

vim.api.nvim_create_user_command('GHWorkflowSelect', function(opts)
  if not sync(opts.bang) then return end
  local items = load_templates()

  if opts.args ~= '' then
    items = vim.fn.matchfuzzy(items, opts.args, { key = 'text' })
    if #items == 0 then
      return vim.notify('No templates match "' .. opts.args .. '"', vim.log.levels.WARN)
    end
    if #items == 1 then return install(items[1]) end
  end

  vim.ui.select(items, {
    prompt = 'Workflow template:',
    format_item = function(i)
      return string.format('%-30s %s  [%s]', i.name, i.desc, i.cats)
    end,
  }, function(choice)
    if choice then install(choice) end
  end)
end, { nargs = '?', bang = true })

return M
