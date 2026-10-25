local M = {}

M.name = "neotest-kotlin"

local query = [[
  (class_declaration
    (type_identifier) @namespace.name) @namespace.definition

  (function_declaration
    (modifiers) @mod
    (simple_identifier) @test.name
    (#lua-match? @mod "@Test")) @test.definition
]]

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
  return name ~= "target" and name ~= "build"
end

function M.is_test_file(file_path)
  return file_path:match("src/test/.*Test%.kt$") ~= nil
    or file_path:match("src/test/.*Tests%.kt$") ~= nil
end

function M.position_id(position, parents)
  parents = parents or {}
  if position.type == "namespace" then
    return position.path .. "::" .. position.name
  end
  if position.type == "test" then
    local ns = parents[#parents]
    local prefix = ns and (ns.name .. "::") or ""
    return position.path .. "::" .. prefix .. position.name
  end
  return position.path
end

function M.discover_positions(file_path)
  return require("neotest.lib.treesitter").parse_positions(file_path, query, {
    require_namespaces = true,
    position_id = "require('neotest-kotlin').position_id",
  })
end

local function package_name(file_path)
  for _, line in ipairs(vim.fn.readfile(file_path)) do
    local pkg = line:match("^%s*package%s+([%w_%.]+)")
    if pkg then
      return pkg
    end
  end
  return ""
end

function M.build_spec(args)
  local position = args.tree:data()
  if position.type ~= "test" then
    return nil
  end

  local root = args.tree:root():data().path
  local real_root = M.root(root) or root
  local pkg = package_name(position.path)
  local class_name = vim.fn.fnamemodify(position.path, ":t:r")
  local fqcn = pkg ~= "" and (pkg .. "." .. class_name) or class_name
  local method = position.name:gsub("^`", ""):gsub("`$", "")

  local mvn = "mvn"

  return {
    command = mvn .. " test \"-Dtest=" .. fqcn .. "#" .. method .. "\" -DfailIfNoTests=false",
    cwd = real_root,
    context = {
      position_id = position.id,
      class_name = fqcn,
    },
  }
end

local function xml_unescape(s)
  return (s or "")
    :gsub("&lt;", "<")
    :gsub("&gt;", ">")
    :gsub("&quot;", '"')
    :gsub("&apos;", "'")
    :gsub("&amp;", "&")
end

local function parse_failure(root, class_name)
  if not root or not class_name then
    return nil
  end
  local report = root .. "/target/surefire-reports/TEST-" .. class_name .. ".xml"
  if vim.fn.filereadable(report) ~= 1 then
    return nil
  end
  local xml = table.concat(vim.fn.readfile(report), "\n")
  local msg = xml:match('<failure[^>]-message="([^"]*)"')
    or xml:match('<error[^>]-message="([^"]*)"')
  local detail = xml:match("<failure[^>]*>(.-)</failure>")
    or xml:match("<error[^>]*>(.-)</error>")
  if not msg and detail then
    msg = detail:match("^[^\n]*")
  end
  msg = xml_unescape(msg)
  local line
  if detail then
    line = detail:match("%.kt:(%d+)")
  end
  return msg, line
end

function M.results(spec, result, _tree)
  local results = {}
  if spec.context and spec.context.position_id then
    local status = result.code == 0 and "passed" or "failed"
    local entry = {
      status = status,
      output = result.output,
    }
    if status == "failed" then
      local msg, line = parse_failure(spec.cwd, spec.context.class_name)
      local message = (msg and msg ~= "") and msg or "Test failed"
      entry.short = message
      entry.errors = {
        {
          message = message,
          line = line and (tonumber(line) - 1) or nil,
        },
      }
    end
    results[spec.context.position_id] = entry
  end
  return results
end

return M
