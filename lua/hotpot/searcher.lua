local function slash_modname(modname)
  local _let_1_ = require("hotpot.fs")
  local path_separator = _let_1_["path-separator"]
  return string.gsub(modname, "%.", path_separator())
end
local function search_runtime_path(spec)
  local _let_2_ = require("hotpot.fs")
  local join_path = _let_2_["join-path"]
  local _let_3_ = spec
  local all_3f = _let_3_["all?"]
  local modnames = _let_3_["modnames"]
  local prefix = _let_3_["prefix"]
  local extension = _let_3_["extension"]
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
    local _6_ = vim.api.nvim_get_runtime_file(possible_path, all_3f)
    if (nil ~= _6_) then
      local paths0 = _6_
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
  local _let_9_ = require("hotpot.fs")
  local file_exists_3f = _let_9_["file-exists?"]
  local _let_10_ = spec
  local modnames = _let_10_["modnames"]
  local extension = _let_10_["extension"]
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
  _G.assert((nil ~= spec), "Missing argument spec on /home/soup/projects/personal/hotpot/master/fnl/hotpot/searcher.fnl:33")
  local defaults = {["runtime-path?"] = true, ["package-path?"] = true, ["all?"] = false}
  local spec0 = vim.tbl_extend("keep", spec, defaults)
  for _, key in ipairs({"modnames", "extension", "prefix"}) do
    assert((spec0)[key], ("search spec must have " .. key .. " field"))
  end
  local function _18_(...)
    local _19_ = ...
    if ((_G.type(_19_) == "table") and ((_19_)[1] == nil)) then
      local function _20_(...)
        local _21_ = ...
        if ((_G.type(_21_) == "table") and ((_21_)[1] == nil)) then
          return nil
        elseif true then
          local __75_auto = _21_
          return ...
        else
          return nil
        end
      end
      local function _23_(...)
        if spec0["package-path?"] then
          return search_package_path(spec0)
        else
          return {}
        end
      end
      return _20_(_23_(...))
    elseif true then
      local __75_auto = _19_
      return ...
    else
      return nil
    end
  end
  local function _25_()
    if spec0["runtime-path?"] then
      return search_runtime_path(spec0)
    else
      return {}
    end
  end
  return _18_(_25_())
end
return {search = search}