package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_12_auto(ok_13_auto, ...)
      fh:close()
      if ok_13_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _2_()
      return fh:write(lines)
    end
    return close_handlers_12_auto(_G.xpcall(_2_, (package.loaded.fennel or _G.debug or {}).traceback))
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
local _local_3_ = require("test.utils")
local FAIL = _local_3_["FAIL"]
local NVIM_APPNAME = _local_3_["NVIM_APPNAME"]
local OK = _local_3_["OK"]
local exit = _local_3_["exit"]
local read_file = _local_3_["read-file"]
local write_file = _local_3_["write-file"]
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local fnl_path = p("/fnl/a/b/c.fnl")
local lua_path = p("/lua/a/b/c.lua")
write_file(p("/fnl/a/b/c.fnl"), "(fn x [] nil)")
write_file(p("/fnl/a/macro.fnl"), "(fn x [] :macro)")
local _local_4_ = require("hotpot.api.make")
local build = _local_4_["build"]
build(vim.fn.stdpath("config"), {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}})
local function _5_(...)
  local _6_ = ...
  if (_6_ == true) then
    local function _7_(...)
      local _8_ = ...
      if (_8_ == true) then
        local function _9_(...)
          local _10_ = ...
          if (_10_ == true) then
            return vim.loop.fs_unlink(lua_path)
          else
            local __87_auto = _10_
            return ...
          end
        end
        local function _13_(...)
          local _12_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (_12_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = _12_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _9_(_13_(...))
      else
        local __87_auto = _8_
        return ...
      end
    end
    local function _17_(...)
      local _16_ = read_file(lua_path)
      if (_16_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = _16_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _7_(_17_(...))
  else
    local __87_auto = _6_
    return ...
  end
end
local function _21_(...)
  local _20_ = vim.loop.fs_access(lua_path, "R")
  if (_20_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path))
    return true
  else
    local __1_auto = _20_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
    return false
  end
end
_5_(_21_(...))
local function _23_(path)
  if string.find(path, "macro") then
    return false
  else
    return string.gsub(string.gsub(path, "/fnl/", "/lua/"), "c.fnl$", "z.fnl")
  end
end
build(vim.fn.stdpath("config"), {{"fnl/**/*.fnl", _23_}})
local lua_path0 = (vim.fn.stdpath("config") .. "/lua/a/b/z.lua")
local function _25_(...)
  local _26_ = ...
  if (_26_ == true) then
    local function _27_(...)
      local _28_ = ...
      if (_28_ == true) then
        local function _29_(...)
          local _30_ = ...
          if (_30_ == true) then
            return true
          else
            local __87_auto = _30_
            return ...
          end
        end
        local function _33_(...)
          local _32_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (_32_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = _32_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _29_(_33_(...))
      else
        local __87_auto = _28_
        return ...
      end
    end
    local function _37_(...)
      local _36_ = read_file(lua_path0)
      if (_36_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = _36_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _27_(_37_(...))
  else
    local __87_auto = _26_
    return ...
  end
end
local function _41_(...)
  local _40_ = vim.loop.fs_access(lua_path0, "R")
  if (_40_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return true
  else
    local __1_auto = _40_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return false
  end
end
_25_(_41_(...))
return exit()