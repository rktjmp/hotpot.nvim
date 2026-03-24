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
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local fnl_path = p("/fnl/a/b/c.fnl")
local lua_path = p("/lua/a/b/c.lua")
write_file(p("/fnl/a/b/c.fnl"), "(fn x [] nil)")
write_file(p("/fnl/a/macro.fnl"), "(fn x [] :macro)")
local _local_11_ = require("hotpot.api.make")
local build = _local_11_.build
build(vim.fn.stdpath("config"), {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}})
local function _12_(...)
  if (... == true) then
    local function _13_(...)
      if (... == true) then
        local function _14_(...)
          if (... == true) then
            return vim.loop.fs_unlink(lua_path)
          else
            local __43_ = ...
            return ...
          end
        end
        local function _17_(...)
          local case_16_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (case_16_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = case_16_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _14_(_17_(...))
      else
        local __43_ = ...
        return ...
      end
    end
    local function _21_(...)
      local case_20_ = read_file(lua_path)
      if (case_20_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = case_20_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _13_(_21_(...))
  else
    local __43_ = ...
    return ...
  end
end
local function _25_(...)
  local case_24_ = vim.loop.fs_access(lua_path, "R")
  if (case_24_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path))
    return true
  else
    local __1_auto = case_24_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
    return false
  end
end
_12_(_25_(...))
local function _27_(path)
  if string.find(path, "macro") then
    return false
  else
    return string.gsub(string.gsub(path, "/fnl/", "/lua/"), "c.fnl$", "z.fnl")
  end
end
build(vim.fn.stdpath("config"), {{"fnl/**/*.fnl", _27_}})
local lua_path0 = (vim.fn.stdpath("config") .. "/lua/a/b/z.lua")
local function _29_(...)
  if (... == true) then
    local function _30_(...)
      if (... == true) then
        local function _31_(...)
          if (... == true) then
            return true
          else
            local __43_ = ...
            return ...
          end
        end
        local function _34_(...)
          local case_33_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (case_33_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = case_33_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _31_(_34_(...))
      else
        local __43_ = ...
        return ...
      end
    end
    local function _38_(...)
      local case_37_ = read_file(lua_path0)
      if (case_37_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = case_37_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _30_(_38_(...))
  else
    local __43_ = ...
    return ...
  end
end
local function _42_(...)
  local case_41_ = vim.loop.fs_access(lua_path0, "R")
  if (case_41_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return true
  else
    local __1_auto = case_41_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return false
  end
end
_29_(_42_(...))
return exit()