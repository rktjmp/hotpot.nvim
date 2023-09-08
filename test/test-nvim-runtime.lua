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
local plugin_path_1 = p("/plugin/my_plugin_1.fnl")
local lua_path_1 = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/my_plugin_1.lua")
local plugin_path_2 = p("/plugin/nested/deeply/my_plugin_2.fnl")
local lua_path_2 = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/nested/deeply/my_plugin_2.lua")
write_file(plugin_path_1, "(set _G.exit_1 11)")
write_file(plugin_path_2, "(set _G.exit_2 22)")
do
  local _5_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.exit_1 = 0\n                        _G.exit_2 = 0\n                        vim.defer_fn(function()\n                                      os.exit(_G.exit_1 + _G.exit_2)\n                         end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _5_ = vim.v.shell_error
  end
  if (_5_ == 33) then
    OK(string.format(("plugin/*.fnl executed automatically" or "")))
  elseif true then
    local __1_auto = _5_
    FAIL(string.format(("plugin/*.fnl executed automatically" or "")))
  else
  end
end
do
  local _7_ = (vim.loop.fs_access(lua_path_1, "R") and vim.loop.fs_access(lua_path_2, "R"))
  if (_7_ == true) then
    OK(string.format(("plugin lua files exists" or "")))
  elseif true then
    local __1_auto = _7_
    FAIL(string.format(("plugin lua files exists" or "")))
  else
  end
end
local stats_a_1 = vim.loop.fs_stat(lua_path_1)
local stats_a_2 = vim.loop.fs_stat(lua_path_2)
do
  local _9_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.exit_1 = 0\n                        _G.exit_2 = 0\n                        vim.defer_fn(function()\n                                      os.exit(_G.exit_1 + _G.exit_2)\n                         end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _9_ = vim.v.shell_error
  end
  if (_9_ == 33) then
    OK(string.format(("plugin/*.fnl executed automatically second time" or "")))
  elseif true then
    local __1_auto = _9_
    FAIL(string.format(("plugin/*.fnl executed automatically second time" or "")))
  else
  end
end
local stats_b_1 = vim.loop.fs_stat(lua_path_1)
local stats_b_2 = vim.loop.fs_stat(lua_path_2)
do
  local _11_ = ((stats_a_1.mtime.sec == stats_b_1.mtime.sec) and (stats_a_1.mtime.nsec == stats_b_1.mtime.nsec) and (stats_a_2.mtime.sec == stats_b_2.mtime.sec) and (stats_a_2.mtime.nsec == stats_b_2.mtime.nsec))
  if (_11_ == true) then
    OK(string.format(("plugin lua files were not recompiled" or "")))
  elseif true then
    local __1_auto = _11_
    FAIL(string.format(("plugin lua files were not recompiled" or "")))
  else
  end
end
vim.loop.fs_unlink(plugin_path_1)
do
  local _13_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.exit_1 = 0\n                        _G.exit_2 = 0\n                        vim.defer_fn(function() os.exit(_G.exit_1 + _G.exit_2) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _13_ = vim.v.shell_error
  end
  if (_13_ == 22) then
    OK(string.format(("plugin did not zombie" or "")))
  elseif true then
    local __1_auto = _13_
    FAIL(string.format(("plugin did not zombie" or "")))
  else
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _15_ = vim.loop.fs_access(lua_path_1, "R")
  if (_15_ == false) then
    OK(string.format(("plugin lua file removed" or "")))
  elseif true then
    local __1_auto = _15_
    FAIL(string.format(("plugin lua file removed" or "")))
  else
  end
else
end
return exit()