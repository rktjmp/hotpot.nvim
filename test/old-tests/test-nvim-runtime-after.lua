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
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local _local_14_ = require("hotpot.api.cache")
local cache_prefix = _local_14_["cache-prefix"]
local plugin_path = p("/plugin/my_plugin.fnl")
local after_path = p("/after/plugin/not_my_plugin.fnl")
local lua_path = (cache_prefix() .. "/hotpot-runtime-" .. NVIM_APPNAME .. "/lua/hotpot-runtime-after/plugin/not_my_plugin.lua")
write_file(plugin_path, "(set _G.plugin_time (vim.loop.hrtime))")
write_file(after_path, "(set _G.after_time (vim.loop.hrtime))")
do
  local case_15_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_15_ = vim.v.shell_error
  end
  if (case_15_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
do
  local case_17_ = vim.loop.fs_access(lua_path, "R")
  if (case_17_ == true) then
    OK(string.format(("lua files exists" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format(("lua files exists" or "")))
  end
end
local stats_a = vim.loop.fs_stat(lua_path)
do
  local case_19_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.plugin_time < _G.after_time then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_19_ = vim.v.shell_error
  end
  if (case_19_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = case_19_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
local stats_b = vim.loop.fs_stat(lua_path)
do
  local case_21_ = ((stats_a.mtime.sec == stats_b.mtime.sec) and (stats_a.mtime.nsec == stats_b.mtime.nsec))
  if (case_21_ == true) then
    OK(string.format(("lua files were not recompiled" or "")))
  else
    local __1_auto = case_21_
    FAIL(string.format(("lua files were not recompiled" or "")))
  end
end
vim.loop.fs_unlink(after_path)
do
  local case_23_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "_G.plugin_time = 1000\n                        _G.after_time = 1\n                        vim.defer_fn(function()\n                          if _G.after_time == 1 and _G.plugin_time ~= 1000 then\n                            os.exit(100)\n                          else\n                            os.exit(1)\n                          end\n                        end, 500)")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    case_23_ = vim.v.shell_error
  end
  if (case_23_ == 100) then
    OK(string.format(("after/**/*.fnl executed automatically" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("after/**/*.fnl executed automatically" or "")))
  end
end
if (1 ~= vim.fn.has("win32")) then
  local case_25_ = vim.loop.fs_access(lua_path, "R")
  if (case_25_ == false) then
    OK(string.format(("after plugin lua file removed" or "")))
  else
    local __1_auto = case_25_
    FAIL(string.format(("after plugin lua file removed" or "")))
  end
else
end
return exit()