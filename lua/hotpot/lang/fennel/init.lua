local function make_module_record(modname, fnl_path, _3fopts)
  local _let_1_ = require("hotpot.loader.record")
  local new_module = _let_1_["new-module"]
  local opts = vim.tbl_extend("error", (_3fopts or {}), {prefix = "fnl", extension = "fnl"})
  return new_module(modname, fnl_path, opts)
end
local function make_runtime_record(modname, fnl_path, _3fopts)
  local _let_2_ = require("hotpot.loader.record")
  local new_runtime = _let_2_["new-runtime"]
  local opts = vim.tbl_extend("error", (_3fopts or {}), {extension = "fnl"})
  return new_runtime(modname, fnl_path, opts)
end
return {language = "fennel", ["make-runtime-record"] = make_runtime_record, ["make-module-record"] = make_module_record}