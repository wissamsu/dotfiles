local M = {}

M.name = "neotest-kotlin"

local uv = vim.uv or vim.loop
local is_win = package.config:sub(1, 1) == "\\"

-- Matches @Test but not @TestFactory / @TestTemplate / etc.
local query = [[
  (class_declaration
    (type_identifier) @namespace.name) @namespace.definition

  (function_declaration
    (modifiers) @mod
    (simple_identifier) @test.name
    (#lua-match? @mod "@Test%f[%W]")) @test.definition
]]

local IGNORED_DIRS = {
  target = true,
  build = true,
  out = true,
  node_modules = true,
  [".git"] = true,
  [".gradle"] = true,
  [".idea"] = true,
}

----------------------------------------------------------------------
-- Small helpers (all safe to call from neotest's async context)
----------------------------------------------------------------------

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function package_name(file_path)
  local f = io.open(file_path, "r")
  if not f then
    return ""
  end
  for line in f:lines() do
    local pkg = line:match("^%s*package%s+([%w_%.]+)")
    if pkg then
      f:close()
      return pkg
    end
  end
  f:close()
  return ""
end

local function strip_ticks(name)
  return (name:gsub("`", ""))
end

local function xml_unescape(s)
  return (
    (s or "")
    :gsub("&lt;", "<")
    :gsub("&gt;", ">")
    :gsub("&quot;", '"')
    :gsub("&apos;", "'")
    :gsub("&#(%d+);", function(n)
      return utf8.char(tonumber(n))
    end)
    :gsub("&amp;", "&")
  )
end

--- Walk up from `path` to the nearest directory containing a build file.
--- Returns the directory and the build tool ("maven" | "gradle").
local function locate(path)
  local stat = uv.fs_stat(path)
  local dir = (stat and stat.type == "directory") and path or vim.fs.dirname(path)
  while dir do
    if exists(dir .. "/pom.xml") then
      return dir, "maven"
    end
    if exists(dir .. "/build.gradle.kts") or exists(dir .. "/build.gradle") then
      return dir, "gradle"
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return nil, nil
end

--- Look for mvnw / gradlew between `dir` and `stop` (inclusive); fall back to global binary.
local function find_wrapper(dir, stop, tool)
  local wrapper, fallback
  if tool == "maven" then
    wrapper = is_win and "mvnw.cmd" or "mvnw"
    fallback = "mvn"
  else
    wrapper = is_win and "gradlew.bat" or "gradlew"
    fallback = "gradle"
  end
  local current = dir
  while current do
    local candidate = current .. "/" .. wrapper
    if exists(candidate) then
      return candidate
    end
    if current == stop then
      break
    end
    local parent = vim.fs.dirname(current)
    if not parent or parent == current then
      break
    end
    current = parent
  end
  return fallback
end

local function report_dir(module_dir, tool)
  if tool == "maven" then
    return module_dir .. "/target/surefire-reports"
  end
  return module_dir .. "/build/test-results/test"
end

--- "Outer$Inner" style chain of enclosing classes for a tree node.
local function class_chain(node)
  local names = {}
  local n = node
  while n do
    local d = n:data()
    if d.type == "namespace" then
      table.insert(names, 1, d.name)
    end
    n = n:parent()
  end
  return table.concat(names, "$")
end

local function class_name(node, pkg)
  local chain = class_chain(node)
  return (pkg ~= "" and (pkg .. ".") or "") .. chain
end

----------------------------------------------------------------------
-- Adapter interface
----------------------------------------------------------------------

function M.root(dir)
  return vim.fs.root(dir, {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    ".git",
  })
end

function M.filter_dir(name, _rel_path, _root)
  return not IGNORED_DIRS[name]
end

function M.is_test_file(file_path)
  return file_path:match("src/test/.*Test%.kt$") ~= nil
      or file_path:match("src/test/.*Tests%.kt$") ~= nil
end

function M.discover_positions(file_path)
  -- Default position ids (path::Outer::Inner::test) already include every parent.
  return require("neotest.lib.treesitter").parse_positions(file_path, query, {
    require_namespaces = true,
  })
end

function M.build_spec(args)
  local tree = args.tree
  local position = tree:data()

  local module_dir, tool = locate(position.path)
  if not module_dir then
    return nil
  end
  local root = M.root(module_dir) or module_dir
  local runner = find_wrapper(module_dir, root, tool)

  -- Work out which classes / methods to run.
  local targets = {}
  if position.type == "test" or position.type == "namespace" then
    local pkg = package_name(position.path)
    local target = class_name(tree, pkg)
    if position.type == "test" then
      target = target .. "#" .. strip_ticks(position.name)
    end
    targets = { target }
  elseif position.type == "file" then
    local pkg = package_name(position.path)
    for _, child in ipairs(tree:children()) do
      if child:data().type == "namespace" then
        table.insert(targets, class_name(child, pkg))
      end
    end
    if #targets == 0 then
      return nil
    end
  end
  -- position.type == "dir": no filter, run every test in the module.

  local command
  if tool == "maven" then
    command = { runner, "-B", "test" }
    if #targets > 0 then
      vim.list_extend(command, {
        "-Dtest=" .. table.concat(targets, ","),
        "-Dsurefire.failIfNoSpecifiedTests=false",
      })
    end
  else
    command = { runner, "--console=plain", "cleanTest", "test" }
    for _, target in ipairs(targets) do
      -- Gradle wants Class.method rather than Class#method
      table.insert(command, "--tests")
      table.insert(command, (target:gsub("#", ".")))
    end
  end

  return {
    command = command,
    cwd = module_dir,
    context = {
      position_id = position.id,
      position_type = position.type,
      started = os.time(),
    },
  }
end

----------------------------------------------------------------------
-- Results
----------------------------------------------------------------------

--- Parse a JUnit-style XML report into a list of testcases.
local function parse_report(xml)
  local cases = {}
  local pos = 1
  while true do
    local s, e, attrs, selfclose = xml:find("<testcase(%s[^>]-)(/?)>", pos)
    if not s then
      break
    end
    local body = ""
    pos = e + 1
    if selfclose ~= "/" then
      local cs, ce = xml:find("</testcase>", pos, true)
      if cs then
        body = xml:sub(pos, cs - 1)
        pos = ce + 1
      end
    end

    local status = "passed"
    local message, detail
    if body:find("<skipped", 1, true) then
      status = "skipped"
    end
    if body:find("<failure", 1, true) or body:find("<error", 1, true) then
      status = "failed"
      message = body:match('<failure[^>]-message="([^"]*)"') or body:match('<error[^>]-message="([^"]*)"')
      detail = body:match("<failure[^>]*>(.-)</failure>") or body:match("<error[^>]*>(.-)</error>")
      if not message and detail then
        message = detail:match("^%s*([^\n]*)")
      end
    end

    table.insert(cases, {
      classname = xml_unescape(attrs:match('classname="([^"]*)"')),
      -- leading %s avoids matching the "name" inside "classname"
      name = xml_unescape(attrs:match('%sname="([^"]*)"')),
      status = status,
      message = xml_unescape(message),
      detail = xml_unescape(detail),
    })
  end
  return cases
end

local function collect_cases(dirs, started)
  local cases = {}
  for dir in pairs(dirs) do
    local handle = uv.fs_scandir(dir)
    if handle then
      while true do
        local name = uv.fs_scandir_next(handle)
        if not name then
          break
        end
        if name:match("^TEST%-.*%.xml$") then
          local path = dir .. "/" .. name
          local stat = uv.fs_stat(path)
          -- ignore stale reports from earlier runs
          if stat and stat.mtime.sec >= (started or 0) - 1 then
            local xml = read_file(path)
            if xml then
              vim.list_extend(cases, parse_report(xml))
            end
          end
        end
      end
    end
  end
  return cases
end

function M.results(spec, result, tree)
  local ctx = spec.context or {}
  local results = {}

  -- Index every test in the run by "binary.class.Name#method".
  local tests, report_dirs, pkgs = {}, {}, {}
  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if pos.type == "test" then
      pkgs[pos.path] = pkgs[pos.path] or package_name(pos.path)
      tests[class_name(node, pkgs[pos.path]) .. "#" .. strip_ticks(pos.name)] = pos
      local dir, tool = locate(pos.path)
      if dir then
        report_dirs[report_dir(dir, tool)] = true
      end
    end
  end

  local found_any = false
  for _, case in ipairs(collect_cases(report_dirs, ctx.started)) do
    -- JUnit 5 reports "method()"; JUnit 4 reports "method"
    local method = (case.name:gsub("%(%)$", ""))
    local pos = tests[case.classname .. "#" .. method]
    if pos then
      found_any = true
      local entry = { status = case.status, output = result.output }
      if case.status == "failed" then
        local message = (case.message and case.message ~= "") and case.message or "Test failed"
        local line
        if case.detail then
          local fname = vim.fs.basename(pos.path)
          line = case.detail:match(vim.pesc(fname) .. ":(%d+)")
        end
        entry.short = message:match("^[^\n]*")
        entry.errors = {
          { message = message, line = line and (tonumber(line) - 1) or nil },
        }
      end
      results[pos.id] = entry
    end
  end

  -- Nothing was reported (compile error, bad filter, ...) and the build failed:
  -- mark everything that was supposed to run as failed.
  if not found_any and result.code ~= 0 then
    for _, pos in pairs(tests) do
      results[pos.id] = {
        status = "failed",
        short = "Build or test run failed (see output)",
        output = result.output,
        errors = { { message = "Build or test run failed (see output)" } },
      }
    end
  end

  -- Fallback for the position that was actually run.
  if ctx.position_id and not results[ctx.position_id] and (ctx.position_type == "test" or not found_any) then
    results[ctx.position_id] = {
      status = result.code == 0 and "passed" or "failed",
      output = result.output,
    }
  end

  return results
end

return M
