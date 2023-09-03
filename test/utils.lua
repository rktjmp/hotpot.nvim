local function read_file(path)
  return table.concat(vim.fn.readfile(path), "\\n")
end
local function write_file(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local _1_
  if ("string" == type(content)) then
    _1_ = {content}
  else
    _1_ = content
  end
  return vim.fn.writefile(_1_, path)
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
do end (vim.opt.runtimepath):prepend("/hotpot")
require("hotpot")
return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}