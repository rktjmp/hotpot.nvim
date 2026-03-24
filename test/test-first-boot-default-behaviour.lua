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
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/abc.fnl")
local first_boot_sigil = (vim.fn.stdpath("cache") .. "/hotpot/first-boot.txt")
local lua_path = (vim.fn.stdpath("data") .. "/site/hotpot/start/lua/abc.lua")
write_file(fnl_path, "{:works true}")
local function start_nvim()
  local nvim = vim.fn.jobstart({"nvim", "--embed", "--headless"}, {rpc = true})
  vim.rpcrequest(nvim, "nvim_exec2", "lua vim.opt.runtimepath:prepend('/home/user/hotpot')", {output = true})
  local function _11_(this)
    return vim.fn.jobstop(this.channel)
  end
  local function _12_(this, src)
    return vim.rpcrequest(this.channel, "nvim_exec2", table.concat({"lua << EOF", src, "EOF"}, "\n"), {output = true})
  end
  return {channel = nvim, close = _11_, lua = _12_}
end
do
  local case_13_ = vim.uv.fs_stat(first_boot_sigil)
  if (case_13_ == nil) then
    OK(string.format(("no first-boot-sigil" or "")))
  else
    local __1_auto = case_13_
    FAIL(string.format(("no first-boot-sigil" or "")))
  end
end
local nvim = start_nvim()
nvim:lua("require'hotpot'")
nvim:close()
do
  local case_15_ = vim.uv.fs_stat(first_boot_sigil)
  if ((_G.type(case_15_) == "table") and (_G.type(case_15_.mtime) == "table")) then
    OK(string.format(("created first-boot-sigil" or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format(("created first-boot-sigil" or "")))
  end
end
do
  local case_17_ = read_file(lua_path)
  if (case_17_ == "return {works = true}") then
    OK(string.format(("created lua file in cache" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("created lua file in cache" or "")))
  end
end
return exit()