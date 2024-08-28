package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_12_auto(ok_13_auto, ...)
      fh:close()
      if ok_13_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _2_()
      return fh:write(lines)
    end
    return close_handlers_12_auto(_G.xpcall(_2_, (package.loaded.fennel or _G.debug or {}).traceback))
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
local _local_3_ = require("test.utils")
local FAIL = _local_3_["FAIL"]
local NVIM_APPNAME = _local_3_["NVIM_APPNAME"]
local OK = _local_3_["OK"]
local exit = _local_3_["exit"]
local read_file = _local_3_["read-file"]
local write_file = _local_3_["write-file"]
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local _local_4_ = require("hotpot.api.cache")
local cache_prefix = _local_4_["cache-prefix"]
local fnl_path_1 = p("/ftplugin/arst.fnl")
local fnl_path_2 = p("/ftplugin/arst/nested.fnl")
local fnl_path_3 = p("/ftplugin/arst_under.fnl")
local fnl_path_4 = p("/after/ftplugin/arst_under.fnl")
local lua_path_1 = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-ftplugin/arst.lua")
local lua_path_2 = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-ftplugin/arst/nested.lua")
local lua_path_3 = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-ftplugin/arst_under.lua")
write_file(fnl_path_1, "(set _G.t1 1)")
write_file(fnl_path_2, "(set _G.t2 10)")
write_file(fnl_path_3, "(set _G.t3 100)")
write_file(fnl_path_4, "(set _G.after 0)")
do
  local _5_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _5_ = vim.v.shell_error
  end
  if (_5_ == 111) then
    OK(string.format(("ftplugin ran" or "")))
  else
    local __1_auto = _5_
    FAIL(string.format(("ftplugin ran" or "")))
  end
end
do
  local _7_ = (vim.loop.fs_access(lua_path_1, "R") and vim.loop.fs_access(lua_path_2, "R") and vim.loop.fs_access(lua_path_3, "R"))
  if (_7_ == true) then
    OK(string.format(("ftplugin lua file exists" or "")))
  else
    local __1_auto = _7_
    FAIL(string.format(("ftplugin lua file exists" or "")))
  end
end
local stats_a = {x = vim.loop.fs_stat(lua_path_1), y = vim.loop.fs_stat(lua_path_2), z = vim.loop.fs_stat(lua_path_3)}
do
  local _9_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _9_ = vim.v.shell_error
  end
  if (_9_ == 111) then
    OK(string.format(("ftplugin ran second time" or "")))
  else
    local __1_auto = _9_
    FAIL(string.format(("ftplugin ran second time" or "")))
  end
end
local stats_b = {x = vim.loop.fs_stat(lua_path_1), y = vim.loop.fs_stat(lua_path_2), z = vim.loop.fs_stat(lua_path_3)}
do
  local _11_ = ((stats_a.x.mtime.sec == stats_b.x.mtime.sec) and (stats_a.x.mtime.nsec == stats_b.x.mtime.nsec) and (stats_a.y.mtime.sec == stats_b.y.mtime.sec) and (stats_a.y.mtime.nsec == stats_b.y.mtime.nsec) and (stats_a.z.mtime.sec == stats_b.z.mtime.sec) and (stats_a.z.mtime.nsec == stats_b.z.mtime.nsec))
  if (_11_ == true) then
    OK(string.format(("ftplugin lua file was not recompiled" or "")))
  else
    local __1_auto = _11_
    FAIL(string.format(("ftplugin lua file was not recompiled" or "")))
  end
end
vim.loop.fs_unlink(fnl_path_1)
do
  local _13_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _13_ = vim.v.shell_error
  end
  if (_13_ == 110) then
    OK(string.format(("ftplugin ran second time" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format(("ftplugin ran second time" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _15_ = vim.loop.fs_access(lua_path_1, "R")
  if (_15_ == false) then
    OK(string.format(("ftplugin lua file removed" or "")))
  else
    local __1_auto = _15_
    FAIL(string.format(("ftplugin lua file removed" or "")))
  end
else
end
return exit()