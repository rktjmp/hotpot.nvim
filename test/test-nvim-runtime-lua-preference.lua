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
local fnl_plugin_path = p("/plugin/my_plugin_1.fnl")
local fnl_lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/my_plugin_1.lua")
local lua_plugin_path = p("/plugin/my_plugin_1.lua")
write_file(fnl_plugin_path, "(set _G.exit_val 99)")
write_file(lua_plugin_path, "_G.exit_val = 1")
do
  local _5_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.exit_1 = 0\n                       vim.defer_fn(function()\n                         os.exit(_G.exit_val)\n                       end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _5_ = vim.v.shell_error
  end
  if (_5_ == 1) then
    OK(string.format(("plugin/*.lua executed" or "")))
  elseif true then
    local __1_auto = _5_
    FAIL(string.format(("plugin/*.lua executed" or "")))
  else
  end
end
do
  local _7_ = vim.loop.fs_access(fnl_lua_path, "R")
  if (_7_ == false) then
    OK(string.format(("fnl never compiled" or "")))
  elseif true then
    local __1_auto = _7_
    FAIL(string.format(("fnl never compiled" or "")))
  else
  end
end
return exit()