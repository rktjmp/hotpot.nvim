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
local function eval_string(code, _3foptions)
  inject_macro_searcher()
  local _let_5_ = require("hotpot.fennel")
  local eval = _let_5_["eval"]
  local _let_6_ = require("hotpot.runtime")
  local traceback = _let_6_["traceback"]
  local options = (_3foptions or {})
  local _
  if (nil == options.filename) then
    options["filename"] = "hotpot-live-eval"
    _ = nil
  else
    _ = nil
  end
  local do_eval
  local function _8_()
    return eval(code, options)
  end
  do_eval = _8_
  return xpcall(do_eval, traceback)
end
local function eval_range(buf, start_pos, stop_pos, _3foptions)
  local _let_9_ = require("hotpot.api.get_text")
  local get_range = _let_9_["get-range"]
  return eval_string(get_range(buf, start_pos, stop_pos), _3foptions)
end
local function eval_selection(_3foptions)
  local _let_10_ = require("hotpot.api.get_text")
  local get_selection = _let_10_["get-selection"]
  return eval_string(get_selection(), _3foptions)
end
local function eval_buffer(buf, _3foptions)
  local _let_11_ = require("hotpot.api.get_text")
  local get_buf = _let_11_["get-buf"]
  return eval_string(get_buf(buf), _3foptions)
end
local function eval_file(fnl_file, _3foptions)
  inject_macro_searcher()
  assert(fnl_file, "eval-file: must provide path to .fnl file")
  local _let_12_ = require("hotpot.fennel")
  local dofile = _let_12_["dofile"]
  local _let_13_ = require("hotpot.runtime")
  local traceback = _let_13_["traceback"]
  local options = (_3foptions or {})
  if (nil == options.filename) then
    options["filename"] = fnl_file
  else
  end
  local function _15_()
    return dofile(fnl_file, options)
  end
  return xpcall(_15_, traceback)
end
local function eval_module(modname, _3foptions)
  assert(modname, "eval-module: must provide modname")
  local _let_16_ = require("hotpot.searcher")
  local mod_search = _let_16_["mod-search"]
  local _let_17_ = require("hotpot.common")
  local put_new = _let_17_["put-new"]
  local _18_ = mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname .. ".init"), modname}})
  if ((_G.type(_18_) == "table") and (nil ~= (_18_)[1])) then
    local path = (_18_)[1]
    local options
    do
      local _19_ = vim.deepcopy((_3foptions or {}))
      put_new(_19_, "module-name", modname)
      put_new(_19_, "filename", path)
      options = _19_
    end
    return eval_file(path, options)
  elseif true then
    local _ = _18_
    return error(string.format("compile-modname: could not find file for %s", modname))
  else
    return nil
  end
end
return {["eval-string"] = eval_string, ["eval-range"] = eval_range, ["eval-selection"] = eval_selection, ["eval-buffer"] = eval_buffer, ["eval-file"] = eval_file, ["eval-module"] = eval_module}