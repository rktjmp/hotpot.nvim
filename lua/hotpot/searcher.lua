local function slash_modname(modname)
  return string.gsub(modname, "%.", "/")
end
local function search_runtime_path(spec)
  local _let_1_ = require("hotpot.fs")
  local join_path = _let_1_["join-path"]
  local _let_2_ = spec
  local all_3f = _let_2_["all?"]
  local modnames = _let_2_["modnames"]
  local prefix = _let_2_["prefix"]
  local extension = _let_2_["extension"]
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
    local _5_ = vim.api.nvim_get_runtime_file(possible_path, all_3f)
    if (nil ~= _5_) then
      local paths0 = _5_
      local tbl_17_auto = matches
      local i_18_auto = #tbl_17_auto
      for _0, path in ipairs(paths0) do
        local val_19_auto = path
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      matches = tbl_17_auto
    else
      matches = nil
    end
  end
  return matches
end
local function search_package_path(spec)
  local _let_8_ = require("hotpot.fs")
  local file_exists_3f = _let_8_["file-exists?"]
  local _let_9_ = spec
  local modnames = _let_9_["modnames"]
  local extension = _let_9_["extension"]
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
  local function _11_(modname)
    local function _12_(_241, _242)
      return (_241 .. modname .. _242 .. "." .. extension)
    end
    return _12_
  end
  build_path_with = _11_
  local result
  do
    local template_match = nil
    for template in templates do
      if template_match then break end
      local mod_match = nil
      for _, modname in ipairs(modnames0) do
        if mod_match then break end
        local _13_, _14_ = string.gsub(template, "(.*)%?(.*)%.lua$", build_path_with(modname))
        local function _15_()
          local path = _13_
          return file_exists_3f(path)
        end
        if (((nil ~= _13_) and (_14_ == 1)) and _15_()) then
          local path = _13_
          mod_match = path
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
local function search(spec)
  _G.assert((nil ~= spec), "Missing argument spec on fnl/hotpot/searcher.fnl:32")
  local defaults = {["runtime-path?"] = true, ["package-path?"] = true, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"modnames", "extension", "prefix"}) do
    assert((spec0)[key], ("search spec must have " .. key .. " field"))
  end
  local function _17_(...)
    local _18_ = ...
    if ((_G.type(_18_) == "table") and ((_18_)[1] == nil)) then
      local function _19_(...)
        local _20_ = ...
        if ((_G.type(_20_) == "table") and ((_20_)[1] == nil)) then
          return nil
        elseif true then
          local __75_auto = _20_
          return ...
        else
          return nil
        end
      end
      local function _22_(...)
        if spec0["package-path?"] then
          return search_package_path(spec0)
        else
          return {}
        end
      end
      return _19_(_22_(...))
    elseif true then
      local __75_auto = _18_
      return ...
    else
      return nil
    end
  end
  local function _24_()
    if spec0["runtime-path?"] then
      return search_runtime_path(spec0)
    else
      return {}
    end
  end
  return _17_(_24_())
end
return {search = search}