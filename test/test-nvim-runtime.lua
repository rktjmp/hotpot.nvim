package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_10_auto(ok_11_auto, ...)
      fh:close()
      if ok_11_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _3_()
      return fh:write(lines)
    end
    return close_handlers_10_auto(_G.xpcall(_3_, (package.loaded.fennel or debug).traceback))
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
  do end (vim.opt.runtimepath):prepend(vim.loop.cwd())
  require("hotpot")
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_1_ = require("test.utils")
local FAIL = _local_1_["FAIL"]
local NVIM_APPNAME = _local_1_["NVIM_APPNAME"]
local OK = _local_1_["OK"]
local exit = _local_1_["exit"]
local read_file = _local_1_["read-file"]
local write_file = _local_1_["write-file"]
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local _local_4_ = require("hotpot.api.cache")
local cache_prefix = _local_4_["cache-prefix"]
local function make_plugin(file)
  local config_dir = vim.fn.stdpath("config")
  local fnl_path = (config_dir .. "/plugin/" .. file .. ".fnl")
  local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/" .. file .. ".lua")
  write_file(fnl_path, "(set _G.exit (+ 1 (or _G.exit 100)))")
  return fnl_path, lua_path
end
local plugin_path_1, lua_path_1 = make_plugin("my_plugin_1")
local plugin_path_2, lua_path_2 = make_plugin("nested/deeply/my_plugin_2")
local plugin_path_3, lua_path_3 = make_plugin("init")
local plugin_path_4, lua_path_4 = make_plugin("init/init.fnl")
local lua_paths = {lua_path_1, lua_path_2, lua_path_3, lua_path_4}
do
  local _5_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _5_ = vim.v.shell_error
  end
  if (_5_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically" or "")))
  else
    local __1_auto = _5_
    FAIL(string.format(("plugin/*.fnl executed automatically" or "")))
  end
end
do
  local _7_
  do
    local exists_3f = true
    for _, path in ipairs(lua_paths) do
      exists_3f = (exists_3f and vim.loop.fs_access(path, "R"))
    end
    _7_ = exists_3f
  end
  if (_7_ == true) then
    OK(string.format(("plugin lua files exists" or "")))
  else
    local __1_auto = _7_
    FAIL(string.format(("plugin lua files exists" or "")))
  end
end
local stats_before
do
  local tbl_19_auto = {}
  local i_20_auto = 0
  for _, path in ipairs(lua_paths) do
    local val_21_auto = vim.loop.fs_stat(path)
    if (nil ~= val_21_auto) then
      i_20_auto = (i_20_auto + 1)
      do end (tbl_19_auto)[i_20_auto] = val_21_auto
    else
    end
  end
  stats_before = tbl_19_auto
end
do
  local _10_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _10_ = vim.v.shell_error
  end
  if (_10_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically second time" or "")))
  else
    local __1_auto = _10_
    FAIL(string.format(("plugin/*.fnl executed automatically second time" or "")))
  end
end
local stats_after
do
  local tbl_19_auto = {}
  local i_20_auto = 0
  for _, path in ipairs(lua_paths) do
    local val_21_auto = vim.loop.fs_stat(path)
    if (nil ~= val_21_auto) then
      i_20_auto = (i_20_auto + 1)
      do end (tbl_19_auto)[i_20_auto] = val_21_auto
    else
    end
  end
  stats_after = tbl_19_auto
end
do
  local _13_
  do
    local same_3f = true
    for i = 1, #lua_paths do
      local before = stats_before[i]
      local after = stats_after[i]
      same_3f = ((before.mtime.sec == after.mtime.sec) and (before.mtime.nsec == after.mtime.nsec))
    end
    _13_ = same_3f
  end
  if (_13_ == true) then
    OK(string.format(("plugin lua files were not recompiled" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format(("plugin lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(plugin_path_1)
do
  local _15_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _15_ = vim.v.shell_error
  end
  if (_15_ == 103) then
    OK(string.format(("removed plugin/ file is removed from cache" or "")))
  else
    local __1_auto = _15_
    FAIL(string.format(("removed plugin/ file is removed from cache" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _17_ = vim.loop.fs_access(lua_path_1, "R")
  if (_17_ == false) then
    OK(string.format(("plugin lua file removed" or "")))
  else
    local __1_auto = _17_
    FAIL(string.format(("plugin lua file removed" or "")))
  end
else
end
return exit()