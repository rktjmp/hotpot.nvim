



 package.preload["hotpot.bootstrap"] = package.preload["hotpot.bootstrap"] or function(...) local uv = vim.loop local path_separator = string.match(package.config, "(.-)\n") local function join_path(head, ...) _G.assert((nil ~= head), "Missing argument head on fnl/hotpot/bootstrap.fnl:5") local t = head for _, part in ipairs({...}) do t = (t .. path_separator .. part) end return t end local function new_canary(hotpot_dir, lua_dir) local canary_in_repo do local canary_folder = join_path(hotpot_dir, "canary") local handle = uv.fs_opendir(canary_folder, nil, 1) local files = uv.fs_readdir(handle) local _ = uv.fs_closedir(handle) local _let_1_ = files local _let_2_ = _let_1_[1] local name = _let_2_["name"] canary_in_repo = join_path(canary_folder, name) end local canary_in_build = join_path(lua_dir, "canary") return {["canary-in-repo"] = canary_in_repo, ["canary-in-build"] = canary_in_build} end local function canary_valid_3f(_3_) local _arg_4_ = _3_ local canary_in_build = _arg_4_["canary-in-build"] local _5_, _6_ = uv.fs_realpath(canary_in_build) if ((_5_ == nil) and (nil ~= _6_)) then local err = _6_ return false elseif (nil ~= _5_) then local path = _5_ return true else return nil end end local function create_canary_link(_8_) local _arg_9_ = _8_ local canary_in_build = _arg_9_["canary-in-build"] local canary_in_repo = _arg_9_["canary-in-repo"] uv.fs_unlink(canary_in_build) return assert(uv.fs_symlink(canary_in_repo, canary_in_build), "could not create canary symlink") end local function compile_hotpot(fnl_dir, lua_dir) local function compile_file(fnl_src, lua_dest) local _let_10_ = require("hotpot.fennel") local compile_string = _let_10_["compile-string"] local fnl_file = io.open(fnl_src) local lua_file = io.open(lua_dest, "w") local function close_handlers_8_auto(ok_9_auto, ...) lua_file:close() fnl_file:close() if ok_9_auto then return ... else return error(..., 0) end end local function _12_() local fnl_code = fnl_file:read("*a") local lua_code = compile_string(fnl_code, {filename = fnl_src, correlate = true}) return lua_file:write(lua_code) end return close_handlers_8_auto(_G.xpcall(_12_, (package.loaded.fennel or debug).traceback)) end local function compile_dir(in_dir, out_dir) local scanner = uv.fs_scandir(in_dir) local function _13_() return uv.fs_scandir_next(scanner) end for name, kind in _13_ do local _14_ = kind if (_14_ == "directory") then local in_down = join_path(in_dir, name) local out_down = join_path(out_dir, name) vim.fn.mkdir(out_down, "p") compile_dir(in_down, out_down) elseif (_14_ == "file") then local in_file = join_path(in_dir, name) local out_name = string.gsub(name, ".fnl$", ".lua") local out_file = join_path(out_dir, out_name) if not ((name == "macros.fnl") or (name == "hotpot.fnl")) then compile_file(in_file, out_file) else end else end end return nil end do local fennel = require("hotpot.fennel") local saved = {["macro-path"] = fennel["macro-path"]} local fnl_dir_search_path = join_path(fnl_dir, "?.fnl") fennel["macro-path"] = (fnl_dir_search_path .. ";" .. fennel["macro-path"]) compile_dir(fnl_dir, lua_dir) fennel["macro-path"] = saved["macro-path"] end vim.fn.mkdir(join_path(vim.fn.stdpath("cache"), "hotpot"), "p") return true end local function bootstrap() local hotpot_dir = string.match((debug.getinfo(1, "S")).source, "@(.+)..?lua..?hotpot%.lua$") local fnl_dir = join_path(hotpot_dir, "fnl") local lua_dir do local ideal_path = join_path(hotpot_dir, "lua") if uv.fs_access(ideal_path, "W") then lua_dir = ideal_path else local cache_dir = vim.fn.stdpath("cache") local build_to_cache_dir = join_path(cache_dir, "hotpot", "hotpot.nvim", "lua") local search_path = join_path(build_to_cache_dir, "?.lua;") vim.fn.mkdir(build_to_cache_dir, "p") do end (package)["path"] = (search_path .. package.path) lua_dir = build_to_cache_dir end end local canary = new_canary(hotpot_dir, lua_dir) if not canary_valid_3f(canary) then compile_hotpot(fnl_dir, lua_dir) return create_canary_link(canary) else return nil end end return bootstrap end assert((1 == vim.fn.has("nvim-0.6")), "Hotpot requires neovim 0.6+") require("hotpot.bootstrap")()

 local function install()
 local _let_19_ = require("hotpot.index") local new_index = _let_19_["new-index"] local new_indexed_searcher_fn = _let_19_["new-indexed-searcher-fn"]
 local _let_20_ = require("hotpot.fs") local join_path = _let_20_["join-path"]
 local runtime = require("hotpot.runtime")
 local index_path = join_path(vim.fn.stdpath("cache"), "hotpot", "index.bin")
 local index = new_index(index_path)
 local searcher = new_indexed_searcher_fn(index)
 table.insert(package.loaders, 1, searcher)
 return runtime.update("index", index) end

 local function setup(options)
 local runtime = require("hotpot.runtime")
 return runtime.update("config", options) end


 install()


 local _let_21_ = require("hotpot.common") local set_lazy_proxy = _let_21_["set-lazy-proxy"]
 return set_lazy_proxy({setup = setup}, {api = "hotpot.api", runtime = "hotpot.runtime"})
