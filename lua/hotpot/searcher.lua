local function slash_modname(modname)
  return string.gsub(modname, "%.", "/")
end
local function globsearch_runtime_path(spec)
  local _let_1_ = spec
  local all_3f = _let_1_["all?"]
  local glob = _let_1_["glob"]
  local path = _let_1_["path"]
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
  local _let_3_ = require("hotpot.fs")
  local join_path = _let_3_["join-path"]
  local _let_4_ = spec
  local all_3f = _let_4_["all?"]
  local modnames = _let_4_["modnames"]
  local prefix = _let_4_["prefix"]
  local extension = _let_4_["extension"]
  local paths
  do
    local tbl_19_auto = {}
    local i_20_auto = 0
    for _, modname in ipairs(modnames) do
      local val_21_auto = join_path(prefix, (slash_modname(modname) .. "." .. extension))
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    paths = tbl_19_auto
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
    local _7_ = vim.api.nvim_get_runtime_file(possible_path, all_3f)
    if (nil ~= _7_) then
      local paths0 = _7_
      local tbl_17_auto = matches
      for _0, path in ipairs(paths0) do
        local val_18_auto = vim.fs.normalize(path, {expand_env = false})
        table.insert(tbl_17_auto, val_18_auto)
      end
      matches = tbl_17_auto
    else
      local _0 = _7_
      matches = matches
    end
  end
  return matches
end
local function modsearch_package_path(spec)
  local _let_9_ = require("hotpot.fs")
  local file_exists_3f = _let_9_["file-exists?"]
  local _let_10_ = spec
  local modnames = _let_10_["modnames"]
  local extension = _let_10_["extension"]
  local modnames0
  do
    local tbl_19_auto = {}
    local i_20_auto = 0
    for _, modname in ipairs(modnames) do
      local val_21_auto = slash_modname(modname)
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    modnames0 = tbl_19_auto
  end
  local templates = string.gmatch((package.path .. ";"), "(.-);")
  local build_path_with
  local function _12_(modname)
    local function _13_(_241, _242)
      return (_241 .. modname .. _242 .. "." .. extension)
    end
    return _13_
  end
  build_path_with = _12_
  local result
  do
    local template_match = nil
    for template in templates do
      if template_match then break end
      local mod_match = nil
      for _, modname in ipairs(modnames0) do
        if mod_match then break end
        local _14_, _15_ = string.gsub(template, "(.*)%?(.*)%.lua$", build_path_with(modname))
        local function _16_()
          local path = _14_
          return file_exists_3f(path)
        end
        if (((nil ~= _14_) and (_15_ == 1)) and _16_()) then
          local path = _14_
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
  _G.assert((nil ~= spec), "Missing argument spec on fnl/hotpot/searcher.fnl:43")
  local defaults = {["runtime-path?"] = true, ["package-path?"] = true, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"modnames", "extension", "prefix"}) do
    assert(spec0[key], ("search spec must have " .. key .. " field"))
  end
  local function _18_(...)
    local _19_ = ...
    if ((_G.type(_19_) == "table") and (_19_[1] == nil)) then
      local function _20_(...)
        local _21_ = ...
        if ((_G.type(_21_) == "table") and (_21_[1] == nil)) then
          return {}
        else
          local __85_auto = _21_
          return ...
        end
      end
      local function _23_(...)
        if spec0["package-path?"] then
          return modsearch_package_path(spec0)
        else
          return {}
        end
      end
      return _20_(_23_(...))
    else
      local __85_auto = _19_
      return ...
    end
  end
  local function _25_()
    if spec0["runtime-path?"] then
      return modsearch_runtime_path(spec0)
    else
      return {}
    end
  end
  return _18_(_25_())
end
local function glob_search(spec)
  _G.assert((nil ~= spec), "Missing argument spec on fnl/hotpot/searcher.fnl:78")
  local defaults = {path = vim.go.rtp, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"glob"}) do
    assert(spec0[key], ("glob-search spec must have " .. key .. " field"))
  end
  return globsearch_runtime_path(spec0)
end
return {["mod-search"] = mod_search, ["glob-search"] = glob_search}