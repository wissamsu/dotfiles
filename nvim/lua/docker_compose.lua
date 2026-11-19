local api = vim.api
local uv = vim.uv or vim.loop

local TAG_TTL_MS = 10 * 60 * 1000
local ENV_TTL_MS = 30 * 60 * 1000
local MAX_TAGS = 2000
local TAG_PAGE_SIZE = 100
local ANON_PAGE_LIMIT = 10
local TAG_VERSION_SORT_BASE = 100000000
local TAG_LATEST_SORT = 250000000
local REQUEST_TIMEOUT = '10'

local tag_states = {}
local env_states = {}

local DOC_ENV_SOURCES = {
  ['quay.io/keycloak/keycloak'] = {
    url = 'https://www.keycloak.org/server/all-config',
    pattern = '(KC_[A-Z0-9_]+)',
  },
}

local ENV_BLACKLIST = {
  ADD = true,
  ALPINE = true,
  AMD64 = true,
  ARG = true,
  ARM64 = true,
  BASH = true,
  BIN = true,
  CMD = true,
  COPY = true,
  DEBIAN = true,
  DOCKER = true,
  DOCKERFILE = true,
  ENTRYPOINT = true,
  ENV = true,
  EXPOSE = true,
  FALSE = true,
  FROM = true,
  HEALTHCHECK = true,
  HOME = true,
  HOSTNAME = true,
  HTTP = true,
  HTTPS = true,
  JSON = true,
  LABEL = true,
  LANG = true,
  LANGUAGE = true,
  LATEST = true,
  LC_ALL = true,
  LINUX = true,
  MAINTAINER = true,
  NONE = true,
  NULL = true,
  OLDPWD = true,
  ONBUILD = true,
  PATH = true,
  PWD = true,
  README = true,
  ROOT = true,
  RUN = true,
  SHELL = true,
  SHLVL = true,
  STOPSIGNAL = true,
  TERM = true,
  TMPDIR = true,
  TRUE = true,
  UBUNTU = true,
  USER = true,
  VERSION = true,
  VOLUME = true,
  WORKDIR = true,
  YAML = true,
  YES = true,
}

local function is_compose_buf(bufnr)
  if vim.bo[bufnr].filetype == 'yaml.docker-compose' then
    return true
  end
  local name = vim.fs.basename(api.nvim_buf_get_name(bufnr))
  return name:match('^docker%-compose.*%.ya?ml$') ~= nil
    or name:match('^compose%.ya?ml$') ~= nil
    or name:match('^compose[%.%-].*%.ya?ml$') ~= nil
end

local function callback_empty(callback)
  callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
end

