local fmt = string["format"]
local injected_macro_searcher_3f = false
local compiler_options_stack = {}
local function spooky_prepare_plugins_21(options)
  local _let_1_ = require("hotpot.searcher")
  local mod_search = _let_1_["mod-search"]
  local fennel = require("hotpot.fennel")
  local plugins
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _i, plug in ipairs((options.plugins or {})) do
      local val_23_auto
      do
        local _2_ = type(plug)
        if (_2_ == "string") then
          local _3_ = mod_search({prefix = "fnl", extension = "fnl", modnames = {plug}})
          if ((_G.type(_3_) == "table") and (nil ~= _3_[1])) then
            local path = _3_[1]
            val_23_auto = fennel.dofile(path, {env = "_COMPILER", useMetadata = true, ["compiler-env"] = _G}, plug, path)
          else
            local _ = _3_
            val_23_auto = error(string.format("Could not find fennel compiler plugin %q", plug))
          end
        else
          local _ = _2_
          val_23_auto = plug
        end
      end
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    plugins = tbl_21_auto
  end
  options.plugins = plugins
  return nil
end
local function make_macro_loader(modname, fnl_path)
  local fennel = require("hotpot.fennel")
  local _let_7_ = require("hotpot.fs")
  local read_file_21 = _let_7_["read-file!"]
  local options
  local or_8_ = compiler_options_stack[1]
  if not or_8_ then
    local function _9_(src)
      return src
    end
    or_8_ = {modules = {}, macros = {env = "_COMPILER"}, preprocessor = _9_}
  end
  options = or_8_
  local preprocessor
  local function _10_(_241)
    return options.preprocessor(_241, {macro = true, ["macro?"] = true, path = fnl_path, modname = modname})
  end
  preprocessor = _10_
  local options0
  do
    local tmp_9_auto = options.macros
    tmp_9_auto["error-pinpoint"] = false
    tmp_9_auto["filename"] = fnl_path
    tmp_9_auto["module-name"] = modname
    options0 = tmp_9_auto
  end
  local _ = spooky_prepare_plugins_21(options0)
  local fnl_code
  do
    local _11_, _12_ = read_file_21(fnl_path)
    if (nil ~= _11_) then
      local file_content = _11_
      fnl_code = preprocessor(file_content)
    elseif ((_11_ == nil) and (nil ~= _12_)) then
      local err = _12_
      fnl_code = error(err)
    else
      fnl_code = nil
    end
  end
  local function _14_(modname0)
    local _let_15_ = require("hotpot.lang.fennel.dependency-tracker")
    local set_macro_modname_path = _let_15_["set-macro-modname-path"]
    set_macro_modname_path(modname0, fnl_path)
    return fennel.eval(fnl_code, options0, modname0)
  end
  return _14_
end
local function macro_searcher(modname)
  local _let_16_ = require("hotpot.searcher")
  local mod_search = _let_16_["mod-search"]
  local spec = {prefix = "fnl", extension = "fnl", modnames = {(modname .. ".init-macros"), (modname .. ".init"), modname}}
  local function _17_(...)
    local _18_ = ...
    if ((_G.type(_18_) == "table") and (nil ~= _18_[1])) then
      local path = _18_[1]
      return make_macro_loader(modname, path)
    elseif ((_G.type(_18_) == "table") and (_18_[1] == nil)) then
      return nil
    else
      return nil
    end
  end
  return _17_(mod_search(spec))
end
local function compile_string(source, modules_options, macros_options, _3fpreprocessor)
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:72")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:72")
  _G.assert((nil ~= source), "Missing argument source on fnl/hotpot/lang/fennel/compiler.fnl:72")
  local fennel = require("hotpot.fennel")
  local saved_fennel_path = fennel.path
  local saved_fennel_macro_path = fennel["macro-path"]
  local _
  fennel.path = ("./fnl/?.fnl;./fnl/?/init.fnl;" .. fennel.path)
  _ = nil
  local _0
  fennel["macro-path"] = ("./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl;" .. fennel["macro-path"])
  _0 = nil
  local _let_20_ = require("hotpot.runtime")
  local traceback = _let_20_["traceback"]
  local options
  do
    modules_options["error-pinpoint"] = false
    modules_options["filename"] = (modules_options.filename or "hotpot-compile-string")
    options = modules_options
  end
  local _1 = spooky_prepare_plugins_21(options)
  local preprocessor
  local or_21_ = _3fpreprocessor
  if not or_21_ then
    local function _22_(src)
      return src
    end
    or_21_ = _22_
  end
  preprocessor = or_21_
  local source0 = preprocessor(source, {path = modules_options.filename, modname = modules_options.modname, macro = false, ["macro?"] = false})
  if not injected_macro_searcher_3f then
    table.insert(fennel["macro-searchers"], 1, macro_searcher)
    injected_macro_searcher_3f = true
  else
  end
  table.insert(compiler_options_stack, 1, {modules = modules_options, macros = macros_options, preprocessor = preprocessor})
  local ok_3f, val = nil, nil
  local function _24_()
    return (fennel["compile-string"](source0, options))
  end
  ok_3f, val = xpcall(_24_, traceback)
  fennel.path = saved_fennel_path
  fennel["macro-path"] = saved_fennel_macro_path
  table.remove(compiler_options_stack, 1)
  modules_options["filename"] = nil
  modules_options["module-name"] = nil
  return ok_3f, val
