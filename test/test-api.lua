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
    local function _11_(this, cmd, ...)
      local case_12_ = vim.rpcrequest(channel, "nvim_exec2", string.format(cmd, ...), {output = true})
      if ((_G.type(case_12_) == "table") and (nil ~= case_12_.output)) then
        local output = case_12_.output
        return output
      else
        local _ = case_12_
        return nil
      end
    end
    local function _14_(this, src)
      local case_15_ = vim.rpcrequest(channel, "nvim_exec2", table.concat({"lua << EOF", src, "EOF"}, "\n"), {output = true})
      if ((_G.type(case_15_) == "table") and (nil ~= case_15_.output)) then
        local output = case_15_.output
        return output
      else
        local _ = case_15_
        return nil
      end
    end
    nvim = {channel = channel, close = _10_, cmd = _11_, lua = _14_}
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
local _local_18_ = require("test.utils")
local FAIL = _local_18_.FAIL
local NVIM_APPNAME = _local_18_.NVIM_APPNAME
local OK = _local_18_.OK
local create_file = _local_18_["create-file"]
local exit = _local_18_.exit
local path = _local_18_.path
local read_file = _local_18_["read-file"]
local start_nvim = _local_18_["start-nvim"]
local write_file = _local_18_["write-file"]
local nvim = start_nvim()
nvim:lua("require'hotpot'")
nvim:lua("api = require'hotpot.api'")
local output = nvim:lua("local ctx, err = api.context('doesnt-exist')\n                        vim.print(ctx,err)")
if (output == "nil\nUnable to load doesnt-exist/.hotpot.fnl: does not exist") then
  OK(string.format(("loading fake path returns nil, err" or "")))
else
  local __1_auto = output
  FAIL(string.format(("loading fake path returns nil, err" or "")))
end
nvim:lua("ctx = api.context(vim.fn.stdpath('config'))")
local output0 = nvim:lua("vim.print(ctx.locate('source'))")
local config_dir = vim.fn.stdpath("config")
do
  local case_20_, case_21_ = output0
  if (case_20_ == config_dir) then
    OK(string.format(("source is config dir" or "")))
  else
    local __1_auto = case_20_
    FAIL(string.format(("source is config dir" or "")))
  end
end
local output1 = nvim:lua("vim.print(ctx.locate('destination'))")
local data_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "hotpot", "opt", "hotpot-config-cache")
do
  local case_23_, case_24_ = output1
  if (case_23_ == data_dir) then
    OK(string.format(("destination is cache dir" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("destination is cache dir" or "")))
  end
end
local output2 = nvim:lua("local ok, val = ctx.compile('(.. :he :llo)')\n                        print(val)")
if (output2 == "return (\"he\" .. \"llo\")") then
  OK(string.format(("compiles code" or "")))
else
  local __1_auto = output2
  FAIL(string.format(("compiles code" or "")))
end
local output3 = nvim:lua("local ok, err = ctx.compile('.. :he :llo)')\n                        print(ok)")
if (output3 == "false") then
  OK(string.format(("handles compiling bad code" or "")))
else
  local __1_auto = output3
  FAIL(string.format(("handles compiling bad code" or "")))
end
local output4 = nvim:lua("local ok, err = ctx.compile('.. :he :llo)')\n                        print(err)")
do
  local case_28_ = ("" ~= output4)
  if (case_28_ == true) then
    OK(string.format(("handles compiling bad code" or "")))
  else
    local __1_auto = case_28_
    FAIL(string.format(("handles compiling bad code" or "")))
  end
end
local output5 = nvim:lua("local ok, val = ctx.eval('(.. :he :llo)')\n                        print(val)")
if (output5 == "hello") then
  OK(string.format(("evals code" or "")))
else
  local __1_auto = output5
  FAIL(string.format(("evals code" or "")))
end
local output6 = nvim:lua("local ok, a, b, c = ctx.eval('(values 1 2 3)')\n                        print(a,b,c)")
if (output6 == "1 2 3") then
  OK(string.format(("evals multi return" or "")))
else
  local __1_auto = output6
  FAIL(string.format(("evals multi return" or "")))
end
local output7 = nvim:lua("local ok, err = ctx.eval('.. :he :llo)')\n                        print(ok)")
if (output7 == "false") then
  OK(string.format(("handles evaling bad code" or "")))
else
  local __1_auto = output7
  FAIL(string.format(("handles evaling bad code" or "")))
end
local output8 = nvim:lua("local ok, err = ctx.eval('.. :he :llo)')\n                        print(ok)")
do
  local case_33_ = ("" ~= output8)
  if (case_33_ == true) then
    OK(string.format(("handles evaling bad code" or "")))
  else
    local __1_auto = case_33_
    FAIL(string.format(("handles evaling bad code" or "")))
  end
end
local fnl_path = create_file(path("config", "fnl/abc.fnl"), "{:works true}")
local lua_path = path("cache", "/lua/abc.lua")
local output9 = nvim:lua("local ok, val = ctx.sync()\n                        print(ok)")
do
  local case_35_ = read_file(lua_path)
  if (case_35_ == "return {works = true}") then
    OK(string.format(("can sync" or "")))
  else
    local __1_auto = case_35_
    FAIL(string.format(("can sync" or "")))
  end
end
local output10 = nvim:lua("local ctx, err = api.context()\n                        vim.print(ctx.eval('(+ 1 1)'))")
if (output10 == "2") then
  OK(string.format(("API context works" or "")))
else
  local __1_auto = output10
  FAIL(string.format(("API context works" or "")))
end
return nvim:close()