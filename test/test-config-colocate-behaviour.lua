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
local config_path = create_file(path("config", ".hotpot.fnl"), "{:schema :hotpot/2 :target :colocate}")
local fnl_path = create_file(path("config", "fnl/abc.fnl"), "{:works true}")
local lua_path = path("config", "/lua/abc.lua")
local nvim = start_nvim()
nvim:lua("require'hotpot'")
nvim:close()
do
  local case_19_ = read_file(lua_path)
  if (case_19_ == "return {works = true}") then
    OK(string.format(("created lua file in colocate" or "")))
  else
    local __1_auto = case_19_
    FAIL(string.format(("created lua file in colocate" or "")))
  end
end
return exit()