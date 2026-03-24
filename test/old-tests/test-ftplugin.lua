package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_13_(ok_14_, ...)
      fh:close()
      if ok_14_ then
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
    return close_handlers_13_(_G.xpcall(_2_, or_8_.traceback))
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
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_10_ = require("test.utils")
local FAIL = _local_10_.FAIL
local NVIM_APPNAME = _local_10_.NVIM_APPNAME
local OK = _local_10_.OK
local exit = _local_10_.exit
local read_file = _local_10_["read-file"]
local write_file = _local_10_["write-file"]
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local _local_11_ = require("hotpot.api.cache")
local cache_prefix = _local_11_["cache-prefix"]
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
  local case_12_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_12_ = vim.v.shell_error
  end
  if (case_12_ == 111) then
    OK(string.format(("ftplugin ran" or "")))
  else
    local __1_auto = case_12_
    FAIL(string.format(("ftplugin ran" or "")))
  end
end
do
  local case_14_ = (vim.loop.fs_access(lua_path_1, "R") and vim.loop.fs_access(lua_path_2, "R") and vim.loop.fs_access(lua_path_3, "R"))
  if (case_14_ == true) then
    OK(string.format(("ftplugin lua file exists" or "")))
  else
    local __1_auto = case_14_
    FAIL(string.format(("ftplugin lua file exists" or "")))
  end
end
local stats_a = {x = vim.loop.fs_stat(lua_path_1), y = vim.loop.fs_stat(lua_path_2), z = vim.loop.fs_stat(lua_path_3)}
do
  local case_16_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_16_ = vim.v.shell_error
  end
  if (case_16_ == 111) then
    OK(string.format(("ftplugin ran second time" or "")))
  else
    local __1_auto = case_16_
    FAIL(string.format(("ftplugin ran second time" or "")))
  end
end
local stats_b = {x = vim.loop.fs_stat(lua_path_1), y = vim.loop.fs_stat(lua_path_2), z = vim.loop.fs_stat(lua_path_3)}
do
  local case_18_ = ((stats_a.x.mtime.sec == stats_b.x.mtime.sec) and (stats_a.x.mtime.nsec == stats_b.x.mtime.nsec) and (stats_a.y.mtime.sec == stats_b.y.mtime.sec) and (stats_a.y.mtime.nsec == stats_b.y.mtime.nsec) and (stats_a.z.mtime.sec == stats_b.z.mtime.sec) and (stats_a.z.mtime.nsec == stats_b.z.mtime.nsec))
  if (case_18_ == true) then
    OK(string.format(("ftplugin lua file was not recompiled" or "")))
  else
    local __1_auto = case_18_
    FAIL(string.format(("ftplugin lua file was not recompiled" or "")))
  end
end
vim.loop.fs_unlink(fnl_path_1)
do
  local case_20_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.t1 = 0\n                         _G.t2 = 0\n                         _G.t3 = 0\n                         _G.after = 1\n                         vim.cmd('set ft=arst')\n                         vim.defer_fn(function()\n                           os.exit(_G.t1 + _G.t2 + _G.t3 + _G.after)\n                         end, 200)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_20_ = vim.v.shell_error
  end
  if (case_20_ == 110) then
    OK(string.format(("ftplugin ran second time" or "")))
  else
    local __1_auto = case_20_
    FAIL(string.format(("ftplugin ran second time" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local case_22_ = vim.loop.fs_access(lua_path_1, "R")
  if (case_22_ == false) then
    OK(string.format(("ftplugin lua file removed" or "")))
  else
    local __1_auto = case_22_
    FAIL(string.format(("ftplugin lua file removed" or "")))
  end
else
end
return exit()