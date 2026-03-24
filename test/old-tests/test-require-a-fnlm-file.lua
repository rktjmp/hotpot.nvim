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
local function in_path(path0)
  return (vim.fn.stdpath("config") .. "/fnl/" .. path0)
end
write_file(in_path("code.fnl"), "(import-macros {: sum} :my-macro) (sum 1 2)")
write_file(in_path("my-macro.fnlm"), "{:sum (fn [a b] `(+ ,a ,b))}")
do
  local case_14_, case_15_ = pcall(require, "code")
  if ((case_14_ == true) and (case_15_ == 3)) then
    OK(string.format(("can require fnlm macro file" or "")))
  else
    local __1_auto = case_14_
    FAIL(string.format(("can require fnlm macro file" or "")))
  end
end
write_file(in_path("prelude/init.fnl"), "(import-macros {: sum} :my-macro) (sum 5 5)")
write_file(in_path("prelude/init.fnlm"), "{:sum (fn [a b] `(+ ,a ,b))}")
do
  local case_17_, case_18_ = pcall(require, "prelude")
  if ((case_17_ == true) and (case_18_ == 10)) then
    OK(string.format(("can require mod/init.fnlm when mod/init.fnl exists" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("can require mod/init.fnlm when mod/init.fnl exists" or "")))
  end
end
return exit()