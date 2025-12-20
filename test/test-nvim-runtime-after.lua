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
local plugin_path = p("/plugin/my_plugin.fnl")
local after_path = p("/after/plugin/not_my_plugin.fnl")
local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-after/plugin/not_my_plugin.lua")
write_file(plugin_path, "(set _G.plugin_time (vim.loop.hrtime))")
write_file(after_path, "(set _G.after_time (vim.loop.hrtime))")
do
  local _12_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _12_ = vim.v.shell_error
  end
  if (_12_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _12_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
do
  local _14_ = vim.loop.fs_access(lua_path, "R")
  if (_14_ == true) then
    OK(string.format(("lua files exists" or "")))
  else
    local __1_auto = _14_
    FAIL(string.format(("lua files exists" or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local _16_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _16_ = vim.v.shell_error
  end
  if (_16_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _16_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local _18_ = ((stats_a.mtime.sec == stats_b.mtime.sec) and (stats_a.mtime.nsec == stats_b.mtime.nsec))
  if (_18_ == true) then
    OK(string.format(("lua files were not recompiled" or "")))
  else
    local __1_auto = _18_
    FAIL(string.format(("lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(after_path)
do
  local _20_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.after_time == 1 and _G.plugin_time ~= 1000 then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _20_ = vim.v.shell_error
  end
  if (_20_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _20_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _22_ = vim.loop.fs_access(lua_path, "R")
  if (_22_ == false) then
    OK(string.format(("after plugin lua file removed" or "")))
  else
    local __1_auto = _22_
    FAIL(string.format(("after plugin lua file removed" or "")))
  end
else
end
return exit()