local function compile_record(record)
  local _let_1_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_1_["compile-file"]
  return compile_file(record)
end
local function make_module_record(modname, fnl_path, _3fopts)
  local _let_2_ = require("hotpot.loader.record")
  local new_module = _let_2_["new-module"]
  local opts = vim.tbl_extend("error", (_3fopts or {}), {prefix = "fnl", extension = "fnl"})
  return new_module(modname, fnl_path, opts)
end
local function make_runtime_record(modname, fnl_path, _3fopts)
  local _let_3_ = require("hotpot.loader.record")
  local new_runtime = _let_3_["new-runtime"]
  local opts = vim.tbl_extend("error", (_3fopts or {}), {extension = "fnl"})
  return new_runtime(modname, fnl_path, opts)
end
return {language = "fennel", ["compile-record"] = compile_record, ["make-runtime-record"] = make_runtime_record, ["make-module-record"] = make_module_record}