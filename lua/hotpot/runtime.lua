local M = {}
local fmt = string.format
local LOCAL_CONFIG_FILE = ".hotpot.lua"
local function lazy_traceback()
  local _let_1_ = require("hotpot.traceback")
  local traceback = _let_1_["traceback"]
  return traceback
end
local function lookup_local_config(file)
  local _let_2_ = require("hotpot.fs")
  local file_exists_3f = _let_2_["file-exists?"]
  if string.match(file, "%.hotpot%.lua$") then
    if file_exists_3f(file) then
      return vim.fs.normalize(file)
    else
      return nil
    end
  else
    local _4_ = vim.fs.find(LOCAL_CONFIG_FILE, {path = file, upward = true, kind = "file"})
    if ((_G.type(_4_) == "table") and (nil ~= (_4_)[1])) then
      local path = (_4_)[1]
      return vim.fs.normalize(vim.loop.fs_realpath(path))
    elseif ((_G.type(_4_) == "table") and ((_4_)[1] == nil)) then
      return nil
    else
      return nil
    end
  end
end
local function loadfile_local_config(path)
  local function _7_(...)
    local _8_, _9_ = ...
    if (nil ~= _8_) then
      local loader = _8_
      local function _10_(...)
        local _11_, _12_ = ...
        if ((_11_ == true) and (nil ~= _12_)) then
          local config = _12_
          return vim.tbl_deep_extend("keep", config, {context = path}, M["default-config"]())
        elseif ((_11_ == false) and (nil ~= _12_)) then
          local e = _12_
          return nil, e
        elseif ((_11_ == nil) and (nil ~= _12_)) then
          local e = _12_
          return nil, e
        else
          return nil
        end
      end
      return _10_(pcall(loader))
    elseif ((_8_ == false) and (nil ~= _9_)) then
      local e = _9_
      return nil, e
    elseif ((_8_ == nil) and (nil ~= _9_)) then
      local e = _9_
      return nil, e
    else
      return nil
    end
  end
  return _7_(loadfile(path))
end
M["default-config"] = function()
  local function _15_(src)
    return src
  end
  return {compiler = {modules = {}, macros = {env = "_COMPILER"}, preprocessor = _15_, traceback = "hotpot"}, enable_hotpot_diagnostics = true, provide_require_fennel = false}
end
local user_config = M["default-config"]()
M["user-config"] = function()
  return user_config
end
M["set-user-config"] = function(given_config)
  local new_config = M["default-config"]()
  for _, k in ipairs({"preprocessor", "modules", "macros", "traceback"}) do
    local _16_
    do
      local t_17_ = given_config
      if (nil ~= t_17_) then
        t_17_ = (t_17_).compiler
      else
      end
      if (nil ~= t_17_) then
        t_17_ = (t_17_)[k]
      else
      end
      _16_ = t_17_
    end
    if (nil ~= _16_) then
      local val = _16_
      new_config["compiler"][k] = val
    else
    end
  end
  do
    local _21_
    do
      local t_22_ = given_config
      if (nil ~= t_22_) then
        t_22_ = (t_22_).provide_require_fennel
      else
      end
      _21_ = t_22_
    end
    if (nil ~= _21_) then
      local val = _21_
      new_config["provide_require_fennel"] = val
    else
    end
  end
  do
    local _25_
    do
      local t_26_ = given_config
      if (nil ~= t_26_) then
        t_26_ = (t_26_).enable_hotpot_diagnostics
      else
      end
      _25_ = t_26_
    end
    if (nil ~= _25_) then
      local val = _25_
      new_config["enable_hotpot_diagnostics"] = val
    else
    end
  end
  do
    local _29_ = new_config.compiler.traceback
    if (_29_ == "hotpot") then
    elseif (_29_ == "fennel") then
    elseif true then
      local _ = _29_
      error("invalid config.compiler.traceback value, must be 'hotpot' or 'fennel'")
    else
    end
  end
  user_config = new_config
  return user_config
end
M["lookup-local-config"] = function(file)
  return lookup_local_config(file)
end
M["loadfile-local-config"] = function(config_path)
  local _31_, _32_ = loadfile_local_config(config_path)
  if (nil ~= _31_) then
    local config = _31_
    return config
  elseif ((_31_ == nil) and (nil ~= _32_)) then
    local err = _32_
    vim.notify(fmt(("Hotpot could not load local config due to lua error.\n" .. "Path: %s\n" .. "Error: %s"), config_path, err), vim.log.levels.WARN)
    return nil
  elseif (_31_ == nil) then
    vim.notify(fmt(("Hotpot found local config but it return nil, update it to return a table insead.\n" .. "Path: %s\n"), config_path), vim.log.levels.WARN)
    return nil
  else
    return nil
  end
end
M["config-for-context"] = function(file)
  if (nil == file) then
    return M["user-config"]()
  else
    local _34_ = M["lookup-local-config"](file)
    if (_34_ == nil) then
      return M["user-config"]()
    elseif (nil ~= _34_) then
      local config_path = _34_
      local _35_ = M["loadfile-local-config"](config_path)
      if (nil ~= _35_) then
        local config = _35_
        return config
      elseif (_35_ == nil) then
        vim.notify("Using safe defaults", vim.log.levels.WARN)
        return M["default-config"]()
      else
        return nil
      end
    else
      return nil
    end
  end
end
M["set-user-config"](M["default-config"]())
M["proxied-keys"] = "traceback"
local function _39_(_241, _242)
  if (_242 == "traceback") then
    return lazy_traceback()
  else
    return nil
  end
end
return setmetatable(M, {__index = _39_})