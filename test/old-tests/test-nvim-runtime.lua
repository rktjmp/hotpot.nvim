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
local _local_15_ = require("hotpot.api.cache")
local cache_prefix = _local_15_["cache-prefix"]
local function make_plugin(file)
  local config_dir = vim.fn.stdpath("config")
  local fnl_path = (config_dir .. "/plugin/" .. file .. ".fnl")
  local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-plugin/" .. file .. ".lua")
  write_file(fnl_path, "(set _G.exit (+ 1 (or _G.exit 100)))")
  return fnl_path, lua_path
end
local plugin_path_1, lua_path_1 = make_plugin("my_plugin_1")
local plugin_path_2, lua_path_2 = make_plugin("nested/deeply/my-plugin-2")
local plugin_path_3, lua_path_3 = make_plugin("init")
local plugin_path_4, lua_path_4 = make_plugin("init/init.fnl")
local lua_paths = {lua_path_1, lua_path_2, lua_path_3, lua_path_4}
do
  local case_16_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_16_ = vim.v.shell_error
  end
  if (case_16_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically" or "")))
  else
    local __1_auto = case_16_
    FAIL(string.format(("plugin/*.fnl executed automatically" or "")))
  end
end
do
  local case_18_
  do
    local exists_3f = true
    for _, path0 in ipairs(lua_paths) do
      exists_3f = (exists_3f and vim.loop.fs_access(path0, "R"))
    end
    case_18_ = exists_3f
  end
  if (case_18_ == true) then
    OK(string.format(("plugin lua files exists" or "")))
  else
    local __1_auto = case_18_
    FAIL(string.format(("plugin lua files exists" or "")))
  end
end
local stats_before
do
  local tbl_26_ = {}
  local i_27_ = 0
  for _, path0 in ipairs(lua_paths) do
    local val_28_ = vim.loop.fs_stat(path0)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  stats_before = tbl_26_
end
do
  local case_21_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_21_ = vim.v.shell_error
  end
  if (case_21_ == 104) then
    OK(string.format(("plugin/*.fnl executed automatically second time" or "")))
  else
    local __1_auto = case_21_
    FAIL(string.format(("plugin/*.fnl executed automatically second time" or "")))
  end
end
local stats_after
do
  local tbl_26_ = {}
  local i_27_ = 0
  for _, path0 in ipairs(lua_paths) do
    local val_28_ = vim.loop.fs_stat(path0)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  stats_after = tbl_26_
end
do
  local case_24_
  do
    local same_3f = true
    for i = 1, #lua_paths do
      local before = stats_before[i]
      local after = stats_after[i]
      same_3f = ((before.mtime.sec == after.mtime.sec) and (before.mtime.nsec == after.mtime.nsec))
    end
    case_24_ = same_3f
  end
  if (case_24_ == true) then
    OK(string.format(("plugin lua files were not recompiled" or "")))
  else
    local __1_auto = case_24_
    FAIL(string.format(("plugin lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(plugin_path_1)
do
  local case_26_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "vim.defer_fn(function() os.exit(_G.exit) end, 50)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_26_ = vim.v.shell_error
  end
  if (case_26_ == 103) then
    OK(string.format(("removed plugin/ file is removed from cache" or "")))
  else
    local __1_auto = case_26_
    FAIL(string.format(("removed plugin/ file is removed from cache" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local case_28_ = vim.loop.fs_access(lua_path_1, "R")
  if (case_28_ == false) then
    OK(string.format(("plugin lua file removed" or "")))
  else
    local __1_auto = case_28_
    FAIL(string.format(("plugin lua file removed" or "")))
  end
else
end
return exit()