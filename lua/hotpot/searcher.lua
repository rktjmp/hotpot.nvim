local function slash_modname(modname)
  return string.gsub(modname, "%.", "/")
end
local function globsearch_runtime_path(spec)
  local all_3f = spec["all?"]
  local glob = spec.glob
  local path = spec.path
  local limit
  if all_3f then
    limit = -1
  else
    limit = 1
  end
  local matches = {}
  for _, path0 in ipairs(vim.fn.globpath(path, glob, true, true)) do
    if (limit == #matches) then break end
    table.insert(matches, vim.fs.normalize(path0, {expand_env = false}))
    matches = matches
  end
  return matches
end
local function modsearch_runtime_path(spec)
  local _let_2_ = require("hotpot.fs")
  local join_path = _let_2_["join-path"]
  local all_3f = spec["all?"]
  local modnames = spec.modnames
  local prefix = spec.prefix
  local extensions = spec.extensions
  local paths
  do
    local t = {}
    for _, extension in ipairs(extensions) do
      local tbl_24_ = t
      for _0, modname in ipairs(modnames) do
        local val_25_ = join_path(prefix, (slash_modname(modname) .. "." .. extension))
        table.insert(tbl_24_, val_25_)
      end
      t = tbl_24_
    end
    paths = t
  end
  local limit
  if all_3f then
    limit = -1
  else
    limit = 1
  end
  local matches = {}
  for _, possible_path in ipairs(paths) do
    if (limit == #matches) then break end
    local case_4_ = vim.api.nvim_get_runtime_file(possible_path, all_3f)
    if (nil ~= case_4_) then
      local paths0 = case_4_
      local tbl_24_ = matches
      for _0, path in ipairs(paths0) do
        local val_25_ = vim.fs.normalize(path, {expand_env = false})
        table.insert(tbl_24_, val_25_)
      end
      matches = tbl_24_
    else
      local _0 = case_4_
      matches = matches
    end
  end
  return matches
end
local function modsearch_package_path(spec)
  local _let_6_ = require("hotpot.fs")
  local file_exists_3f = _let_6_["file-exists?"]
  local modnames = spec.modnames
  local extensions = spec.extensions
  local modnames0
  do
    local t = {}
    for _, extension in ipairs(extensions) do
      local tbl_24_ = t
      for _0, modname in ipairs(modnames) do
        local val_25_ = {slash_modname(modname), extension}
        table.insert(tbl_24_, val_25_)
      end
      t = tbl_24_
    end
    modnames0 = t
  end
  local templates = string.gmatch((package.path .. ";"), "(.-);")
  local build_path_with
  local function _7_(modname, extension)
    local function _8_(_241, _242)
      return (_241 .. modname .. _242 .. "." .. extension)
    end
    return _8_
  end
  build_path_with = _7_
  local result
  do
    local template_match = nil
    for template in templates do
      if template_match then break end
      local mod_match = nil
      for _, _9_ in ipairs(modnames0) do
        local modname = _9_[1]
        local extension = _9_[2]
        if mod_match then break end
        local case_10_, case_11_ = string.gsub(template, "(.*)%?(.*)%.lua$", build_path_with(modname, extension))
        local and_12_ = ((nil ~= case_10_) and (case_11_ == 1))
        if and_12_ then
          local path = case_10_
          and_12_ = file_exists_3f(path)
        end
        if and_12_ then
          local path = case_10_
          mod_match = vim.fs.normalize(path, {expand_env = false})
        else
          mod_match = nil
        end
      end
      template_match = mod_match
    end
    result = template_match
  end
  return {result}
end
local function mod_search(spec)
  if (nil == spec) then
    _G.error("Missing argument spec on fnl/hotpot/searcher.fnl:46", 2)
  else
  end
  local defaults = {["runtime-path?"] = true, ["package-path?"] = true, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"modnames", "extensions", "prefix"}) do
    assert(spec0[key], ("search spec must have " .. key .. " field"))
  end
  local function _16_(...)
    if ((_G.type(...) == "table") and ((...)[1] == nil)) then
      local function _17_(...)
        if ((_G.type(...) == "table") and ((...)[1] == nil)) then
          return {}
        else
          local __43_ = ...
          return ...
        end
      end
      local function _19_(...)
        if spec0["package-path?"] then
          return modsearch_package_path(spec0)
        else
          return {}
        end
      end
      return _17_(_19_(...))
    else
      local __43_ = ...
      return ...
    end
  end
  local function _21_()
    if spec0["runtime-path?"] then
      return modsearch_runtime_path(spec0)
    else
      return {}
    end
  end
  return _16_(_21_())
end
local function glob_search(spec)
  if (nil == spec) then
    _G.error("Missing argument spec on fnl/hotpot/searcher.fnl:87", 2)
  else
  end
  local defaults = {path = vim.go.rtp, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"glob"}) do
    assert(spec0[key], ("glob-search spec must have " .. key .. " field"))
  end
  return globsearch_runtime_path(spec0)
end
return {["mod-search"] = mod_search, ["glob-search"] = glob_search}