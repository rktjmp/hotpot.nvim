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
local config_path = create_file(path("config", ".hotpot.fnl"), "{:schema :hotpot/2\n                                  :target :colocate\n                                  :ignore [:fnl/ignore.fnlm]}")
local abc_fnl_path = create_file(path("config", "fnl/abc.fnl"), "{:works true}")
local abc_lua_path = path("config", "lua/abc.lua")
local xyz_fnl_path = create_file(path("config", "fnl/xyz.fnl"), "{:works true}")
local xyz_lua_path = path("config", "lua/xyz.lua")
local fnlm_path = create_file(path("config", "fnl/macro.fnlm"), "{}")
local ignore_fnlm_path = create_file(path("config", "fnl/ignore.fnlm"), "{}")
local nvim = start_nvim()
nvim:lua("require'hotpot'")
do
  local case_14_ = vim.uv.fs_stat(abc_lua_path)
  if ((_G.type(case_14_) == "table") and (_G.type(case_14_.mtime) == "table")) then
    OK(string.format(("created abc-lua" or "")))
  else
    local __1_auto = case_14_
    FAIL(string.format(("created abc-lua" or "")))
  end
end
do
  local case_16_ = vim.uv.fs_stat(xyz_lua_path)
  if ((_G.type(case_16_) == "table") and (_G.type(case_16_.mtime) == "table")) then
    OK(string.format(("created xyz-lua" or "")))
  else
    local __1_auto = case_16_
    FAIL(string.format(("created xyz-lua" or "")))
  end
end
local _local_18_ = vim.uv.fs_stat(abc_lua_path)
local _local_19_ = _local_18_.mtime
local abc_time1 = _local_19_.sec
local abc_time1_n = _local_19_.nsec
local _local_20_ = vim.uv.fs_stat(xyz_lua_path)
local _local_21_ = _local_20_.mtime
local xyz_time1 = _local_21_.sec
local xyz_time1_n = _local_21_.nsec
vim.uv.sleep(1100)
nvim:cmd(("edit " .. abc_fnl_path))
nvim:cmd("write")
local _local_22_ = vim.uv.fs_stat(abc_lua_path)
local _local_23_ = _local_22_.mtime
local abc_time2 = _local_23_.sec
local abc_time2_n = _local_23_.nsec
local _local_24_ = vim.uv.fs_stat(xyz_lua_path)
local _local_25_ = _local_24_.mtime
local xyz_time2 = _local_25_.sec
local xyz_time2_n = _local_25_.nsec
do
  local case_26_ = (abc_time1 < abc_time2)
  if (case_26_ == true) then
    OK(string.format(("rebuilt abc-fnl because it was modified" or "")))
  else
    local __1_auto = case_26_
    FAIL(string.format(("rebuilt abc-fnl because it was modified" or "")))
  end
end
do
  local case_28_ = (xyz_time1 == xyz_time2)
  if (case_28_ == true) then
    OK(string.format(("did not rebuild xyz-fnl" or "")))
  else
    local __1_auto = case_28_
    FAIL(string.format(("did not rebuild xyz-fnl" or "")))
  end
end
vim.uv.sleep(1100)
nvim:cmd(("edit " .. fnlm_path))
nvim:cmd("write")
local _local_30_ = vim.uv.fs_stat(abc_lua_path)
local _local_31_ = _local_30_.mtime
local abc_time3 = _local_31_.sec
local abc_time3_n = _local_31_.nsec
local _local_32_ = vim.uv.fs_stat(xyz_lua_path)
local _local_33_ = _local_32_.mtime
local xyz_time3 = _local_33_.sec
local xyz_time3_n = _local_33_.nsec
do
  local case_34_ = (abc_time1 < abc_time2)
  if (case_34_ == true) then
    OK(string.format(("rebuilt abc-fnl because of fnlm modified" or "")))
  else
    local __1_auto = case_34_
    FAIL(string.format(("rebuilt abc-fnl because of fnlm modified" or "")))
  end
end
do
  local case_36_ = (xyz_time1 < xyz_time3)
  if (case_36_ == true) then
    OK(string.format(("rebuilt xyz-fnl because of fnlm modified" or "")))
  else
    local __1_auto = case_36_
    FAIL(string.format(("rebuilt xyz-fnl because of fnlm modified" or "")))
  end
end
vim.uv.sleep(1100)
nvim:cmd(("edit " .. ignore_fnlm_path))
nvim:cmd("write")
local _local_38_ = vim.uv.fs_stat(abc_lua_path)
local _local_39_ = _local_38_.mtime
local abc_time4 = _local_39_.sec
local abc_time4_n = _local_39_.nsec
local _local_40_ = vim.uv.fs_stat(xyz_lua_path)
local _local_41_ = _local_40_.mtime
local xyz_time4 = _local_41_.sec
local xyz_time4_n = _local_41_.nsec
do
  local case_42_ = (abc_time3 == abc_time4)
  if (case_42_ == true) then
    OK(string.format(("did not rebuild abc-fnl when ignored fnlm changed" or "")))
  else
    local __1_auto = case_42_
    FAIL(string.format(("did not rebuild abc-fnl when ignored fnlm changed" or "")))
  end
end
do
  local case_44_ = (xyz_time3 == xyz_time4)
  if (case_44_ == true) then
    OK(string.format(("did not rebuild xyz-fnl when ignored fnlm changed" or "")))
  else
    local __1_auto = case_44_
    FAIL(string.format(("did not rebuild xyz-fnl when ignored fnlm changed" or "")))
  end
end
nvim:close()
return exit()