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
local function test_path(modname, path)
  local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. path .. ".fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path .. ".lua")
  write_file(fnl_path, "{:works true}")
  local val
  local function _4_(...)
    local _5_ = ...
    if (_5_ == true) then
      local function _6_(...)
        local _7_ = ...
        if (_7_ == true) then
          local function _8_(...)
            local _9_ = ...
            if (_9_ == true) then
              return true
            else
              local __85_auto = _9_
              return ...
            end
          end
          local function _12_(...)
            local _11_ = read_file(lua_path)
            if (_11_ == "return {works = true}") then
              OK(string.format(("Outputs correct lua code" or "")))
              return true
            else
              local __1_auto = _11_
              FAIL(string.format(("Outputs correct lua code" or "")))
              return false
            end
          end
          return _8_(_12_(...))
        else
          local __85_auto = _7_
          return ...
        end
      end
      local function _16_(...)
        local _15_ = vim.loop.fs_access(lua_path, "R")
        if (_15_ == true) then
          OK(string.format(("Creates a lua file at %s" or ""), lua_path))
          return true
        else
          local __1_auto = _15_
          FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
          return false
        end
      end
      return _6_(_16_(...))
    else
      local __85_auto = _5_
      return ...
    end
  end
  local function _21_()
    local _19_, _20_ = pcall(require, modname)
    if ((_19_ == true) and ((_G.type(_20_) == "table") and (_20_.works == true))) then
      OK(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return true
    else
      local __1_auto = _19_
      FAIL(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return false
    end
  end
  val = _4_(_21_())
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
  local _23_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. test_code)))
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
return exit()