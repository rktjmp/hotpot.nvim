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
local config_path = create_file(path("config", ".hotpot.fnl"), "{:schema :hotpot/2 :target :cache}")
local fnl_path = create_file(path("config", "fnl/abc.fnl"), "{:works true}")
local lua_path = path("cache", "/lua/abc.lua")
local vendor_path = create_file(path("config", "lua/vendor/lib.lua"), "return 'vendor lib'")
local nvim = start_nvim()
nvim:lua("require'hotpot'")
nvim:close()
do
  local case_15_ = read_file(lua_path)
  if (case_15_ == "return {works = true}") then
    OK(string.format(("first boot created lua file in cache" or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format(("first boot created lua file in cache" or "")))
  end
end
do
  local case_17_ = read_file(vendor_path)
  if (case_17_ == "return 'vendor lib'") then
    OK(string.format(("first boot left vendor file untouched" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("first boot left vendor file untouched" or "")))
  end
end
local fnl_path2 = create_file(path("config", "fnl/xyz.fnl"), "{:works :also}")
local lua_path2 = path("cache", "/lua/xyz.lua")
local nvim0 = start_nvim()
nvim0:lua("require'hotpot'")
do
  local case_19_ = read_file(lua_path)
  if (case_19_ == "return {works = true}") then
    OK(string.format(("second boot kept lua file in cache" or "")))
  else
    local __1_auto = case_19_
    FAIL(string.format(("second boot kept lua file in cache" or "")))
  end
end
do
  local case_21_ = vim.uv.fs_stat(lua_path2)
  if (case_21_ == nil) then
    OK(string.format(("second boot did not create second file in cache" or "")))
  else
    local __1_auto = case_21_
    FAIL(string.format(("second boot did not create second file in cache" or "")))
  end
end
do
  local case_23_ = read_file(vendor_path)
  if (case_23_ == "return 'vendor lib'") then
    OK(string.format(("second boot left vendor file untouched" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("second boot left vendor file untouched" or "")))
  end
end
nvim0:cmd(("edit " .. fnl_path2))
nvim0:cmd("write")
do
  local case_25_ = read_file(lua_path)
  if (case_25_ == "return {works = true}") then
    OK(string.format(("saving file kept lua file in cache" or "")))
  else
    local __1_auto = case_25_
    FAIL(string.format(("saving file kept lua file in cache" or "")))
  end
end
do
  local case_27_ = read_file(lua_path2)
  if (case_27_ == "return {works = \"also\"}") then
    OK(string.format(("saving file created lua file 2 in cache" or "")))
  else
    local __1_auto = case_27_
    FAIL(string.format(("saving file created lua file 2 in cache" or "")))
  end
end
do
  local case_29_ = read_file(vendor_path)
  if (case_29_ == "return 'vendor lib'") then
    OK(string.format(("saving file left vendor file untouched" or "")))
  else
    local __1_auto = case_29_
    FAIL(string.format(("saving file left vendor file untouched" or "")))
  end
end
vim.fn.delete(fnl_path)
nvim0:cmd("write")
do
  local case_31_ = vim.uv.fs_stat(lua_path)
  if (case_31_ == nil) then
    OK(string.format(("saving file removed orphaned file" or "")))
  else
    local __1_auto = case_31_
    FAIL(string.format(("saving file removed orphaned file" or "")))
  end
end
do
  local case_33_ = read_file(lua_path2)
  if (case_33_ == "return {works = \"also\"}") then
    OK(string.format(("saving file retained lua file 2 in cache" or "")))
  else
    local __1_auto = case_33_
    FAIL(string.format(("saving file retained lua file 2 in cache" or "")))
  end
end
do
  local case_35_ = read_file(vendor_path)
  if (case_35_ == "return 'vendor lib'") then
    OK(string.format(("saving file left vendor file untouched" or "")))
  else
    local __1_auto = case_35_
    FAIL(string.format(("saving file left vendor file untouched" or "")))
  end
end
nvim0:close()
return exit()