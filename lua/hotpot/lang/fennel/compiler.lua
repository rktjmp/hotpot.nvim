local _local_1_ = string
local fmt = _local_1_["format"]
local injected_macro_searcher_3f = false
local compiler_options_stack = {}
local function spooky_prepare_plugins_21(options)
  local _let_2_ = require("hotpot.searcher")
  local mod_search = _let_2_["mod-search"]
  local fennel = require("hotpot.fennel")
  local plugins
  do
    local tbl_19_auto = {}
    local i_20_auto = 0
    for _i, plug in ipairs((options.plugins or {})) do
      local val_21_auto
      do
        local _3_ = type(plug)
        if (_3_ == "string") then
          local _4_ = mod_search({prefix = "fnl", extension = "fnl", modnames = {plug}})
          if ((_G.type(_4_) == "table") and (nil ~= _4_[1])) then
            local path = _4_[1]
            val_21_auto = fennel.dofile(path, {env = "_COMPILER", useMetadata = true, ["compiler-env"] = _G}, plug, path)
          else
            local _ = _4_
            val_21_auto = error(string.format("Could not find fennel compiler plugin %q", plug))
          end
        else
          local _ = _3_
          val_21_auto = plug
        end
      end
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    plugins = tbl_19_auto
  end
  options.plugins = plugins
  return nil
end
local function make_macro_loader(modname, fnl_path)
  local fennel = require("hotpot.fennel")
  local _let_8_ = require("hotpot.fs")
  local read_file_21 = _let_8_["read-file!"]
  local options
  local function _9_(src)
    return src
  end
  options = (compiler_options_stack[1] or {modules = {}, macros = {env = "_COMPILER"}, preprocessor = _9_})
  local preprocessor
  local function _10_(_241)
    return options.preprocessor(_241, {macro = true, ["macro?"] = true, path = fnl_path, modname = modname})
  end
  preprocessor = _10_
  local options0
  do
    local _11_ = options.macros
    _11_["error-pinpoint"] = false
    _11_["filename"] = fnl_path
    _11_["module-name"] = modname
    options0 = _11_
  end
  local _ = spooky_prepare_plugins_21(options0)
  local fnl_code
  do
    local _12_, _13_ = read_file_21(fnl_path)
    if (nil ~= _12_) then
      local file_content = _12_
      fnl_code = preprocessor(file_content)
    elseif ((_12_ == nil) and (nil ~= _13_)) then
      local err = _13_
      fnl_code = error(err)
    else
      fnl_code = nil
    end
  end
  local function _15_(modname0)
    local _let_16_ = require("hotpot.lang.fennel.dependency-tracker")
    local set_macro_modname_path = _let_16_["set-macro-modname-path"]
    set_macro_modname_path(modname0, fnl_path)
    return fennel.eval(fnl_code, options0, modname0)
  end
  return _15_
end
local function macro_searcher(modname)
  local _let_17_ = require("hotpot.searcher")
  local mod_search = _let_17_["mod-search"]
  local spec = {prefix = "fnl", extension = "fnl", modnames = {(modname .. ".init-macros"), (modname .. ".init"), modname}}
  local function _18_(...)
    local _19_ = ...
    if ((_G.type(_19_) == "table") and (nil ~= _19_[1])) then
      local path = _19_[1]
      return make_macro_loader(modname, path)
    elseif ((_G.type(_19_) == "table") and (_19_[1] == nil)) then
      return nil
    else
      return nil
    end
  end
  return _18_(mod_search(spec))
end
local function compile_string(source, modules_options, macros_options, _3fpreprocessor)
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:72")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:72")
  _G.assert((nil ~= source), "Missing argument source on fnl/hotpot/lang/fennel/compiler.fnl:72")
  local fennel = require("hotpot.fennel")
  local _let_21_ = require("hotpot.runtime")
  local traceback = _let_21_["traceback"]
  local options
  do
    modules_options["error-pinpoint"] = false
    modules_options["filename"] = (modules_options.filename or "hotpot-compile-string")
    options = modules_options
  end
  local _ = spooky_prepare_plugins_21(options)
  local preprocessor
  local function _22_(src)
    return src
  end
  preprocessor = (_3fpreprocessor or _22_)
  local source0 = preprocessor(source, {path = modules_options.filename, modname = modules_options.modname, macro = false, ["macro?"] = false})
  if not injected_macro_searcher_3f then
    table.insert(fennel["macro-searchers"], 1, macro_searcher)
    injected_macro_searcher_3f = true
  else
  end
  table.insert(compiler_options_stack, 1, {modules = modules_options, macros = macros_options, preprocessor = preprocessor})
  local ok_3f, val = nil, nil
  local function _24_()
    local _25_ = fennel["compile-string"](source0, options)
    return _25_
  end
  ok_3f, val = xpcall(_24_, traceback)
  table.remove(compiler_options_stack, 1)
  do end (modules_options)["filename"] = nil
  modules_options["module-name"] = nil
  return ok_3f, val
