local function inject_macro_searcher()
  local _let_1_ = require("hotpot.lang.fennel.compiler")
  local compile_string = _let_1_["compile-string"]
  local _let_2_ = require("hotpot.runtime")
  local default_config = _let_2_["default-config"]
  local _let_3_ = default_config()
  local compiler_options = _let_3_["compiler"]
  local modules_options = compiler_options["modules"]
  local macros_options = compiler_options["macros"]
  local preprocessor = compiler_options["preprocessor"]
  return compile_string("(+ 1 1)", modules_options, macros_options, preprocessor)
end
local function eval_string(code, _3foptions)
  inject_macro_searcher()
  local _let_4_ = require("hotpot.fennel")
  local eval = _let_4_["eval"]
  local _let_5_ = require("hotpot.runtime")
  local traceback = _let_5_["traceback"]
  local options = (_3foptions or {})
  local _
  if (nil == options.filename) then
    options["filename"] = "hotpot-live-eval"
    _ = nil
  else
    _ = nil
  end
  local do_eval
  local function _7_()
    return eval(code, options)
  end
  do_eval = _7_
  return xpcall(do_eval, traceback)
end
local function eval_range(buf, start_pos, stop_pos, _3foptions)
  local _let_8_ = require("hotpot.api.get_text")
  local get_range = _let_8_["get-range"]
  return eval_string(get_range(buf, start_pos, stop_pos), _3foptions)
end
local function eval_selection(_3foptions)
  local _let_9_ = require("hotpot.api.get_text")
  local get_selection = _let_9_["get-selection"]
  return eval_string(get_selection(), _3foptions)
end
local function eval_buffer(buf, _3foptions)
  local _let_10_ = require("hotpot.api.get_text")
  local get_buf = _let_10_["get-buf"]
  return eval_string(get_buf(buf), _3foptions)
end
local function eval_file(fnl_file, _3foptions)
  inject_macro_searcher()
  assert(fnl_file, "eval-file: must provide path to .fnl file")
  local _let_11_ = require("hotpot.fennel")
  local dofile = _let_11_["dofile"]
  local _let_12_ = require("hotpot.runtime")
  local traceback = _let_12_["traceback"]
  local options = (_3foptions or {})
  if (nil == options.filename) then
    options["filename"] = fnl_file
  else
  end
  local function _14_()
    return dofile(fnl_file, options)
  end
  return xpcall(_14_, traceback)
end
local function eval_module(modname, _3foptions)
  assert(modname, "eval-module: must provide modname")
  local _let_15_ = require("hotpot.searcher")
  local mod_search = _let_15_["mod-search"]
  local _let_16_ = require("hotpot.common")
  local put_new = _let_16_["put-new"]
  local _17_ = mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname .. ".init"), modname}})
  if ((_G.type(_17_) == "table") and (nil ~= _17_[1])) then
    local path = _17_[1]
    local options
    do
      local tmp_9_auto = vim.deepcopy((_3foptions or {}))
      put_new(tmp_9_auto, "module-name", modname)
      put_new(tmp_9_auto, "filename", path)
      options = tmp_9_auto
    end
    return eval_file(path, options)
  else
    local _ = _17_
    return error(string.format("compile-modname: could not find file for %s", modname))
  end
end
return {["eval-string"] = eval_string, ["eval-range"] = eval_range, ["eval-selection"] = eval_selection, ["eval-buffer"] = eval_buffer, ["eval-file"] = eval_file, ["eval-module"] = eval_module}