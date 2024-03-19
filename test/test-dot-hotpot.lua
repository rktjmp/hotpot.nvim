package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_10_auto(ok_11_auto, ...)
      fh:close()
      if ok_11_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _3_()
      return fh:write(lines)
    end
    return close_handlers_10_auto(_G.xpcall(_3_, (package.loaded.fennel or debug).traceback))
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
  do end (vim.opt.runtimepath):prepend(vim.loop.cwd())
  require("hotpot")
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_1_ = require("test.utils")
local FAIL = _local_1_["FAIL"]
local NVIM_APPNAME = _local_1_["NVIM_APPNAME"]
local OK = _local_1_["OK"]
local exit = _local_1_["exit"]
local read_file = _local_1_["read-file"]
local write_file = _local_1_["write-file"]
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
  local _4_ = _G.loaded_dot
  if (_4_ == true) then
    OK(string.format((".hotpot.lua file loaded" or "")))
  else
    local __1_auto = _4_
    FAIL(string.format((".hotpot.lua file loaded" or "")))
  end
end
do
  local _6_ = read_file(lua_cache_path)
  if (_6_ == "do local _ = (1 + 1) end\\nreturn {works = true}") then
    OK(string.format((".hotpot.lua applies a preprocessor" or "")))
  else
    local __1_auto = _6_
    FAIL(string.format((".hotpot.lua applies a preprocessor" or "")))
  end
end
write_file(fnl_path_2, "{:works :also-true}")
write_file(dot_hotpot_path, "\nreturn {\n  build = true\n}")
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _8_ = read_file(lua_path)
  if (_8_ == "return {works = true}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = _8_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local _10_ = read_file(lua_path_2)
  if (_10_ == "return {works = \"also-true\"}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = _10_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local _12_ = vim.loop.fs_access(lua_cache_path, "R")
  if (_12_ == true) then
    OK(string.format(("previous cache lua still exists" or "")))
  else
    local __1_auto = _12_
    FAIL(string.format(("previous cache lua still exists" or "")))
  end
end
write_file(dot_hotpot_path, "\nreturn {\n  build = {{atomic = true},\n           {'fnl/**/*.fnl', true}},\n  clean = true,\n}")
write_file(junk_path, "return 1")
do
  local _14_ = vim.loop.fs_access(junk_path, "R")
  if (_14_ == true) then
    OK(string.format(("junk file exists" or "")))
  else
    local __1_auto = _14_
    FAIL(string.format(("junk file exists" or "")))
  end
end
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _16_ = vim.loop.fs_access(junk_path, "R")
  if (_16_ == false) then
    OK(string.format(("junk file is cleaned away" or "")))
  else
    local __1_auto = _16_
    FAIL(string.format(("junk file is cleaned away" or "")))
  end
end
return exit()