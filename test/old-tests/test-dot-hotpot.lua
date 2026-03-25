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
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/abc.fnl")
local fnl_path_2 = (vim.fn.stdpath("config") .. "/fnl/def.fnl")
local lua_path = (vim.fn.stdpath("config") .. "/lua/abc.lua")
local lua_path_2 = (vim.fn.stdpath("config") .. "/lua/def.lua")
local junk_path = (vim.fn.stdpath("config") .. "/lua/junk.lua")
local lua_cache_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/abc.lua")
local dot_hotpot_path = (vim.fn.stdpath("config") .. "/.hotpot.lua")
write_file(dot_hotpot_path, "\n_G.loaded_dot = true\nreturn {\n  compiler = {\n    preprocessor = function(src)\n      return \"(+ 1 1)\\n\" .. src\n    end\n  }\n}")
write_file(fnl_path, "{:works true}")
require("abc")
do
  local case_15_ = _G.loaded_dot
  if (case_15_ == true) then
    OK(string.format((".hotpot.lua file loaded" or "")))
  else
    local __1_auto = case_15_
    FAIL(string.format((".hotpot.lua file loaded" or "")))
  end
end
do
  local case_17_ = read_file(lua_cache_path)
  if (case_17_ == "do local _ = (1 + 1) end\\nreturn {works = true}") then
    OK(string.format((".hotpot.lua applies a preprocessor" or "")))
  else
    local __1_auto = case_17_
    FAIL(string.format((".hotpot.lua applies a preprocessor" or "")))
  end
end
write_file(fnl_path_2, "{:works :also-true}")
write_file(dot_hotpot_path, "\nreturn {\n  build = true\n}")
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local case_19_ = read_file(lua_path)
  if (case_19_ == "return {works = true}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = case_19_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local case_21_ = read_file(lua_path_2)
  if (case_21_ == "return {works = \"also-true\"}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = case_21_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local case_23_ = vim.loop.fs_access(lua_cache_path, "R")
  if (case_23_ == true) then
    OK(string.format(("previous cache lua still exists" or "")))
  else
    local __1_auto = case_23_
    FAIL(string.format(("previous cache lua still exists" or "")))
  end
end
write_file(dot_hotpot_path, "\nreturn {\n  build = {{atomic = true},\n           {'fnl/**/*.fnl', true}},\n  clean = true,\n}")
write_file(junk_path, "return 1")
do
  local case_25_ = vim.loop.fs_access(junk_path, "R")
  if (case_25_ == true) then
    OK(string.format(("junk file exists" or "")))
  else
    local __1_auto = case_25_
    FAIL(string.format(("junk file exists" or "")))
  end
end
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local case_27_ = vim.loop.fs_access(junk_path, "R")
  if (case_27_ == false) then
    OK(string.format(("junk file is cleaned away" or "")))
  else
    local __1_auto = case_27_
    FAIL(string.format(("junk file is cleaned away" or "")))
  end
end
return exit()