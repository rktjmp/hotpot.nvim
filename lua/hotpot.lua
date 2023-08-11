 assert((1 == vim.fn.has("nvim-0.9.1")), "Hotpot requires neovim 0.9.1+")

 package.preload["hotpot.bootstrap"] = package.preload["hotpot.bootstrap"] or function(...) local uv = vim.loop local path_separator = string.match(package.config, "(.-)\n") local function join_path(head, ...) _G.assert((nil ~= head), "Missing argument head on fnl/hotpot/bootstrap.fnl:8") local t = head for _, part in ipairs({...}) do t = (t .. path_separator .. part) end return t end local function new_canary(hotpot_dir, lua_dir) local canary_in_repo do local canary_folder = join_path(hotpot_dir, "canary") local handle = uv.fs_opendir(canary_folder, nil, 1) local files = uv.fs_readdir(handle) local _ = uv.fs_closedir(handle) local _let_1_ = files local _let_2_ = _let_1_[1] local name = _let_2_["name"] canary_in_repo = join_path(canary_folder, name) end local canary_in_build = join_path(lua_dir, "canary") return {["canary-in-repo"] = canary_in_repo, ["canary-in-build"] = canary_in_build} end local function canary_valid_3f(_3_) local _arg_4_ = _3_ local canary_in_build = _arg_4_["canary-in-build"] return not (nil == uv.fs_realpath(canary_in_build)) end local function create_canary_link(_5_) local _arg_6_ = _5_ local canary_in_build = _arg_6_["canary-in-build"] local canary_in_repo = _arg_6_["canary-in-repo"] uv.fs_unlink(canary_in_build) return assert(uv.fs_symlink(canary_in_repo, canary_in_build), ("Could not create canary symlink. If you are using window you may have " .. "to enable developer mode. See hotpots readme for details.")) end local function compile_hotpot(fnl_dir, lua_dir) local function compile_file(fnl_src, lua_dest) local _let_7_ = require("hotpot.fennel") local compile_string = _let_7_["compile-string"] local fnl_file = io.open(fnl_src) local lua_file = io.open(lua_dest, "w") local function close_handlers_10_auto(ok_11_auto, ...) lua_file:close() fnl_file:close() if ok_11_auto then return ... else return error(..., 0) end end local function _9_() local fnl_code = fnl_file:read("*a") local lua_code = compile_string(fnl_code, {filename = fnl_src, correlate = true}) return lua_file:write(lua_code) end return close_handlers_10_auto(_G.xpcall(_9_, (package.loaded.fennel or debug).traceback)) end local function compile_dir(in_dir, out_dir) local scanner = uv.fs_scandir(in_dir) local function _10_() return uv.fs_scandir_next(scanner) end for name, kind in _10_ do local _11_ = kind if (_11_ == "directory") then local in_down = join_path(in_dir, name) local out_down = join_path(out_dir, name) vim.fn.mkdir(out_down, "p") compile_dir(in_down, out_down) elseif (_11_ == "file") then local in_file = join_path(in_dir, name) local out_name = string.gsub(name, ".fnl$", ".lua") local out_file = join_path(out_dir, out_name) if not ((name == "macros.fnl") or (name == "hotpot.fnl")) then compile_file(in_file, out_file) else end else end end return nil end local fennel = require("hotpot.fennel") local default_macro_path = fennel["macro-path"] local fnl_dir_search_path = join_path(fnl_dir, "?.fnl") local cache_dir = join_path(vim.fn.stdpath("cache"), "hotpot") fennel["macro-path"] = (fnl_dir_search_path .. ";" .. default_macro_path) compile_dir(fnl_dir, lua_dir) fennel["macro-path"] = default_macro_path vim.fn.mkdir(cache_dir, "p") return true end local function bootstrap() local hotpot_dir = string.match((debug.getinfo(1, "S")).source, "@(.+)..?lua..?hotpot%.lua$") local fnl_dir = join_path(hotpot_dir, "fnl") local lua_dir do local ideal_path = join_path(hotpot_dir, "lua") if uv.fs_access(ideal_path, "W") then lua_dir = ideal_path else local cache_dir = vim.fn.stdpath("cache") local build_to_cache_dir = join_path(cache_dir, "hotpot", "compiled", "hotpot.nvim", "lua") local search_path = (join_path(build_to_cache_dir, "?/init.lua;") .. join_path(build_to_cache_dir, "?.lua;")) vim.fn.mkdir(build_to_cache_dir, "p") do end (package)["path"] = (search_path .. package.path) lua_dir = build_to_cache_dir end end local canary = new_canary(hotpot_dir, lua_dir) if not canary_valid_3f(canary) then compile_hotpot(fnl_dir, lua_dir) return create_canary_link(canary) else return nil end end return bootstrap end require("hotpot.bootstrap")()

 local _let_16_ = require("hotpot.loader") local make_searcher = _let_16_["make-searcher"] local compiled_cache_path = _let_16_["compiled-cache-path"]
 local _let_17_ = require("hotpot.fs") local join_path = _let_17_["join-path"] local make_path = _let_17_["make-path"]
 local _let_18_ = require("hotpot.common") local set_lazy_proxy = _let_18_["set-lazy-proxy"]



 make_path(compiled_cache_path) do end (vim.opt.runtimepath):prepend(join_path(compiled_cache_path, "*"))

 do end (package.loaders)[1] = make_searcher()

 local function setup(options)


 local runtime = require("hotpot.runtime")
 local config = runtime["set-config"](options)
 local ftplugin = require("hotpot.neovim.ftplugin")
 if true then
 ftplugin.enable() else end
 if config.provide_require_fennel then
 local function _20_() return require("hotpot.fennel") end package.preload["fennel"] = _20_ else end
 if config.enable_hotpot_diagnostics then
 local _let_22_ = require("hotpot.api.diagnostics") local enable = _let_22_["enable"]
 return enable() else return nil end end

 return set_lazy_proxy({setup = setup}, {api = "hotpot.api", runtime = "hotpot.runtime"})
