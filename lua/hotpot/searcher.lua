local function slash_modname(modname)
  return string.gsub(modname, "%.", "/")
end
local function globsearch_runtime_path(spec)
  local all_3f = spec["all?"]
  local glob = spec["glob"]
  local path = spec["path"]
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
  local modnames = spec["modnames"]
  local prefix = spec["prefix"]
  local extension = spec["extension"]
  local paths
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, modname in ipairs(modnames) do
      local val_23_auto = join_path(prefix, (slash_modname(modname) .. "." .. extension))
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    paths = tbl_21_auto
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
      local tbl_19_auto = matches
      for _0, path in ipairs(paths0) do
        local val_20_auto = vim.fs.normalize(path, {expand_env = false})
        table.insert(tbl_19_auto, val_20_auto)
      end
      matches = tbl_19_auto
    else
      local _0 = _5_
      matches = matches
    end
  end
  return matches
end
local function modsearch_package_path(spec)
  local _let_7_ = require("hotpot.fs")
  local file_exists_3f = _let_7_["file-exists?"]
  local modnames = spec["modnames"]
  local extension = spec["extension"]
  local modnames0
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, modname in ipairs(modnames) do
      local val_23_auto = slash_modname(modname)
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    modnames0 = tbl_21_auto
  end
  local templates = string.gmatch((package.path .. ";"), "(.-);")
  local build_path_with
  local function _9_(modname)
    local function _10_(_241, _242)
      return (_241 .. modname .. _242 .. "." .. extension)
    end
    return _10_
  end
  build_path_with = _9_
  local result
  do
    local template_match = nil
    for template in templates do
      if template_match then break end
      local mod_match = nil
      for _, modname in ipairs(modnames0) do
        if mod_match then break end
        local _11_, _12_ = string.gsub(template, "(.*)%?(.*)%.lua$", build_path_with(modname))
        local and_13_ = ((nil ~= _11_) and (_12_ == 1))
        if and_13_ then
          local path = _11_
          and_13_ = file_exists_3f(path)
        end
        if and_13_ then
          local path = _11_
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
  local function _16_(...)
    local _17_ = ...
    if ((_G.type(_17_) == "table") and (_17_[1] == nil)) then
      local function _18_(...)
        local _19_ = ...
        if ((_G.type(_19_) == "table") and (_19_[1] == nil)) then
          return {}
        else
          local __87_auto = _19_
          return ...
        end
      end
      local function _21_(...)
        if spec0["package-path?"] then
          return modsearch_package_path(spec0)
        else
          return {}
        end
      end
      return _18_(_21_(...))
    else
      local __87_auto = _17_
      return ...
    end
  end
  local function _23_()
    if spec0["runtime-path?"] then
      return modsearch_runtime_path(spec0)
    else
      return {}
    end
  end
  return _16_(_23_())
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