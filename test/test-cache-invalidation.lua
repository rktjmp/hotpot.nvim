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
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. "abc" .. ".fnl")
local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. "abc" .. ".lua")
write_file(fnl_path, "{:first true}")
require("abc")
do
  local _4_ = read_file(lua_path)
  if (_4_ == "return {first = true}") then
    OK(string.format("Outputs correct lua code"))
  elseif true then
    local __1_auto = _4_
    FAIL(string.format("Outputs correct lua code"))
  else
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
vim.loop.sleep(50)
write_file(fnl_path, "{:second true}")
package.loaded.abc = nil
require("abc")
local stats_b = vim.loop.fs_stat(lua_path)
do
  local _6_ = read_file(lua_path)
  if (_6_ == "return {second = true}") then
    OK(string.format("Outputs updated lua code"))
  elseif true then
    local __1_auto = _6_
    FAIL(string.format("Outputs updated lua code"))
  else
  end
end
do
  local _8_ = (stats_a.size == stats_b.size)
  if (_8_ == false) then
    OK(string.format("size changed"))
  elseif true then
    local __1_auto = _8_
    FAIL(string.format("size changed"))
  else
  end
end
do
  local _10_ = (stats_a.mtime.nsec == stats_b.mtime.nsec)
  if (_10_ == false) then
    OK(string.format("mtime.nsec changed"))
  elseif true then
    local __1_auto = _10_
    FAIL(string.format("mtime.nsec changed"))
  else
  end
end
package.loaded.abc = nil
require("abc")
local stats_c = vim.loop.fs_stat(lua_path)
do
  local _12_ = read_file(lua_path)
  if (_12_ == "return {second = true}") then
    OK(string.format("Didnt alter lua code"))
  elseif true then
    local __1_auto = _12_
    FAIL(string.format("Didnt alter lua code"))
  else
  end
end
do
  local _14_ = (stats_b.size == stats_c.size)
  if (_14_ == true) then
    OK(string.format("size same"))
  elseif true then
    local __1_auto = _14_
    FAIL(string.format("size same"))
  else
  end
end
do
  local _16_ = (stats_b.mtime.sec == stats_c.mtime.sec)
  if (_16_ == true) then
    OK(string.format("mtime.sec same"))
  elseif true then
    local __1_auto = _16_
    FAIL(string.format("mtime.sec same"))
  else
  end
end
do
  local _18_ = (stats_b.mtime.nsec == stats_c.mtime.nsec)
  if (_18_ == true) then
    OK(string.format("mtime.nsec same"))
  elseif true then
    local __1_auto = _18_
    FAIL(string.format("mtime.nsec same"))
  else
  end
end
return exit()