end
local function compile_file(fnl_path, lua_path, modules_options, macros_options, _3fpreprocessor)
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:106")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:106")
  _G.assert((nil ~= lua_path), "Missing argument lua-path on fnl/hotpot/lang/fennel/compiler.fnl:106")
  _G.assert((nil ~= fnl_path), "Missing argument fnl-path on fnl/hotpot/lang/fennel/compiler.fnl:106")
  local function check_existing(path)
    local uv = vim.loop
    local _let_26_ = (uv.fs_stat(path) or {})
    local type = _let_26_["type"]
    if not (("file" == type) or (nil == type)) then
      local failed_what_1_auto = "(or (= \"file\" type) (= nil type))"
      local err_2_auto = string.format("%s [failed: %s]", "Refusing to write to %q, it exists as a %s", failed_what_1_auto)
      return error(string.format(err_2_auto, path, type), 0)
    else
      return nil
    end
  end
  local function do_compile()
    local _let_28_ = require("hotpot.runtime")
    local windows_3f = _let_28_["windows?"]
    local _let_29_ = require("hotpot.fs")
    local read_file_21 = _let_29_["read-file!"]
    local write_file_21 = _let_29_["write-file!"]
    local is_lua_path_3f = _let_29_["is-lua-path?"]
    local is_fnl_path_3f = _let_29_["is-fnl-path?"]
    local make_path = _let_29_["make-path"]
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
      local _32_, _33_ = read_file_21(fnl_path)
      if ((_32_ == nil) and (nil ~= _33_)) then
        local err = _33_
        fnl_code = error(err)
      elseif (nil ~= _32_) then
        local src = _32_
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
    local _36_, _37_ = compile_string(fnl_code, modules_options, macros_options, _3fpreprocessor)
    if ((_36_ == true) and (nil ~= _37_)) then
      local lua_code = _37_
      check_existing(lua_path)
      make_path(vim.fs.dirname(lua_path))
      return write_file_21(lua_path, lua_code)
    elseif ((_36_ == false) and (nil ~= _37_)) then
      local errors = _37_
      return error(errors)
    else
      return nil
    end
  end
  local function _39_(_241)
    local lines = vim.split(_241, "\n")
    local function _41_()
      local _var_42_ = {"", true}
      local s = _var_42_[1]
      local c = _var_42_[2]
      for _, line in ipairs(lines) do
        if not c then break end
        local function _45_()
          local _44_ = string.find(line, "stack traceback:", 1, true)
          if (_44_ == 1) then
            return {s, false}
          else
            local _0 = _44_
            return {(s .. line .. "\n"), true}
          end
        end
        local _set_43_ = _45_()
        s = _set_43_[1]
        c = _set_43_[2]
      end
      return {s, c}
    end
    local _let_40_ = _41_()
    local s = _let_40_[1]
    local _ = _let_40_[2]
    return s
  end
  return xpcall(do_compile, _39_)
end
local function compile_record(record, modules_options, macros_options, preprocessor)
  _G.assert((nil ~= preprocessor), "Missing argument preprocessor on fnl/hotpot/lang/fennel/compiler.fnl:146")
  _G.assert((nil ~= macros_options), "Missing argument macros-options on fnl/hotpot/lang/fennel/compiler.fnl:146")
  _G.assert((nil ~= modules_options), "Missing argument modules-options on fnl/hotpot/lang/fennel/compiler.fnl:146")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/lang/fennel/compiler.fnl:146")
  local _let_47_ = record
  local lua_path = _let_47_["lua-path"]
  local src_path = _let_47_["src-path"]
  local modname = _let_47_["modname"]
  local _let_48_ = require("hotpot.lang.fennel.dependency-tracker")
  local new_macro_dep_tracking_plugin = _let_48_["new"]
  local deps_for_fnl_path = _let_48_["deps-for-fnl-path"]
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
  local function _49_(...)
    local _50_ = ...
    if (_50_ == true) then
      local function _51_(...)
        local _52_ = ...
        if (nil ~= _52_) then
          local deps = _52_
          return true, deps
        else
          local __85_auto = _52_
          return ...
        end
      end
      return _51_((deps_for_fnl_path(src_path) or {}))
    else
      local __85_auto = _50_
      return ...
    end
  end
  ok_3f, extra = _49_(compile_file(src_path, lua_path, modules_options0, macros_options, preprocessor))
  table.remove(modules_options0.plugins, 1)
  return ok_3f, extra
end
return {["compile-string"] = compile_string, ["compile-file"] = compile_file, ["compile-record"] = compile_record}