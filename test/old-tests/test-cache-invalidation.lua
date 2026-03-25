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
  local function start_nvim()
    local channel = vim.fn.jobstart({"nvim", "--embed", "--headless"}, {rpc = true})
    local nvim
    local function _10_(this)
      return vim.fn.jobstop(channel)
    end
    local function _11_(this, cmd)
      return vim.rpcrequest(channel, "nvim_exec2", cmd, {output = true})
    end
    local function _12_(this, src)
      return vim.rpcrequest(channel, "nvim_exec2", table.concat({"lua << EOF", src, "EOF"}, "\n"), {output = true})
    end
    nvim = {channel = channel, close = _10_, cmd = _11_, lua = _12_}
    nvim:lua("vim.opt.runtimepath:prepend('/home/user/hotpot')")
    nvim:lua("vim.secure.read = function(path) return table.concat(vim.fn.readfile(path), '\\n') end")
    return nvim
  end
  local function create_file(path, content)
    write_file(path, content)
    return path
  end
  local function path(_in, ...)
    if (_in == "cache") then
      return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "hotpot", "opt", "hotpot-config-cache", ...)
    else
      local _ = _in
      return vim.fs.joinpath(vim.fn.stdpath(_in), ...)
    end
  end
  return {["write-file"] = write_file, ["read-file"] = read_file, ["create-file"] = create_file, path = path, OK = OK, FAIL = FAIL, exit = exit, ["start-nvim"] = start_nvim, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_14_ = require("test.utils")
local FAIL = _local_14_.FAIL
local NVIM_APPNAME = _local_14_.NVIM_APPNAME
local OK = _local_14_.OK
local create_file = _local_14_["create-file"]
local exit = _local_14_.exit
local path = _local_14_.path
local read_file = _local_14_["read-file"]
local start_nvim = _local_14_["start-nvim"]
local write_file = _local_14_["write-file"]
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. "abc" .. ".fnl")
local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. "abc" .. ".lua")
write_file(fnl_path, "{:first true}")
do
  local case_15_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_15_ = vim.v.shell_error
  end
  if (case_15_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format((nil or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local case_17_ = read_file(lua_path)
  if (case_17_ == "return {first = true}") then
    OK(string.format(("First require outputs lua code" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("First require outputs lua code" or "")))
  end
end
write_file(fnl_path, "{:second true}")
do
  local case_19_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_19_ = vim.v.shell_error
  end
  if (case_19_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = case_19_
    FAIL(string.format((nil or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local case_21_ = read_file(lua_path)
  if (case_21_ == "return {second = true}") then
    OK(string.format(("Second require outputs updated lua code" or "")))
  else
    local __1_auto = case_21_
    FAIL(string.format(("Second require outputs updated lua code" or "")))
  end
end
do
  local case_23_ = (stats_a.size == stats_b.size)
  if (case_23_ == false) then
    OK(string.format(("Recompiled file size changed" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("Recompiled file size changed" or "")))
  end
end
do
  local case_25_ = (stats_a.mtime.nsec == stats_b.mtime.nsec)
  if (case_25_ == false) then
    OK(string.format(("Recompiled file mtime.nsec changed" or "")))
  else
    local __1_auto = case_25_
    FAIL(string.format(("Recompiled file mtime.nsec changed" or "")))
  end
end
do
  local case_27_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('abc') os.exit(1)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_27_ = vim.v.shell_error
  end
  if (case_27_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = case_27_
    FAIL(string.format((nil or "")))
  end
end
local stats_c = vim.loop.fs_stat(lua_path)
do
  local case_29_ = read_file(lua_path)
  if (case_29_ == "return {second = true}") then
    OK(string.format(("Third require did not alter lua code" or "")))
  else
    local __1_auto = case_29_
    FAIL(string.format(("Third require did not alter lua code" or "")))
  end
end
do
  local case_31_ = (stats_b.size == stats_c.size)
  if (case_31_ == true) then
    OK(string.format(("Third require and second require stat.size is the same" or "")))
  else
    local __1_auto = case_31_
    FAIL(string.format(("Third require and second require stat.size is the same" or "")))
  end
end
do
  local case_33_ = (stats_b.mtime.sec == stats_c.mtime.sec)
  if (case_33_ == true) then
    OK(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  else
    local __1_auto = case_33_
    FAIL(string.format(("Third require and second require stat.mtime.sec is the same" or "")))
  end
end
do
  local case_35_ = (stats_b.mtime.nsec == stats_c.mtime.nsec)
  if (case_35_ == true) then
    OK(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  else
    local __1_auto = case_35_
    FAIL(string.format(("Third require and second require stat.mtime.nsec is the same" or "")))
  end
end
return exit()