package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_12_(ok_13_, ...)
      fh:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _2_()
      return fh:write(lines)
    end
    local _4_
    do
      local t_3_ = _G
      if (nil ~= t_3_) then
        t_3_ = t_3_.package
      else
      end
      if (nil ~= t_3_) then
        t_3_ = t_3_.loaded
      else
      end
      if (nil ~= t_3_) then
        t_3_ = t_3_.fennel
      else
      end
      _4_ = t_3_
    end
    local or_8_ = _4_ or _G.debug
    if not or_8_ then
      local function _9_()
        return ""
      end
      or_8_ = {traceback = _9_}
    end
    return close_handlers_12_(_G.xpcall(_2_, or_8_.traceback))
  end
  local results = {passes = 0, fails = 0}
  local function OK(message)
    results.passes = (1 + results.passes)
    return print("OK", message)
  end
  local function FAIL(message)
    results.fails = (1 + results.fails)
    return print("FAIL", message)
  end
  local function exit()
    print("\n")
    return os.exit(results.fails)
  end
  vim.opt.runtimepath:prepend(vim.loop.cwd())
  require("hotpot")
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_10_ = require("test.utils")
local FAIL = _local_10_["FAIL"]
local NVIM_APPNAME = _local_10_["NVIM_APPNAME"]
local OK = _local_10_["OK"]
local exit = _local_10_["exit"]
local read_file = _local_10_["read-file"]
local write_file = _local_10_["write-file"]
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local _local_11_ = require("hotpot.api.cache")
local cache_prefix = _local_11_["cache-prefix"]
local function make_plugin(file)
  local config_dir = vim.fn.stdpath("config")
  local fnl_path = (config_dir .. "/plugin/" .. file .. ".fnl")
  local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/" .. file .. ".lua")
  write_file(fnl_path, "(set _G.exit (+ 1 (or _G.exit 100)))")
  return fnl_path, lua_path
end
local plugin_path_1, lua_path_1 = make_plugin("my_plugin_1")
local plugin_path_2, lua_path_2 = make_plugin("nested/deeply/my-plugin-2")
local plugin_path_3, lua_path_3 = make_plugin("init")
local plugin_path_4, lua_path_4 = make_plugin("init/init.fnl")
local lua_paths = {lua_path_1, lua_path_2, lua_path_3, lua_path_4}
do
  local _12_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _12_ = vim.v.shell_error
  end
  if (_12_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically" or "")))
  else
    local __1_auto = _12_
    FAIL(string.format(("plugin/*.fnl executed automatically" or "")))
  end
end
do
  local _14_
  do
    local exists_3f = true
    for _, path in ipairs(lua_paths) do
      exists_3f = (exists_3f and vim.loop.fs_access(path, "R"))
    end
    _14_ = exists_3f
  end
  if (_14_ == true) then
    OK(string.format(("plugin lua files exists" or "")))
  else
    local __1_auto = _14_
    FAIL(string.format(("plugin lua files exists" or "")))
  end
end
local stats_before
do
  local tbl_21_ = {}
  local i_22_ = 0
  for _, path in ipairs(lua_paths) do
    local val_23_ = vim.loop.fs_stat(path)
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  stats_before = tbl_21_
end
do
  local _17_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _17_ = vim.v.shell_error
  end
  if (_17_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically second time" or "")))
  else
    local __1_auto = _17_
    FAIL(string.format(("plugin/*.fnl executed automatically second time" or "")))
  end
end
local stats_after
do
  local tbl_21_ = {}
  local i_22_ = 0
  for _, path in ipairs(lua_paths) do
    local val_23_ = vim.loop.fs_stat(path)
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  stats_after = tbl_21_
end
do
  local _20_
  do
    local same_3f = true
    for i = 1, #lua_paths do
      local before = stats_before[i]
      local after = stats_after[i]
      same_3f = ((before.mtime.sec == after.mtime.sec) and (before.mtime.nsec == after.mtime.nsec))
    end
    _20_ = same_3f
  end
  if (_20_ == true) then
    OK(string.format(("plugin lua files were not recompiled" or "")))
  else
    local __1_auto = _20_
    FAIL(string.format(("plugin lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(plugin_path_1)
do
  local _22_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _22_ = vim.v.shell_error
  end
  if (_22_ == 103) then
    OK(string.format(("removed plugin/ file is removed from cache" or "")))
  else
    local __1_auto = _22_
    FAIL(string.format(("removed plugin/ file is removed from cache" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _24_ = vim.loop.fs_access(lua_path_1, "R")
  if (_24_ == false) then
    OK(string.format(("plugin lua file removed" or "")))
  else
    local __1_auto = _24_
    FAIL(string.format(("plugin lua file removed" or "")))
  end
else
end
return exit()