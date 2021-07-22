 local _local_0_ = require("hotpot.searcher.locate") local locate_module = _local_0_["locate-module"]
 local _local_1_ = require("hotpot.compiler") local compile_string = _local_1_["compile-string"]
 local _local_2_ = require("hotpot.fs") local file_missing_3f = _local_2_["file-missing?"]
 local file_stale_3f = _local_2_["file-stale?"]

 local read_file = _local_2_["read-file"] local write_file = _local_2_["write-file"]


 local function fnl_path_to_compiled_path(path, prefix) local function _0_(...) return (prefix .. ...) end











 return string.gsub(_0_(vim.loop.fs_realpath(path)), "%.fnl$", ".lua") end

 local function needs_compilation_3f(fnl_path, lua_path)
 return (file_missing_3f(lua_path) or file_stale_3f(fnl_path, lua_path)) end

 local function create_loader(path)
 local function _0_(modname)
 return dofile(path) end return _0_ end

 local function maybe_compile(fnl_path, lua_path)
 local _0_ = needs_compilation_3f(fnl_path, lua_path) if (_0_ == false) then
 return lua_path elseif (_0_ == true) then

 local _1_, _2_ = compile_string(read_file(fnl_path), {correlate = true, filename = fnl_path}) if ((_1_ == true) and (nil ~= _2_)) then local code = _2_




 vim.fn.mkdir(string.match(lua_path, "(.+)/.-%.lua"), "p")
 write_file(lua_path, code)
 return lua_path elseif ((_1_ == false) and (nil ~= _2_)) then local errors = _2_

 vim.api.nvim_err_write(errors)
 return ("Compilation failure for " .. fnl_path) end end end

 local function searcher(config, modname)






 local _0_ = locate_module(modname) if (nil ~= _0_) then local fnl_path = _0_


 local lua_path = fnl_path_to_compiled_path(fnl_path, config.prefix)

 print("fnl-path", fnl_path, "lua-path", lua_path)
 maybe_compile(fnl_path, lua_path)
 return create_loader(lua_path) elseif (_0_ == nil) then


 return nil end end

 return searcher
