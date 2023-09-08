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
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for _, modname in ipairs(modnames) do
      local val_19_auto = join_path(prefix, (slash_modname(modname) .. "." .. extension))
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    paths = tbl_17_auto
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
      local i_18_auto = #tbl_17_auto
      for _0, path in ipairs(paths0) do
        local val_19_auto = vim.fs.normalize(path, {expand_env = false})
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      matches = tbl_17_auto
    elseif true then
      local _0 = _7_
      matches = matches
    else
      matches = nil
    end
  end
  return matches
end
local function modsearch_package_path(spec)
  local _let_10_ = require("hotpot.fs")
  local file_exists_3f = _let_10_["file-exists?"]
  local _let_11_ = spec
  local modnames = _let_11_["modnames"]
  local extension = _let_11_["extension"]
  local modnames0
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for _, modname in ipairs(modnames) do
      local val_19_auto = slash_modname(modname)
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    modnames0 = tbl_17_auto
  end
  local templates = string.gmatch((package.path .. ";"), "(.-);")
  local build_path_with
  local function _13_(modname)
    local function _14_(_241, _242)
      return (_241 .. modname .. _242 .. "." .. extension)
    end
    return _14_
  end
  build_path_with = _13_
  local result
  do
    local template_match = nil
    for template in templates do
      if template_match then break end
      local mod_match = nil
      for _, modname in ipairs(modnames0) do
        if mod_match then break end
        local _15_, _16_ = string.gsub(template, "(.*)%?(.*)%.lua$", build_path_with(modname))
        local function _17_()
          local path = _15_
          return file_exists_3f(path)
        end
        if (((nil ~= _15_) and (_16_ == 1)) and _17_()) then
          local path = _15_
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
    assert((spec0)[key], ("search spec must have " .. key .. " field"))
  end
  local function _19_(...)
    local _20_ = ...
    if ((_G.type(_20_) == "table") and ((_20_)[1] == nil)) then
      local function _21_(...)
        local _22_ = ...
        if ((_G.type(_22_) == "table") and ((_22_)[1] == nil)) then
          return {}
        elseif true then
          local __75_auto = _22_
          return ...
        else
          return nil
        end
      end
      local function _24_(...)
        if spec0["package-path?"] then
          return modsearch_package_path(spec0)
        else
          return {}
        end
      end
      return _21_(_24_(...))
    elseif true then
      local __75_auto = _20_
      return ...
    else
      return nil
    end
  end
  local function _26_()
    if spec0["runtime-path?"] then
      return modsearch_runtime_path(spec0)
    else
      return {}
    end
  end
  return _19_(_26_())
end
local function glob_search(spec)
  _G.assert((nil ~= spec), "Missing argument spec on fnl/hotpot/searcher.fnl:78")
  local defaults = {path = vim.go.rtp, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"glob"}) do
    assert((spec0)[key], ("glob-search spec must have " .. key .. " field"))
  end
  return globsearch_runtime_path(spec0)
end
return {["mod-search"] = mod_search, ["glob-search"] = glob_search}