package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_12_(ok_13_, ...)
      fh:close()
      if ok_13_ then
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
    return close_handlers_12_(_G.xpcall(_2_, or_8_.traceback))
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
  vim.opt.runtimepath:prepend(vim.loop.cwd())
  require("hotpot")
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_10_ = require("test.utils")
local FAIL = _local_10_["FAIL"]
local NVIM_APPNAME = _local_10_["NVIM_APPNAME"]
local OK = _local_10_["OK"]
local exit = _local_10_["exit"]
local read_file = _local_10_["read-file"]
local write_file = _local_10_["write-file"]
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
  local _11_ = _G.loaded_dot
  if (_11_ == true) then
    OK(string.format((".hotpot.lua file loaded" or "")))
  else
    local __1_auto = _11_
    FAIL(string.format((".hotpot.lua file loaded" or "")))
  end
end
do
  local _13_ = read_file(lua_cache_path)
  if (_13_ == "do local _ = (1 + 1) end\\nreturn {works = true}") then
    OK(string.format((".hotpot.lua applies a preprocessor" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format((".hotpot.lua applies a preprocessor" or "")))
  end
end
write_file(fnl_path_2, "{:works :also-true}")
write_file(dot_hotpot_path, "\nreturn {\n  build = true\n}")
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _15_ = read_file(lua_path)
  if (_15_ == "return {works = true}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = _15_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local _17_ = read_file(lua_path_2)
  if (_17_ == "return {works = \"also-true\"}") then
    OK(string.format(("build = true outputs to lua/ dir" or "")))
  else
    local __1_auto = _17_
    FAIL(string.format(("build = true outputs to lua/ dir" or "")))
  end
end
do
  local _19_ = vim.loop.fs_access(lua_cache_path, "R")
  if (_19_ == true) then
    OK(string.format(("previous cache lua still exists" or "")))
  else
    local __1_auto = _19_
    FAIL(string.format(("previous cache lua still exists" or "")))
  end
end
write_file(dot_hotpot_path, "\nreturn {\n  build = {{atomic = true},\n           {'fnl/**/*.fnl', true}},\n  clean = true,\n}")
write_file(junk_path, "return 1")
do
  local _21_ = vim.loop.fs_access(junk_path, "R")
  if (_21_ == true) then
    OK(string.format(("junk file exists" or "")))
  else
    local __1_auto = _21_
    FAIL(string.format(("junk file exists" or "")))
  end
end
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _23_ = vim.loop.fs_access(junk_path, "R")
  if (_23_ == false) then
    OK(string.format(("junk file is cleaned away" or "")))
  else
    local __1_auto = _23_
    FAIL(string.format(("junk file is cleaned away" or "")))
  end
end
return exit()