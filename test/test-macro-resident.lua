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
local dot_hotpot_path = (vim.fn.stdpath("config") .. "/.hotpot.lua")
local fnl_path = (vim.fn.stdpath("config") .. "/fnl/abc.fnl")
local macro_path = (vim.fn.stdpath("config") .. "/fnl/macro.fnl")
local lua_path = (vim.fn.stdpath("config") .. "/lua/abc.lua")
write_file(dot_hotpot_path, "return {build = {{verbose = false}, {'fnl/macro.fnl', false}, {'fnl/**/*.fnl', true}}}")
write_file(macro_path, "(fn dbl [a] `(+ ,a ,a ,a)) {: dbl}")
write_file(fnl_path, "(import-macros {: dbl} :macro) (dbl 1)")
vim.cmd(string.format("edit %s", fnl_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _11_ = read_file(lua_path)
  if (_11_ == "return (1 + 1 + 1)") then
    OK(string.format(("returns first version of macro" or "")))
  else
    local __1_auto = _11_
    FAIL(string.format(("returns first version of macro" or "")))
  end
end
write_file(macro_path, "(fn dbl [a] `(+ ,a ,a)) {: dbl}")
vim.cmd(string.format("edit %s", macro_path))
vim.cmd("set ft=fennel")
vim.cmd("w")
do
  local _13_ = read_file(lua_path)
  if (_13_ == "return (1 + 1)") then
    OK(string.format(("returns second version of macro" or "")))
  else
    local __1_auto = _13_
    FAIL(string.format(("returns second version of macro" or "")))
  end
end
return exit()