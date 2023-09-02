local function inject_macro_searcher()
  local _let_1_ = require("hotpot.lang.fennel.compiler")
  local compile_string = _let_1_["compile-string"]
  local _let_2_ = require("hotpot.runtime")
  local default_config = _let_2_["default-config"]
  local _let_3_ = default_config()
  local compiler_options = _let_3_["compiler"]
  local _let_4_ = compiler_options
  local modules_options = _let_4_["modules"]
  local macros_options = _let_4_["macros"]
  local preprocessor = _let_4_["preprocessor"]
  return compile_string("(+ 1 1)", modules_options, macros_options, preprocessor)
end
local function compile_string(str, compiler_options)
  inject_macro_searcher()
  local _let_5_ = require("hotpot.fennel")
  local compile_string0 = _let_5_["compile-string"]
  local _let_6_ = require("hotpot.runtime")
  local traceback = _let_6_["traceback"]
  local function _7_()
    local _8_ = compile_string0(str, compiler_options)
    return _8_
  end
  return xpcall(_7_, traceback)
end
local function compile_range(buf, start_pos, stop_pos, compiler_options)
  local _let_9_ = require("hotpot.api.get_text")
  local get_range = _let_9_["get-range"]
  return compile_string(get_range(buf, start_pos, stop_pos), compiler_options)
end
local function compile_selection(compiler_options)
  local _let_10_ = require("hotpot.api.get_text")
  local get_selection = _let_10_["get-selection"]
  return compile_string(get_selection(), compiler_options)
end
local function compile_buffer(buf, compiler_options)
  local _let_11_ = require("hotpot.api.get_text")
  local get_buf = _let_11_["get-buf"]
  return compile_string(get_buf(buf), compiler_options)
end
local function compile_file(fnl_path, compiler_options)
  local _let_12_ = require("hotpot.fs")
  local is_fnl_path_3f = _let_12_["is-fnl-path?"]
  local file_exists_3f = _let_12_["file-exists?"]
  local read_file_21 = _let_12_["read-file!"]
  if not is_fnl_path_3f(fnl_path) then
    local failed_what_1_auto = "(is-fnl-path? fnl-path)"
    local err_2_auto = string.format("%s [failed: %s]", "compile-file: must provide .fnl path, got: %q", failed_what_1_auto)
    error(string.format(err_2_auto, fnl_path), 0)
  else
  end
  if not file_exists_3f(fnl_path) then
    local failed_what_1_auto = "(file-exists? fnl-path)"
    local err_2_auto = string.format("%s [failed: %s]", "compile-file: doesn't exist: %q", failed_what_1_auto)
    error(string.format(err_2_auto, fnl_path), 0)
  else
  end
  return compile_string(read_file_21(fnl_path), compiler_options)
end
return {["compile-string"] = compile_string, ["compile-range"] = compile_range, ["compile-selection"] = compile_selection, ["compile-buffer"] = compile_buffer, ["compile-file"] = compile_file}