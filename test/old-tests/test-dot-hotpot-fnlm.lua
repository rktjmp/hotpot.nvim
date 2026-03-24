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
    return nvim
  end
  local function create_file(path, content)
    write_file(path, content)
    return path
  end
  local function path(_in, ...)
    return vim.fs.joinpath(vim.fn.stdpath(_in), ...)
  end
  return {["write-file"] = write_file, ["read-file"] = read_file, ["create-file"] = create_file, path = path, OK = OK, FAIL = FAIL, exit = exit, ["start-nvim"] = start_nvim, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_13_ = require("test.utils")
local FAIL = _local_13_.FAIL
local NVIM_APPNAME = _local_13_.NVIM_APPNAME
local OK = _local_13_.OK
local create_file = _local_13_["create-file"]
local exit = _local_13_.exit
local path = _local_13_.path
local read_file = _local_13_["read-file"]
local start_nvim = _local_13_["start-nvim"]
local write_file = _local_13_["write-file"]
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/abc.fnl")
local fnlm_path = (vim.fn.stdpath("config") .. "/fnl/xyz.fnlm")
local dot_hotpot_path = (vim.fn.stdpath("config") .. "/.hotpot.lua")
write_file(dot_hotpot_path, "return { build = true }")
write_file(fnlm_path, "{:works (fn [v] `{:works ,v})}")
write_file(fnl_path, "(import-macros {: works} :xyz) (works true)")
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local case_14_ = vim.loop.fs_access((vim.fn.stdpath("config") .. "/lua/abc.lua"), "R")
  if (case_14_ == true) then
    OK(string.format(("built module file" or "")))
  else
    local __1_auto = case_14_
    FAIL(string.format(("built module file" or "")))
  end
end
do
  local case_16_ = vim.loop.fs_access((vim.fn.stdpath("config") .. "xyz.lua"), "R")
  if (case_16_ == false) then
    OK(string.format(("did not build macro file" or "")))
  else
    local __1_auto = case_16_
    FAIL(string.format(("did not build macro file" or "")))
  end
end
return exit()