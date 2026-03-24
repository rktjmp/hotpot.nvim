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
local function test_path(modname, path0)
  local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. path0 .. ".fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path0 .. ".lua")
  write_file(fnl_path, "{:works true}")
  local val
  local function _14_(...)
    if (... == true) then
      local function _15_(...)
        if (... == true) then
          local function _16_(...)
            if (... == true) then
              return true
            else
              local __43_ = ...
              return ...
            end
          end
          local function _19_(...)
            local case_18_ = read_file(lua_path)
            if (case_18_ == "return {works = true}") then
              OK(string.format(("Outputs correct lua code" or "")))
              return true
            else
              local __1_auto = case_18_
              FAIL(string.format(("Outputs correct lua code" or "")))
              return false
            end
          end
          return _16_(_19_(...))
        else
          local __43_ = ...
          return ...
        end
      end
      local function _23_(...)
        local case_22_ = vim.loop.fs_access(lua_path, "R")
        if (case_22_ == true) then
          OK(string.format(("Creates a lua file at %s" or ""), lua_path))
          return true
        else
          local __1_auto = case_22_
          FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
          return false
        end
      end
      return _15_(_23_(...))
    else
      local __43_ = ...
      return ...
    end
  end
  local function _28_()
    local case_26_, case_27_ = pcall(require, modname)
    if ((case_26_ == true) and ((_G.type(case_27_) == "table") and (case_27_.works == true))) then
      OK(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return true
    else
      local __1_auto = case_26_
      FAIL(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return false
    end
  end
  val = _14_(_28_())
  vim.fn.delete(fnl_path)
  vim.fn.delete(lua_path)
  return val
end
test_path("abc", "abc")
test_path("def", "def/init")
test_path("def.init", "def/init")
test_path("xyz.init", "xyz/init")
test_path("abc.xyz.p-q-r", "abc/xyz/p-q-r")
test_path("xc-init", "xc-init")
test_path("init", "init/init")
package.loaded.init = nil
test_path("init", "init")
test_path("fnl", "fnl/init")
test_path("some.code.fnl", "some/code/fnl/init")
test_path("some.code.fnl.init", "some/code/fnl/init")
do
  local path0 = "issue-131"
  local modname = "issue-131"
  local fnl_path_1 = (vim.fn.stdpath("config") .. "/fnl/" .. path0 .. ".fnl")
  local fnl_path_2 = (vim.fn.stdpath("config") .. "/fnl/" .. path0 .. "-broken.fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path0 .. ".lua")
  local test_code = table.concat({"require('issue-131')", string.format("vim.loop.fs_unlink(%q)", fnl_path_1), string.format("vim.loop.fs_rename(%q, %q)", fnl_path_2, fnl_path_1), "package.loaded['issue-131'] = nil", "if not pcall(require, 'issue-131') then os.exit(1) else os.exit(255) end"}, "\n")
  write_file(fnl_path_1, "{:works true}")
  write_file(fnl_path_2, "{:works true")
  local case_30_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. test_code)))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_30_ = vim.v.shell_error
  end
  if (case_30_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = case_30_
    FAIL(string.format((nil or "")))
  end
end
return exit()