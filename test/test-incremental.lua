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
      return vim.rpcrequest(channel, "nvim_exec2", string.format(cmd, ...), {output = true})
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
local config_path = create_file(path("config", ".hotpot.fnl"), "{:schema :hotpot/2\n                                  :target :colocate\n                                  :ignore [:fnl/ignore.fnlm]}")
local abc_fnl_path = create_file(path("config", "fnl/abc.fnl"), "{:works true}")
local abc_lua_path = path("config", "lua/abc.lua")
local xyz_fnl_path = create_file(path("config", "fnl/xyz.fnl"), "{:works true}")
local xyz_lua_path = path("config", "lua/xyz.lua")
local fnlm_path = create_file(path("config", "fnl/macro.fnlm"), "{}")
local ignore_fnlm_path = create_file(path("config", "fnl/ignore.fnlm"), "{}")
local function a_newer_than_b_3f(mtime1, mtime2)
  local s1 = mtime1.sec
  local n1 = mtime1.nsec
  local s2 = mtime2.sec
  local n2 = mtime2.nsec
  return (((s2 == s1) and (n2 < n1)) or (s2 < s1))
end
local function a_equal_b_3f(mtime1, mtime2)
  local s1 = mtime1.sec
  local n1 = mtime1.nsec
  local s2 = mtime2.sec
  local n2 = mtime2.nsec
  return ((s1 == s2) and (n1 == n2))
end
local nvim = start_nvim()
nvim:lua("require'hotpot'")
do
  local case_15_ = vim.uv.fs_stat(abc_lua_path)
  if ((_G.type(case_15_) == "table") and (_G.type(case_15_.mtime) == "table")) then
    OK(string.format(("created abc-lua" or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format(("created abc-lua" or "")))
  end
end
do
  local case_17_ = vim.uv.fs_stat(xyz_lua_path)
  if ((_G.type(case_17_) == "table") and (_G.type(case_17_.mtime) == "table")) then
    OK(string.format(("created xyz-lua" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("created xyz-lua" or "")))
  end
end
local _local_19_ = vim.uv.fs_stat(abc_lua_path)
local abc_time1 = _local_19_.mtime
local _local_20_ = vim.uv.fs_stat(xyz_lua_path)
local xyz_time1 = _local_20_.mtime
vim.uv.sleep(40)
nvim:cmd(("edit " .. abc_fnl_path))
nvim:cmd("write")
local _local_21_ = vim.uv.fs_stat(abc_lua_path)
local abc_time2 = _local_21_.mtime
local _local_22_ = vim.uv.fs_stat(xyz_lua_path)
local xyz_time2 = _local_22_.mtime
do
  local case_23_ = a_newer_than_b_3f(abc_time2, abc_time1)
  if (case_23_ == true) then
    OK(string.format(("rebuilt abc-fnl because it was modified" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("rebuilt abc-fnl because it was modified" or "")))
  end
end
do
  local case_25_ = a_equal_b_3f(xyz_time1, xyz_time2)
  if (case_25_ == true) then
    OK(string.format(("did not rebuild xyz-fnl" or "")))
  else
    local __1_auto = case_25_
    FAIL(string.format(("did not rebuild xyz-fnl" or "")))
  end
end
vim.uv.sleep(40)
nvim:cmd(("edit " .. fnlm_path))
nvim:cmd("write")
local _local_27_ = vim.uv.fs_stat(abc_lua_path)
local abc_time3 = _local_27_.mtime
local _local_28_ = vim.uv.fs_stat(xyz_lua_path)
local xyz_time3 = _local_28_.mtime
do
  local case_29_ = a_newer_than_b_3f(abc_time2, abc_time1)
  if (case_29_ == true) then
    OK(string.format(("rebuilt abc-fnl because of fnlm modified" or "")))
  else
    local __1_auto = case_29_
    FAIL(string.format(("rebuilt abc-fnl because of fnlm modified" or "")))
  end
end
do
  local case_31_ = a_newer_than_b_3f(xyz_time3, xyz_time1)
  if (case_31_ == true) then
    OK(string.format(("rebuilt xyz-fnl because of fnlm modified" or "")))
  else
    local __1_auto = case_31_
    FAIL(string.format(("rebuilt xyz-fnl because of fnlm modified" or "")))
  end
end
vim.uv.sleep(40)
nvim:cmd(("edit " .. ignore_fnlm_path))
nvim:cmd("write")
local _local_33_ = vim.uv.fs_stat(abc_lua_path)
local abc_time4 = _local_33_.mtime
local _local_34_ = vim.uv.fs_stat(xyz_lua_path)
local xyz_time4 = _local_34_.mtime
do
  local case_35_ = a_equal_b_3f(abc_time3, abc_time4)
  if (case_35_ == true) then
    OK(string.format(("did not rebuild abc-fnl when ignored fnlm changed" or "")))
  else
    local __1_auto = case_35_
    FAIL(string.format(("did not rebuild abc-fnl when ignored fnlm changed" or "")))
  end
end
do
  local case_37_ = a_equal_b_3f(xyz_time3, xyz_time4)
  if (case_37_ == true) then
    OK(string.format(("did not rebuild xyz-fnl when ignored fnlm changed" or "")))
  else
    local __1_auto = case_37_
    FAIL(string.format(("did not rebuild xyz-fnl when ignored fnlm changed" or "")))
  end
end
nvim:close()
return exit()