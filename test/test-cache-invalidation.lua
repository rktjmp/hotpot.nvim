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
do
  local _4_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _4_ = vim.v.shell_error
  end
  if (_4_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _4_
    FAIL(string.format((nil or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local _6_ = read_file(lua_path)
  if (_6_ == "return {first = true}") then
    OK(string.format(("First require outputs lua code" or "")))
  else
    local __1_auto = _6_
    FAIL(string.format(("First require outputs lua code" or "")))
  end
end
write_file(fnl_path, "{:second true}")
do
  local _8_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _8_ = vim.v.shell_error
  end
  if (_8_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _8_
    FAIL(string.format((nil or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local _10_ = read_file(lua_path)
  if (_10_ == "return {second = true}") then
    OK(string.format(("Second require outputs updated lua code" or "")))
  else
    local __1_auto = _10_
    FAIL(string.format(("Second require outputs updated lua code" or "")))
  end
end
do
  local _12_ = (stats_a.size == stats_b.size)
  if (_12_ == false) then
    OK(string.format(("Recompiled file size changed" or "")))
  else
    local __1_auto = _12_
    FAIL(string.format(("Recompiled file size changed" or "")))
  end
end
do
  local _14_ = (stats_a.mtime.nsec == stats_b.mtime.nsec)
  if (_14_ == false) then
    OK(string.format(("Recompiled file mtime.nsec changed" or "")))
  else
    local __1_auto = _14_
    FAIL(string.format(("Recompiled file mtime.nsec changed" or "")))
  end
end
do
  local _16_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _16_ = vim.v.shell_error
  end
  if (_16_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _16_
    FAIL(string.format((nil or "")))
  end
end
local stats_c = vim.loop.fs_stat(lua_path)
do
  local _18_ = read_file(lua_path)
  if (_18_ == "return {second = true}") then
    OK(string.format(("Third require did not alter lua code" or "")))
  else
    local __1_auto = _18_
    FAIL(string.format(("Third require did not alter lua code" or "")))
  end
end
do
  local _20_ = (stats_b.size == stats_c.size)
  if (_20_ == true) then
    OK(string.format(("Third require and second require stat.size is the same" or "")))
  else
    local __1_auto = _20_
    FAIL(string.format(("Third require and second require stat.size is the same" or "")))
  end
end
do
  local _22_ = (stats_b.mtime.sec == stats_c.mtime.sec)
  if (_22_ == true) then
    OK(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  else
    local __1_auto = _22_
    FAIL(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  end
end
do
  local _24_ = (stats_b.mtime.nsec == stats_c.mtime.nsec)
  if (_24_ == true) then
    OK(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  else
    local __1_auto = _24_
    FAIL(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  end
end
return exit()