 local _local_0_ = require("hotpot.searcher.locate") local locate_module = _local_0_["locate-module"]
 local _local_1_ = require("hotpot.compiler") local compile_string = _local_1_["compile-string"]
 local _local_2_ = require("hotpot.fs") local file_missing_3f = _local_2_["file-missing?"]
 local file_stale_3f = _local_2_["file-stale?"]

 local read_file = _local_2_["read-file"] local write_file = _local_2_["write-file"]


 local function fnl_path_to_compiled_path(path, prefix) local function _0_(...) return (prefix .. ...) end











 return string.gsub(_0_(vim.loop.fs_realpath(path)), "%.fnl$", ".lua") end

 local function dependency_filename(lua_path)
 return (lua_path .. ".deps") end

 local function save_dependency_graph(path, graph)
 local deps do local tbl_0_ = {} for maybe_modname, path0 in pairs(graph) do local _0_ if not string.match(maybe_modname, "^__") then

 _0_ = path0 else _0_ = nil end tbl_0_[(#tbl_0_ + 1)] = _0_ end deps = tbl_0_ end if (#deps > 0) then

 print(path, vim.inspect(deps))
 return write_file(dependency_filename(path), table.concat(deps, "\n")) end end


 local function load_dependency_graph(lua_path)


 local lines = read_file(dependency_filename(lua_path)) local tbl_0_ = {} for line in string.gmatch(lines, "([^\n]*)\n?") do

 local _0_ if (line ~= "") then _0_ = line else _0_ = nil end tbl_0_[(#tbl_0_ + 1)] = _0_ end return tbl_0_ end

 local function has_dependency_graph(lua_path)
 return vim.loop.fs_access(dependency_filename(lua_path), "R") end

 local function has_stale_dependency(fnl_path, lua_path)
 local deps = load_dependency_graph(lua_path) local has_stale = false

 for _, dep_path in ipairs(deps) do if has_stale then break end
 print("@@ check dep", dep_path)
 print("stale:", file_stale_3f(dep_path, lua_path))




 has_stale = file_stale_3f(dep_path, lua_path) end
 print("@@ stale deps?", fnl_path, has_stale)
 return has_stale end

 local function needs_compilation_3f(fnl_path, lua_path)
 return ((file_missing_3f(lua_path) or file_stale_3f(fnl_path, lua_path)) or (has_dependency_graph(lua_path) and has_stale_dependency(fnl_path, lua_path))) end








 local function create_loader(path)
 local function _0_(modname)


 return dofile(path) end return _0_ end

 local function maybe_compile(fnl_path, lua_path)
 local _0_ = needs_compilation_3f(fnl_path, lua_path) if (_0_ == false) then

 print("no-compilation-needed", fnl_path)
 return lua_path elseif (_0_ == true) then

 local _1_, _2_ = compile_string(read_file(fnl_path), {correlate = true, filename = fnl_path}) if ((_1_ == true) and (nil ~= _2_)) then local code = _2_


 print("compiled", fnl_path)


 vim.fn.mkdir(string.match(lua_path, "(.+)/.-%.lua"), "p")
 write_file(lua_path, code)
 return lua_path elseif ((_1_ == false) and (nil ~= _2_)) then local errors = _2_

 vim.api.nvim_err_write(errors)
 return ("Compilation failure for " .. fnl_path) end end end

 local function searcher(config, modname)






 local _0_ = locate_module(modname) if (nil ~= _0_) then local fnl_path = _0_


 local lua_path = fnl_path_to_compiled_path(fnl_path, config.prefix)

 print("module.seacher.found", fnl_path) if not ("hotpot.cache" == modname) then

 local cache = require("hotpot.cache")
 cache.down(modname) end

 maybe_compile(fnl_path, lua_path)
 local loader = create_loader(lua_path) if not ("hotpot.cache" == modname) then

 local cache = require("hotpot.cache")
 print("dependecy-graph", vim.inspect(cache["whole-graph"]()))
 save_dependency_graph(lua_path, cache["current-graph"]())
 cache.up() end
 return loader elseif (_0_ == nil) then


 return nil end end

 return searcher