local function curl_json(url, callback, headers)
  local cmd = { 'curl', '-sSL', '--max-time', REQUEST_TIMEOUT }
  for _, header in ipairs(headers or { 'Accept: application/json', 'User-Agent: nvim-docker-compose' }) do
    cmd[#cmd + 1] = '-H'
    cmd[#cmd + 1] = header
  end
  cmd[#cmd + 1] = url
  return vim.system(cmd, { text = true }, vim.schedule_wrap(function(result)
    local ok, data = pcall(vim.json.decode, result.stdout or '')
    if ok and type(data) == 'table' then
      callback(data)
      return
    end
    if result.code ~= 0 then
      local err = (result.stderr or ''):gsub('%s+$', '')
      if err == '' then
        err = 'request failed (exit ' .. result.code .. ')'
      end
      callback(nil, err)
      return
    end
    callback(nil, 'invalid JSON response')
  end))
end

local function curl_text(url, callback)
  local cmd = { 'curl', '-sSL', '--max-time', REQUEST_TIMEOUT, '-H', 'User-Agent: nvim-docker-compose', url }
  return vim.system(cmd, { text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      local err = (result.stderr or ''):gsub('%s+$', '')
      if err == '' then
        err = 'request failed (exit ' .. result.code .. ')'
      end
      callback(nil, err)
      return
    end
    callback(result.stdout or '')
  end))
end

local function item_edit(edit_range, text)
  return {
    newText = text,
    range = {
      start = { line = edit_range.start.line, character = edit_range.start.character },
      ['end'] = { line = edit_range['end'].line, character = edit_range['end'].character },
    },
  }
end

local function relative_age(iso)
  if type(iso) ~= 'string' then
    return nil
  end
  local year, month, day = iso:match('^(%d+)-(%d+)-(%d+)')
  if not year then
    return nil
  end
  local then_time = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = 12,
  })
  local days = math.max(0, math.floor((os.time() - then_time) / 86400))
  if days < 1 then
    return 'today'
  end
  if days < 30 then
    return days .. 'd ago'
  end
  if days < 365 then
    return math.floor(days / 30) .. 'mo ago'
  end
  return math.floor(days / 365) .. 'y ago'
end

local function strip_yaml_value(raw)
  if raw == nil then
    return nil
  end
  local quote = raw:sub(1, 1)
  if quote == '"' or quote == "'" then
    local close = raw:find(quote, 2, true)
    if close then
      return raw:sub(2, close - 1), 1, close - 1
    end
    return raw:sub(2), 1, #raw
  end
  local value = raw:gsub('%s+#.*$', ''):match('^(.-)%s*$') or ''
  return value, 0, #value
end

local function split_image_ref(value)
  if not value or value == '' or value:find('$', 1, true) then
    return nil
  end
  local at = value:find('@', 1, true)
  if at then
    value = value:sub(1, at - 1)
  end
  local last_slash = 0
  for i = 1, #value do
    if value:sub(i, i) == '/' then
      last_slash = i
    end
  end
  local colon = value:find(':', last_slash + 1, true)
  if colon then
    local name = value:sub(1, colon - 1)
    if name == '' then
      return nil
    end
    return name, value:sub(colon + 1)
  end
  if value == '' then
    return nil
  end
  return value, nil
end

local function image_registry_repo(name)
  if not name or name == '' or name:find('%s') then
    return nil
  end
  local normalized = name:lower()
  local first = normalized:match('^([^/]+)/')
  local registry = 'docker.io'
  if first and (first == 'localhost' or first:find('[%.:]')) then
    registry = first == 'index.docker.io' and 'docker.io' or first
    normalized = normalized:sub(#first + 2)
  end
  if registry == 'registry-1.docker.io' then
    registry = 'docker.io'
  end
  if normalized == '' then
    return nil
  end
  if registry == 'docker.io' and not normalized:find('/') then
    normalized = 'library/' .. normalized
  end
  return registry, normalized
end

local function new_tag_state(registry, repo)
  return {
    registry = registry,
    repo = repo,
    tags = {},
    seen = {},
    complete = false,
    fetching = false,
    fetched_at = 0,
    subscribers = {},
    generation = 1,
    notified = false,
    proc = nil,
    phase = 'newest',
    page = 1,
    count = nil,
    last = nil,
  }
end

local function finish_tag_fetch(state, err)
  state.fetching = false
  state.complete = true
  state.fetched_at = uv.now()
  if err and #state.tags == 0 and not state.notified then
    state.notified = true
    local message = err
    if err:find('404', 1, true) then
      local host = state.registry == 'docker.io' and 'Docker Hub' or state.registry
      message = 'repository not found on ' .. host .. ': ' .. state.repo
    end
    vim.notify('docker compose: ' .. message, vim.log.levels.WARN)
  end
  local subscribers = state.subscribers
  state.subscribers = {}
  for subscriber in pairs(subscribers) do
    if subscriber.on_done then
      subscriber.on_done()
    end
  end
end

local function tag_sort_offset(name)
  if name == 'latest' then
    return TAG_LATEST_SORT
  end
  local version = name:match('^v?(%d[%d%.]*)')
  if not version then
    return 0
  end
  local major, minor, patch = version:match('^(%d+)%.?(%d*)%.?(%d*)')
  major = math.min(tonumber(major) or 0, 999)
  minor = math.min(tonumber(minor) or 0, 999)
  patch = math.min(tonumber(patch) or 0, 999)
  local offset = TAG_VERSION_SORT_BASE + major * 100000 + minor * 100 + patch
  if name:lower():find('alpha', 1, true)
    or name:lower():find('beta', 1, true)
    or name:lower():find('rc', 1, true)
    or name:lower():find('snapshot', 1, true)
    or name:lower():find('nightly', 1, true)
    or name:lower():find('dev', 1, true)
  then
    offset = offset - 1
  end
  return offset
end

local function make_tag_items(display_name, tags, edit_range)
  local kinds = require('blink.cmp.types').CompletionItemKind
  local items = {}
  for _, tag in ipairs(tags) do
    local label = display_name .. ':' .. tag.name
    local age = relative_age(tag.updated)
    local item = {
      label = label,
      filterText = tag.name,
      kind = kinds.Reference,
      score_offset = tag_sort_offset(tag.name),
      textEdit = item_edit(edit_range, label),
    }
    if age then
      item.labelDetails = { description = age }
    end
    if tag.updated then
      item.documentation = {
        kind = 'markdown',
        value = ('`%s`  \nLast updated: %s'):format(tag.name, tag.updated),
      }
    end
    items[#items + 1] = item
  end
  return items
end

local function subscribe_tags(state, display_name, edit_range, on_items, on_done)
  local subscriber = {
    display_name = display_name,
    edit_range = edit_range,
    on_items = on_items,
    on_done = on_done,
  }
  if state.complete then
    on_items(make_tag_items(display_name, state.tags, edit_range))
    on_done()
    return function() end
  end
  state.subscribers[subscriber] = true
  if #state.tags > 0 then
    on_items(make_tag_items(display_name, state.tags, edit_range))
  end
  return function()
    state.subscribers[subscriber] = nil
  end
end

local function hub_tag_page_url(state)
  local ordering = state.phase == 'oldest' and '-last_updated' or 'last_updated'
  return ('https://hub.docker.com/v2/repositories/%s/tags?page_size=%d&ordering=%s&page=%d')
    :format(state.repo, TAG_PAGE_SIZE, ordering, state.page)
end

local function url_encode(value)
  return (value:gsub('([^%w%-%._~])', function(char)
    return ('%%%02X'):format(string.byte(char))
  end))
end

local function oci_tag_page_url(state)
  local url = ('https://%s/v2/%s/tags/list?n=%d'):format(state.registry, state.repo, TAG_PAGE_SIZE)
  if state.last then
    url = url .. '&last=' .. url_encode(state.last)
  end
  return url
end

local function switch_to_oldest(state)
  if state.phase == 'oldest' then
    return false
  end
  state.phase = 'oldest'
  state.page = 1
  return true
end

local function emit_tag_update(state, fresh)
  if #fresh == 0 then
    return
  end
  for subscriber in pairs(state.subscribers) do
    subscriber.on_items(make_tag_items(subscriber.display_name, fresh, subscriber.edit_range))
  end
end

local function fetch_hub_tag_page(state)
  local generation = state.generation
  state.proc = curl_json(hub_tag_page_url(state), function(data, err)
    state.proc = nil
    if state.generation ~= generation then
      return
    end
    if err then
      finish_tag_fetch(state, err)
      return
    end
    if type(data) ~= 'table' or type(data.results) ~= 'table' then
      local message = type(data) == 'table' and (data.message or data.detail) or nil
      if type(message) ~= 'string' then
        message = 'unexpected response from Docker Hub'
      end
      if message:find('pagination offset too large', 1, true) then
        if state.phase == 'newest' and (not state.count or #state.tags < state.count) and switch_to_oldest(state) then
          fetch_hub_tag_page(state)
          return
        end
        if state.phase == 'oldest' then
          finish_tag_fetch(state)
          return
        end
      end
      finish_tag_fetch(state, message)
      return
    end
    state.count = tonumber(data.count) or state.count
    local fresh = {}
    for _, tag in ipairs(data.results) do
      if #state.tags >= MAX_TAGS then
        break
      end
      local name = tag.name
      if type(name) == 'string' and name ~= '' and not state.seen[name] then
        state.seen[name] = true
        local entry = { name = name, updated = tag.last_updated }
        state.tags[#state.tags + 1] = entry
        fresh[#fresh + 1] = entry
      end
    end
    emit_tag_update(state, fresh)
    if #state.tags >= MAX_TAGS then
      finish_tag_fetch(state)
      return
    end
    local has_next = type(data.next) == 'string' and data.next ~= ''
    if has_next and state.page < ANON_PAGE_LIMIT then
      state.page = state.page + 1
      fetch_hub_tag_page(state)
      return
    end
    if state.phase == 'newest' and (not state.count or #state.tags < state.count) and switch_to_oldest(state) then
      fetch_hub_tag_page(state)
      return
    end
    finish_tag_fetch(state)
  end)
end

local function fetch_oci_tag_page(state)
  local generation = state.generation
  state.proc = curl_json(oci_tag_page_url(state), function(data, err)
    state.proc = nil
    if state.generation ~= generation then
      return
    end
    if err then
      finish_tag_fetch(state, err)
      return
    end
    if type(data) ~= 'table' or (data.tags ~= nil and type(data.tags) ~= 'table') then
      local message = type(data) == 'table' and (data.message or data.detail) or nil
      if not message and type(data) == 'table' and type(data.errors) == 'table' then
        message = data.errors[1] and data.errors[1].message
      end
      finish_tag_fetch(state, type(message) == 'string' and message or 'unexpected response from registry')
      return
    end
    local fresh = {}
    local last
    for _, name in ipairs(data.tags or {}) do
      last = name
      if #state.tags >= MAX_TAGS then
        break
      end
      if type(name) == 'string' and name ~= '' and not state.seen[name] then
        state.seen[name] = true
        local entry = { name = name }
        state.tags[#state.tags + 1] = entry
        fresh[#fresh + 1] = entry
      end
    end
    emit_tag_update(state, fresh)
    local tags = data.tags or {}
    if #state.tags >= MAX_TAGS or #tags < TAG_PAGE_SIZE or not last or last == state.last then
      finish_tag_fetch(state)
      return
    end
    state.last = last
    fetch_oci_tag_page(state)
  end)
end

local function fetch_tag_page(state)
  if state.registry == 'docker.io' then
    fetch_hub_tag_page(state)
  else
    fetch_oci_tag_page(state)
  end
end

local function get_tags(registry, repo, display_name, edit_range, on_items, on_done)
  local key = registry .. '/' .. repo
  local old = tag_states[key]
  local state = old
  if not state or (not state.fetching and uv.now() - state.fetched_at > TAG_TTL_MS) then
    if old and old.proc then
      pcall(function()
        old.proc:kill(15)
      end)
    end
    state = new_tag_state(registry, repo)
    if old then
      state.generation = old.generation + 1
    end
    tag_states[key] = state
  end
  local unsubscribe = subscribe_tags(state, display_name, edit_range, on_items, on_done)
  if not state.complete and not state.fetching then
    state.fetching = true
    fetch_tag_page(state)
  end
  return unsubscribe
end

local function is_env_name(name)
  if type(name) ~= 'string' or #name < 2 or #name > 80 then
    return false
  end
  if not name:match('^[A-Z][A-Z0-9_]*$') then
    return false
  end
  if name:find('__', 1, true) or name:sub(-1) == '_' or ENV_BLACKLIST[name] then
    return false
  end
  return true
end

local function add_env_var(vars, seen, name)
  if is_env_name(name) and not seen[name] then
    seen[name] = true
    vars[#vars + 1] = name
  end
end

local function extract_env_vars(text)
  local vars = {}
  local seen = {}

  for name in text:gmatch('`([A-Z][A-Z0-9_]*)`') do
    add_env_var(vars, seen, name)
  end
  for name in text:gmatch('%*%*([A-Z][A-Z0-9_]*)%*%*') do
    add_env_var(vars, seen, name)
  end
  for name in text:gmatch('%-%-env%s+([A-Z][A-Z0-9_]*)%s*=') do
    add_env_var(vars, seen, name)
  end
  for name in text:gmatch('%-%-env=([A-Z][A-Z0-9_]*)%s*=') do
    add_env_var(vars, seen, name)
  end
  for name in text:gmatch('%-e%s+([A-Z][A-Z0-9_]*)%s*=') do
    add_env_var(vars, seen, name)
  end
  for name in text:gmatch('%-e([A-Z][A-Z0-9_]*)=', 1) do
    add_env_var(vars, seen, name)
  end
  for line in text:gmatch('[^\n]+') do
    local env = line:match('^%s*ENV%s+(.+)$')
    if env then
      for name in env:gmatch('([A-Z][A-Z0-9_]+)%s*=') do
        add_env_var(vars, seen, name)
      end
      local single = env:match('^([A-Z][A-Z0-9_]+)%s*$')
      if single then
        add_env_var(vars, seen, single)
      end
    end
    local cell = line:match('^%s*|%s*([A-Z][A-Z0-9_]+)%s*|')
    if cell then
      add_env_var(vars, seen, cell)
    end
  end
  return vars
end

local REGISTRY_ACCEPT = table.concat({
  'application/vnd.oci.image.index.v1+json',
  'application/vnd.docker.distribution.manifest.list.v2+json',
  'application/vnd.oci.image.manifest.v1+json',
  'application/vnd.docker.distribution.manifest.v2+json',
}, ', ')

local function extract_config_env(env)
  local vars = {}
  local seen = {}
  for _, entry in ipairs(env or {}) do
    local name = type(entry) == 'string' and entry:match('^([^=]+)=') or nil
    if name and not name:match('_VERSION$') and not name:match('_MAJOR$') then
      add_env_var(vars, seen, name)
    end
  end
  return vars
end

local function registry_headers(registry, repo, callback)
  local headers = { 'Accept: ' .. REGISTRY_ACCEPT }
  if registry ~= 'docker.io' then
    callback(headers)
    return
  end
  curl_json(
    'https://auth.docker.io/token?service=registry.docker.io&scope=repository:' .. repo .. ':pull',
    function(auth)
      if type(auth) ~= 'table' or type(auth.token) ~= 'string' then
        callback(nil)
        return
      end
      headers[#headers + 1] = 'Authorization: Bearer ' .. auth.token
      callback(headers)
    end
  )
end

local function fetch_registry_env(registry, repo, tag, callback)
  local reference = tag and tag ~= '' and tag or 'latest'
  local host = registry == 'docker.io' and 'registry-1.docker.io' or registry
  registry_headers(registry, repo, function(headers)
    if type(headers) ~= 'table' then
      callback(nil)
      return
    end
    local function config_env(manifest)
      local digest = type(manifest) == 'table' and type(manifest.config) == 'table' and manifest.config.digest
      if type(digest) ~= 'string' then
        callback(nil)
        return
      end
      curl_json('https://' .. host .. '/v2/' .. repo .. '/blobs/' .. digest, function(config)
        if type(config) ~= 'table' then
          callback(nil)
          return
        end
        callback(extract_config_env(type(config.config) == 'table' and config.config.Env or {}))
      end, headers)
    end
    local function manifest_result(manifest)
      if type(manifest) ~= 'table' then
        callback(nil)
        return
      end
      if type(manifest.manifests) ~= 'table' then
        config_env(manifest)
        return
      end
      local digest
      for _, entry in ipairs(manifest.manifests) do
        local platform = entry.platform or {}
        if platform.os == 'linux' and platform.architecture == 'amd64' then
          digest = entry.digest
          break
        end
      end
      if not digest then
        for _, entry in ipairs(manifest.manifests) do
          if (entry.platform or {}).os == 'linux' then
            digest = entry.digest
            break
          end
        end
      end
      if not digest then
        callback(nil)
        return
      end
      curl_json('https://' .. host .. '/v2/' .. repo .. '/manifests/' .. digest, manifest_result, headers)
    end
    curl_json('https://' .. host .. '/v2/' .. repo .. '/manifests/' .. reference, manifest_result, headers)
  end)
end

local function new_env_state(registry, repo, tag)
  return {
    registry = registry,
    repo = repo,
    tag = tag,
    vars = {},
    complete = false,
    fetching = false,
    fetched_at = 0,
    subscribers = {},
    generation = 1,
    proc = nil,
  }
end

local function finish_env_state(state, vars)
  state.vars = vars or {}
  state.complete = true
  state.fetching = false
  state.fetched_at = uv.now()
  local subscribers = state.subscribers
  state.subscribers = {}
  for subscriber in pairs(subscribers) do
    subscriber.on_items(state.vars)
  end
end

local function fetch_docs_env(source, callback)
  curl_text(source.url, function(text, err)
    if err or not text then
      callback(nil, err)
      return
    end
    local vars = {}
    local seen = {}
    for name in text:gmatch(source.pattern) do
      add_env_var(vars, seen, name)
    end
    callback(vars)
  end)
end

local function fetch_env_state(state)
  local generation = state.generation
  state.fetching = true
  if state.registry ~= 'docker.io' then
    local source = DOC_ENV_SOURCES[state.registry .. '/' .. state.repo]
    if source then
      state.proc = fetch_docs_env(source, function(vars)
        state.proc = nil
        if state.generation ~= generation then
          return
        end
        if vars and #vars > 0 then
          finish_env_state(state, vars)
          return
        end
        fetch_registry_env(state.registry, state.repo, state.tag, function(registry_vars)
          if state.generation ~= generation then
            return
          end
          finish_env_state(state, registry_vars or {})
        end)
      end)
      return
    end
    fetch_registry_env(state.registry, state.repo, state.tag, function(registry_vars)
      if state.generation ~= generation then
        return
      end
      finish_env_state(state, registry_vars or {})
    end)
    return
  end
  state.proc = curl_json('https://hub.docker.com/v2/repositories/' .. state.repo .. '/', function(data, err)
    state.proc = nil
    if state.generation ~= generation then
      return
    end
    local vars = {}
    if not err and type(data) == 'table' then
      vars = extract_env_vars(data.full_description or '')
    end
    if #vars > 0 then
      finish_env_state(state, vars)
      return
    end
    fetch_registry_env(state.registry, state.repo, state.tag, function(registry_vars)
      if state.generation ~= generation then
        return
      end
      finish_env_state(state, registry_vars or {})
    end)
  end)
end

local function get_env_vars(registry, repo, tag, on_items)
  local key = registry .. '/' .. repo .. ':' .. (tag or '')
  local old = env_states[key]
  local state = old
  if not state or (not state.fetching and uv.now() - state.fetched_at > ENV_TTL_MS) then
    if old and old.proc then
      pcall(function()
        old.proc:kill(15)
      end)
    end
    state = new_env_state(registry, repo, tag)
    if old then
      state.generation = old.generation + 1
    end
    env_states[key] = state
  end
  if state.complete then
    on_items(state.vars)
    return function() end
  end
  local subscriber = { on_items = on_items }
  state.subscribers[subscriber] = true
  if not state.fetching then
    fetch_env_state(state)
  end
  return function()
    state.subscribers[subscriber] = nil
  end
end

local function env_score(name, base)
  local score = 0
  if base ~= '' and name:find(base, 1, true) then
    score = score + 100
  end
  if name:find('PASSWORD', 1, true) then
    score = score + 20
  end
  if name:find('USER', 1, true) then
    score = score + 10
  end
  if name:find('DATABASE', 1, true) or name:match('_DB$') or name:match('^DB_') then
    score = score + 10
  end
  if name:find('HOST', 1, true) or name:find('PORT', 1, true) then
    score = score + 5
  end
  return score
end

local function make_env_items(vars, existing, base, description, edit_range, suffix)
  local kinds = require('blink.cmp.types').CompletionItemKind
  local items = {}
  for _, name in ipairs(vars) do
    if not existing[name] then
      items[#items + 1] = {
        label = name,
        filterText = name,
        kind = kinds.Constant,
        score_offset = env_score(name, base),
        labelDetails = { description = description },
        textEdit = item_edit(edit_range, name .. suffix),
      }
    end
  end
  return items
end

local function parse_image_line(line, cursor_col)
  local prefix = line:match('^(%s*image%s*:%s*)')
  if not prefix then
    return nil
  end
  local value, rel_start, rel_end = strip_yaml_value(line:sub(#prefix + 1))
  if not value or value == '' then
    return nil
  end
  local value_start = #prefix + rel_start
  local value_end = #prefix + rel_end
  if cursor_col < value_start or cursor_col > value_end then
    return nil
  end
  local name, tag = split_image_ref(value)
  if not name then
    return nil
  end
  return { name = name, tag = tag, start_col = value_start, end_col = value_end }
end

local function indent_of(line)
  return #(line:match('^(%s*)') or '')
end

local function is_blank_or_comment(line)
  return line:match('^%s*$') ~= nil or line:match('^%s*#') ~= nil
end

local function find_env_block(lines, row)
  local cursor_indent = indent_of(lines[row + 1] or '')
  for i = row, 0, -1 do
    local ind, rest = lines[i + 1]:match('^(%s*)environment%s*:%s*(.*)$')
    if ind then
      local env_indent = #ind
      if rest ~= '' and not rest:match('^#') then
        return nil
      end
      if i == row or cursor_indent <= env_indent then
        return nil
      end
      for j = i + 1, row - 1 do
        local line = lines[j + 1]
        if not is_blank_or_comment(line) and indent_of(line) <= env_indent then
          return nil
        end
      end
      return { row = i, indent = env_indent }
    end
  end
  return nil
end

local function env_style(lines, env_row, env_indent)
  for i = env_row + 1, #lines - 1 do
    local line = lines[i + 1]
    if not is_blank_or_comment(line) then
      if indent_of(line) <= env_indent then
        return nil
      end
      return line:match('^%s*%-') and 'list' or 'map'
    end
  end
  return 'map'
end

local function collect_env_keys(lines, env_row, env_indent, style)
  local keys = {}
  for i = env_row + 1, #lines - 1 do
    local line = lines[i + 1]
    if not is_blank_or_comment(line) then
      if indent_of(line) <= env_indent then
        break
      end
      local name
      if style == 'list' then
        name = line:match('^%s*%-%s*([%w_.-]+)')
      else
        name = line:match('^%s*([%w_.-]+)%s*:')
      end
      if name then
        keys[name] = true
      end
    end
  end
  return keys
end

local function find_service_image(lines, env_row, env_indent)
  local top = env_row
  local bottom = env_row
  for i = env_row - 1, 0, -1 do
    local line = lines[i + 1]
    if not is_blank_or_comment(line) and indent_of(line) < env_indent then
      break
    end
    top = i
  end
  for i = env_row + 1, #lines - 1 do
    local line = lines[i + 1]
    if not is_blank_or_comment(line) and indent_of(line) < env_indent then
      break
    end
    bottom = i
  end
  for i = top, bottom do
    local ind, raw = lines[i + 1]:match('^(%s*)image%s*:%s*(.*)$')
    if ind and #ind == env_indent then
      local value = strip_yaml_value(raw)
      local name, tag = value and split_image_ref(value)
      if name then
        return name, tag
      end
    end
  end
  return nil
end

local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.mode = (opts or {}).mode or 'tags'
  return self
end

function source:enabled()
  return is_compose_buf(api.nvim_get_current_buf())
end

function source:get_trigger_characters()
  if self.mode == 'tags' then
    return { ':' }
  end
  return {}
end

function source:get_completions(ctx, callback)
  local bufnr = ctx.bufnr or api.nvim_get_current_buf()
  if not is_compose_buf(bufnr) then
    callback_empty(callback)
    return
  end
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local row = ctx.cursor[1] - 1
  local col = ctx.cursor[2]
  local line = ctx.line or lines[row + 1] or ''

  if self.mode == 'tags' then
    local parsed = parse_image_line(line, col)
    if not parsed then
      callback_empty(callback)
      return
    end
    local registry, repo = image_registry_repo(parsed.name)
    if not registry or not repo or parsed.tag == nil then
      callback_empty(callback)
      return
    end
    local edit_range = {
      start = { line = row, character = parsed.start_col },
      ['end'] = { line = row, character = parsed.end_col },
    }
    local function on_items(items)
      callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
    end
    local function on_done()
      callback_empty(callback)
    end
    return get_tags(registry, repo, parsed.name, edit_range, on_items, on_done)
  end

  if not ctx.bounds or line:match('^%s*#') then
    callback_empty(callback)
    return
  end
  local block = find_env_block(lines, row)
  if not block then
    callback_empty(callback)
    return
  end
  local style = env_style(lines, block.row, block.indent)
  if not style then
    callback_empty(callback)
    return
  end
  local before_cursor = line:sub(1, col)
  if style == 'map' then
    if before_cursor:find(':', 1, true) then
      callback_empty(callback)
      return
    end
  else
    if not line:match('^%s*%-') or before_cursor:find('=', 1, true) or before_cursor:find(':', 1, true) then
      callback_empty(callback)
      return
    end
  end
  local image_name, image_tag = find_service_image(lines, block.row, block.indent)
  if not image_name then
    callback_empty(callback)
    return
  end
  local registry, repo = image_registry_repo(image_name)
  if not registry or not repo then
    callback_empty(callback)
    return
  end
  local existing = collect_env_keys(lines, block.row, block.indent, style)
  local start_col = math.max(0, ctx.bounds.start_col - 1)
  local end_col = math.max(start_col, start_col + ctx.bounds.length)
  local edit_range = {
    start = { line = row, character = start_col },
    ['end'] = { line = row, character = end_col },
  }
  local suffix = style == 'list' and '=' or ': '
  local base = (repo:match('([^/]+)$') or repo):upper():gsub('[^A-Z0-9]', '_')
  return get_env_vars(registry, repo, image_tag, function(vars)
    local items = make_env_items(vars, existing, base, image_name, edit_range, suffix)
    callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  end)
end

return source
