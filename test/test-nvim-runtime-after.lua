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
local plugin_path = p("/plugin/my_plugin.fnl")
local after_path = p("/after/plugin/not_my_plugin.fnl")
local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-after/plugin/not_my_plugin.lua")
write_file(plugin_path, "(set _G.plugin_time (vim.loop.hrtime))")
write_file(after_path, "(set _G.after_time (vim.loop.hrtime))")
do
  local _5_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _5_ = vim.v.shell_error
  end
  if (_5_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _5_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
do
  local _7_ = vim.loop.fs_access(lua_path, "R")
  if (_7_ == true) then
    OK(string.format(("lua files exists" or "")))
  else
    local __1_auto = _7_
    FAIL(string.format(("lua files exists" or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local _9_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _9_ = vim.v.shell_error
  end
  if (_9_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _9_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local _11_ = ((stats_a.mtime.sec == stats_b.mtime.sec) and (stats_a.mtime.nsec == stats_b.mtime.nsec))
  if (_11_ == true) then
    OK(string.format(("lua files were not recompiled" or "")))
  else
    local __1_auto = _11_
    FAIL(string.format(("lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(after_path)
do
  local _13_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.after_time == 1 and _G.plugin_time ~= 1000 then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _13_ = vim.v.shell_error
  end
  if (_13_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local _15_ = vim.loop.fs_access(lua_path, "R")
  if (_15_ == false) then
    OK(string.format(("after plugin lua file removed" or "")))
  else
    local __1_auto = _15_
    FAIL(string.format(("after plugin lua file removed" or "")))
  end
else
end
return exit()