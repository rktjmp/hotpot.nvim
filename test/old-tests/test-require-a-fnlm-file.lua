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
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_10_ = require("test.utils")
local FAIL = _local_10_.FAIL
local NVIM_APPNAME = _local_10_.NVIM_APPNAME
local OK = _local_10_.OK
local exit = _local_10_.exit
local read_file = _local_10_["read-file"]
local write_file = _local_10_["write-file"]
local function in_path(path)
  return (vim.fn.stdpath("config") .. "/fnl/" .. path)
end
write_file(in_path("code.fnl"), "(import-macros {: sum} :my-macro) (sum 1 2)")
write_file(in_path("my-macro.fnlm"), "{:sum (fn [a b] `(+ ,a ,b))}")
do
  local case_11_, case_12_ = pcall(require, "code")
  if ((case_11_ == true) and (case_12_ == 3)) then
    OK(string.format(("can require fnlm macro file" or "")))
  else
    local __1_auto = case_11_
    FAIL(string.format(("can require fnlm macro file" or "")))
  end
end
write_file(in_path("prelude/init.fnl"), "(import-macros {: sum} :my-macro) (sum 5 5)")
write_file(in_path("prelude/init.fnlm"), "{:sum (fn [a b] `(+ ,a ,b))}")
do
  local case_14_, case_15_ = pcall(require, "prelude")
  if ((case_14_ == true) and (case_15_ == 10)) then
    OK(string.format(("can require mod/init.fnlm when mod/init.fnl exists" or "")))
  else
    local __1_auto = case_14_
    FAIL(string.format(("can require mod/init.fnlm when mod/init.fnl exists" or "")))
  end
end
return exit()