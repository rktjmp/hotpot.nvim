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
local function test_path(modname, path)
  local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. path .. ".fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path .. ".lua")
  write_file(fnl_path, "{:works true}")
  local val
  local function _11_(...)
    local _12_ = ...
    if (_12_ == true) then
      local function _13_(...)
        local _14_ = ...
        if (_14_ == true) then
          local function _15_(...)
            local _16_ = ...
            if (_16_ == true) then
              return true
            else
              local __44_ = _16_
              return ...
            end
          end
          local function _19_(...)
            local _18_ = read_file(lua_path)
            if (_18_ == "return {works = true}") then
              OK(string.format(("Outputs correct lua code" or "")))
              return true
            else
              local __1_auto = _18_
              FAIL(string.format(("Outputs correct lua code" or "")))
              return false
            end
          end
          return _15_(_19_(...))
        else
          local __44_ = _14_
          return ...
        end
      end
      local function _23_(...)
        local _22_ = vim.loop.fs_access(lua_path, "R")
        if (_22_ == true) then
          OK(string.format(("Creates a lua file at %s" or ""), lua_path))
          return true
        else
          local __1_auto = _22_
          FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
          return false
        end
      end
      return _13_(_23_(...))
    else
      local __44_ = _12_
      return ...
    end
  end
  local function _28_()
    local _26_, _27_ = pcall(require, modname)
    if ((_26_ == true) and ((_G.type(_27_) == "table") and (_27_.works == true))) then
      OK(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return true
    else
      local __1_auto = _26_
      FAIL(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return false
    end
  end
  val = _11_(_28_())
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
  local path = "issue-131"
  local modname = "issue-131"
  local fnl_path_1 = (vim.fn.stdpath("config") .. "/fnl/" .. path .. ".fnl")
  local fnl_path_2 = (vim.fn.stdpath("config") .. "/fnl/" .. path .. "-broken.fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path .. ".lua")
  local test_code = table.concat({"require('issue-131')", string.format("vim.loop.fs_unlink(%q)", fnl_path_1), string.format("vim.loop.fs_rename(%q, %q)", fnl_path_2, fnl_path_1), "package.loaded['issue-131'] = nil", "if not pcall(require, 'issue-131') then os.exit(1) else os.exit(255) end"}, "\n")
  write_file(fnl_path_1, "{:works true}")
  write_file(fnl_path_2, "{:works true")
  local _30_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. test_code)))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _30_ = vim.v.shell_error
  end
  if (_30_ == 1) then
    OK(string.format((nil or "")))
  else
    local __1_auto = _30_
    FAIL(string.format((nil or "")))
  end
end
return exit()