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
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. "abc" .. ".fnl")
local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. "abc" .. ".lua")
write_file(fnl_path, "{:first true}")
do
  local _11_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _11_ = vim.v.shell_error
  end
  if (_11_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _11_
    FAIL(string.format((nil or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local _13_ = read_file(lua_path)
  if (_13_ == "return {first = true}") then
    OK(string.format(("First require outputs lua code" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format(("First require outputs lua code" or "")))
  end
end
write_file(fnl_path, "{:second true}")
do
  local _15_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _15_ = vim.v.shell_error
  end
  if (_15_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _15_
    FAIL(string.format((nil or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local _17_ = read_file(lua_path)
  if (_17_ == "return {second = true}") then
    OK(string.format(("Second require outputs updated lua code" or "")))
  else
    local __1_auto = _17_
    FAIL(string.format(("Second require outputs updated lua code" or "")))
  end
end
do
  local _19_ = (stats_a.size == stats_b.size)
  if (_19_ == false) then
    OK(string.format(("Recompiled file size changed" or "")))
  else
    local __1_auto = _19_
    FAIL(string.format(("Recompiled file size changed" or "")))
  end
end
do
  local _21_ = (stats_a.mtime.nsec == stats_b.mtime.nsec)
  if (_21_ == false) then
    OK(string.format(("Recompiled file mtime.nsec changed" or "")))
  else
    local __1_auto = _21_
    FAIL(string.format(("Recompiled file mtime.nsec changed" or "")))
  end
end
do
  local _23_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _23_ = vim.v.shell_error
  end
  if (_23_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _23_
    FAIL(string.format((nil or "")))
  end
end
local stats_c = vim.loop.fs_stat(lua_path)
do
  local _25_ = read_file(lua_path)
  if (_25_ == "return {second = true}") then
    OK(string.format(("Third require did not alter lua code" or "")))
  else
    local __1_auto = _25_
    FAIL(string.format(("Third require did not alter lua code" or "")))
  end
end
do
  local _27_ = (stats_b.size == stats_c.size)
  if (_27_ == true) then
    OK(string.format(("Third require and second require stat.size is the same" or "")))
  else
    local __1_auto = _27_
    FAIL(string.format(("Third require and second require stat.size is the same" or "")))
  end
end
do
  local _29_ = (stats_b.mtime.sec == stats_c.mtime.sec)
  if (_29_ == true) then
    OK(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  else
    local __1_auto = _29_
    FAIL(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  end
end
do
  local _31_ = (stats_b.mtime.nsec == stats_c.mtime.nsec)
  if (_31_ == true) then
    OK(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  else
    local __1_auto = _31_
    FAIL(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  end
end
return exit()