end
local function compile_file(fnl_path, lua_path, modules_options, macros_options, _3fpreprocessor)
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:113")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:113")
  _G.assert((nil ~= lua_path), "Missing argument lua-path on fnl/hotpot/lang/fennel/compiler.fnl:113")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/hotpot/lang/fennel/compiler.fnl:113")
  local function check_existing(path)
    local uv = vim.loop
    local _let_25_ = (uv.fs_stat(path) or {})
    local type = _let_25_["type"]
    if not (("file" == type) or (nil == type)) then
      local failed_what_1_auto = "(or (= \"file\" type) (= nil type))"
      local err_2_auto = string.format("%s [failed: %s]", "Refusing to write to %q, it exists as a %s", failed_what_1_auto)
      return error(string.format(err_2_auto, path, type), 0)
    else
      return nil
    end
  end
  local function do_compile()
    local _let_27_ = require("hotpot.runtime")
    local windows_3f = _let_27_["windows?"]
    local _let_28_ = require("hotpot.fs")
    local read_file_21 = _let_28_["read-file!"]
    local write_file_21 = _let_28_["write-file!"]
    local is_lua_path_3f = _let_28_["is-lua-path?"]
    local is_fnl_path_3f = _let_28_["is-fnl-path?"]
    local make_path = _let_28_["make-path"]
    local _
    if not is_fnl_path_3f(fnl_path) then
      local failed_what_1_auto = "(is-fnl-path? fnl-path)"
      local err_2_auto = string.format("%s [failed: %s]", "compile-file fnl-path not fnl file: %q", failed_what_1_auto)
      _ = error(string.format(err_2_auto, fnl_path), 0)
    else
      _ = nil
    end
    local _0
    if not is_lua_path_3f(lua_path) then
      local failed_what_1_auto = "(is-lua-path? lua-path)"
      local err_2_auto = string.format("%s [failed: %s]", "compile-file lua-path not lua file: %q", failed_what_1_auto)
      _0 = error(string.format(err_2_auto, lua_path), 0)
    else
      _0 = nil
    end
    local fnl_code
    do
      local _31_, _32_ = read_file_21(fnl_path)
      if ((_31_ == nil) and (nil ~= _32_)) then
        local err = _32_
        fnl_code = error(err)
      elseif (nil ~= _31_) then
        local src = _31_
        fnl_code = src
      else
        fnl_code = nil
      end
    end
    assert((not windows_3f or (windows_3f and (#lua_path < 259))), string.format(("Lua path length (%s) was over the maximum supported by windows and " .. "can't be saved. Try using ':h hotpot-dot-hotpot' with build = true to " .. "compile to a shorter path."), lua_path))
    if not modules_options.filename then
      modules_options["filename"] = fnl_path
    else
    end
    local _35_, _36_ = compile_string(fnl_code, modules_options, macros_options, _3fpreprocessor)
    if ((_35_ == true) and (nil ~= _36_)) then
      local lua_code = _36_
      check_existing(lua_path)
      make_path(vim.fs.dirname(lua_path))
      return write_file_21(lua_path, lua_code)
    elseif ((_35_ == false) and (nil ~= _36_)) then
      local errors = _36_
      return error(errors)
    else
      return nil
    end
  end
  local function _38_(_241)
    local lines = vim.split(_241, "\n")
    local function _39_()
      local s,c = "", true
      for _, line in ipairs(lines) do
        if not c then break end
        local function _41_()
          local _40_ = string.find(line, "stack traceback:", 1, true)
          if (_40_ == 1) then
            return {s, false}
          else
            local _0 = _40_
            return {(s .. line .. "\n"), true}
          end
        end
        local _set_43_ = _41_()
        s = _set_43_[1]
        c = _set_43_[2]
      end
      return {s, c}
    end
    local _let_44_ = _39_()
    local s = _let_44_[1]
    local _ = _let_44_[2]
    return s
  end
  return xpcall(do_compile, _38_)
end
local function compile_record(record, modules_options, macros_options, preprocessor)
  _G.assert((nil ~= preprocessor), "Missing argument preprocessor on fnl/hotpot/lang/fennel/compiler.fnl:152")
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:152")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:152")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/lang/fennel/compiler.fnl:152")
  local lua_path = record["lua-path"]
  local src_path = record["src-path"]
  local modname = record["modname"]
  local _let_45_ = require("hotpot.lang.fennel.dependency-tracker")
  local new_macro_dep_tracking_plugin = _let_45_["new"]
  local deps_for_fnl_path = _let_45_["deps-for-fnl-path"]
  local modules_options0
  do
    modules_options["module-name"] = modname
    modules_options["filename"] = src_path
    modules_options["plugins"] = (modules_options.plugins or {})
    modules_options0 = modules_options
  end
  local plugin = new_macro_dep_tracking_plugin(src_path, modname)
  table.insert(modules_options0.plugins, 1, plugin)
  local ok_3f, extra = nil, nil
  local function _46_(...)
    local _47_ = ...
    if (_47_ == true) then
      local function _48_(...)
        local _49_ = ...
        if (nil ~= _49_) then
          local deps = _49_
          return true, deps
        else
          local __87_auto = _49_
          return ...
        end
      end
      return _48_((deps_for_fnl_path(src_path) or {}))
    else
      local __87_auto = _47_
      return ...
    end
  end
  ok_3f, extra = _46_(compile_file(src_path, lua_path, modules_options0, macros_options, preprocessor))
  table.remove(modules_options0.plugins, 1)
  return ok_3f, extra
end
return {["compile-string"] = compile_string, ["compile-file"] = compile_file, ["compile-record"] = compile_record}