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
local function p(x)
  return (vim.fn.stdpath("config") .. x)
end
local setup_path = p("/lua/setup.lua")
local mod_path = p("/fnl/mod.fnl")
local mac_path = p("/fnl/mac.fnl")
write_file(setup_path, "\nrequire('hotpot').setup({\n  compiler = {\n    preprocessor = function(src, meta)\n      if meta.macro == true then\n        return '(fn inserted [] 100) ' .. src\n      else\n        return '(fn inserted [] 80) ' .. src\n      end\n    end\n  }\n})")
write_file(mac_path, "(fn exit-var [] `,(inserted)) {: exit-var}")
write_file(mod_path, "(import-macros {: exit-var} :mac) (os.exit (+ (inserted) (exit-var)))")
do
  local _4_
  do
    local fname = string.format("sub-nvim-%d.lua", vim.loop.hrtime())
    write_file(fname, string.format(("vim.opt.runtimepath:prepend(vim.loop.cwd())\n                             require('hotpot')\n                             " .. "require('setup') require('mod')")))
    vim.cmd(string.format("!%s +'set columns=1000' --headless -S %s", (vim.env.NVIM_BIN or "nvim"), fname))
    _4_ = vim.v.shell_error
  end
  if (_4_ == 180) then
    OK(string.format(("preprocessor applies in macros and modules independently" or "")))
  elseif true then
    local __1_auto = _4_
    FAIL(string.format(("preprocessor applies in macros and modules independently" or "")))
  else
  end
end
return exit()