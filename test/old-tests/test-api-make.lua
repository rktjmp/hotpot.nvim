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
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local fnl_path = p("/fnl/a/b/c.fnl")
local lua_path = p("/lua/a/b/c.lua")
write_file(p("/fnl/a/b/c.fnl"), "(fn x [] nil)")
write_file(p("/fnl/a/macro.fnl"), "(fn x [] :macro)")
local _local_15_ = require("hotpot.api.make")
local build = _local_15_.build
build(vim.fn.stdpath("config"), {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}})
local function _16_(...)
  if (... == true) then
    local function _17_(...)
      if (... == true) then
        local function _18_(...)
          if (... == true) then
            return vim.loop.fs_unlink(lua_path)
          else
            local __43_ = ...
            return ...
          end
        end
        local function _21_(...)
          local case_20_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (case_20_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = case_20_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _18_(_21_(...))
      else
        local __43_ = ...
        return ...
      end
    end
    local function _25_(...)
      local case_24_ = read_file(lua_path)
      if (case_24_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = case_24_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _17_(_25_(...))
  else
    local __43_ = ...
    return ...
  end
end
local function _29_(...)
  local case_28_ = vim.loop.fs_access(lua_path, "R")
  if (case_28_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path))
    return true
  else
    local __1_auto = case_28_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
    return false
  end
end
_16_(_29_(...))
local function _31_(path0)
  if string.find(path0, "macro") then
    return false
  else
    return string.gsub(string.gsub(path0, "/fnl/", "/lua/"), "c.fnl$", "z.fnl")
  end
end
build(vim.fn.stdpath("config"), {{"fnl/**/*.fnl", _31_}})
local lua_path0 = (vim.fn.stdpath("config") .. "/lua/a/b/z.lua")
local function _33_(...)
  if (... == true) then
    local function _34_(...)
      if (... == true) then
        local function _35_(...)
          if (... == true) then
            return true
          else
            local __43_ = ...
            return ...
          end
        end
        local function _38_(...)
          local case_37_ = vim.loop.fs_access(p("/lua/a/macro.lua"), "R")
          if (case_37_ == false) then
            OK(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return true
          else
            local __1_auto = case_37_
            FAIL(string.format(("Did not compile macro" or ""), p("/lua/a/macro.lua")))
            return false
          end
        end
        return _35_(_38_(...))
      else
        local __43_ = ...
        return ...
      end
    end
    local function _42_(...)
      local case_41_ = read_file(lua_path0)
      if (case_41_ == "local function x()\\n  return nil\\nend\\nreturn x") then
        OK(string.format(("Outputs correct lua code" or "")))
        return true
      else
        local __1_auto = case_41_
        FAIL(string.format(("Outputs correct lua code" or "")))
        return false
      end
    end
    return _34_(_42_(...))
  else
    local __43_ = ...
    return ...
  end
end
local function _46_(...)
  local case_45_ = vim.loop.fs_access(lua_path0, "R")
  if (case_45_ == true) then
    OK(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return true
  else
    local __1_auto = case_45_
    FAIL(string.format(("Creates a lua file at %s" or ""), lua_path0))
    return false
  end
end
_33_(_46_(...))
return exit()