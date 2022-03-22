
 assert((1 == vim.fn.has("nvim-0.6")), "Hotpot requires neovim 0.6+")
 local uv = vim.loop


 local path_separator = string.match(package.config, "(.-)\n")
 local function join_path(head, ...) _G.assert((nil ~= head), "Missing argument head on fnl/hotpot.fnl:7")
 local t = head for _, part in ipairs({...}) do
 t = (t .. path_separator .. part) end return t end

 local function new_canary(hotpot_dir)




 local repo_canary do local canary_folder = join_path(hotpot_dir, "canary")
 local handle = uv.fs_opendir(canary_folder, nil, 1)
 local files = uv.fs_readdir(handle)
 local _ = uv.fs_closedir(handle)
 local _let_1_ = files local _let_2_ = _let_1_[1] local name = _let_2_["name"]
 repo_canary = join_path(canary_folder, name) end
 local build_canary = join_path(hotpot_dir, "lua", "canary")
 return {["repo-canary"] = repo_canary, ["build-canary"] = build_canary} end


 local function canary_valid_3f(_3_) local _arg_4_ = _3_ local build_canary = _arg_4_["build-canary"]


 local _5_, _6_ = uv.fs_realpath(build_canary) if ((_5_ == nil) and (nil ~= _6_)) then local err = _6_ return false elseif (nil ~= _5_) then local path = _5_ return true else return nil end end



 local function create_canary_link(_8_) local _arg_9_ = _8_ local build_canary = _arg_9_["build-canary"] local repo_canary = _arg_9_["repo-canary"]

 uv.fs_unlink(build_canary)
 return uv.fs_symlink(repo_canary, build_canary) end

 local function load_hotpot()
 local hotpot = require("hotpot.runtime")
 hotpot.install()

 do end (hotpot)["install"] = nil
 return hotpot end

 local function compile_hotpot(hotpot_dir)
 local function compile_file(fnl_src, lua_dest)

 local _let_10_ = require("hotpot.fennel") local compile_string = _let_10_["compile-string"]
 local fnl_file = io.open(fnl_src)
 local lua_file = io.open(lua_dest, "w") local function close_handlers_8_auto(ok_9_auto, ...) lua_file:close() fnl_file:close() if ok_9_auto then return ... else return error(..., 0) end end local function _12_() local fnl_code = fnl_file:read("*a")

 local lua_code = compile_string(fnl_code, {filename = fnl_src, correlate = true}) return lua_file:write(lua_code) end return close_handlers_8_auto(_G.xpcall(_12_, (package.loaded.fennel or debug).traceback)) end



 local function compile_dir(in_dir, out_dir)


 local scanner = uv.fs_scandir(in_dir)
 local function _13_() return uv.fs_scandir_next(scanner) end for name, kind in _13_ do
 local _14_ = kind if (_14_ == "directory") then

 local in_down = join_path(in_dir, name)
 local out_down = join_path(out_dir, name)
 vim.fn.mkdir(out_down, "p")
 compile_dir(in_down, out_down) elseif (_14_ == "file") then

 local in_file = join_path(in_dir, name)
 local out_name = string.gsub(name, ".fnl$", ".lua")
 local out_file = join_path(out_dir, out_name)
 if not ((name == "macros.fnl") or (name == "hotpot.fnl")) then

 compile_file(in_file, out_file) else end else end end return nil end

 do local fennel = require("hotpot.fennel")
 local saved = {["macro-path"] = fennel["macro-path"]}
 local fnl_dir = join_path(hotpot_dir, "fnl")
 local lua_dir = join_path(hotpot_dir, "lua")
 local fnl_dir_search_path = join_path(fnl_dir, "?.fnl")

 fennel["macro-path"] = (fnl_dir_search_path .. ";" .. fennel["macro-path"])
 compile_dir(fnl_dir, lua_dir)
 fennel["macro-path"] = saved["macro-path"] end

 do local cache_dir = join_path(vim.fn.stdpath("cache"), "hotpot")
 vim.fn.mkdir(cache_dir, "p") end
 return true end



 local hotpot_dot_lua = join_path("lua", "hotpot.lua")





 local hotpot_dir = string.sub(uv.fs_realpath(vim.api.nvim_get_runtime_file(hotpot_dot_lua, false)[1]), 1, (-1 * #("_" .. hotpot_dot_lua)))
 local canary = new_canary(hotpot_dir)
 if not canary_valid_3f(canary) then
 compile_hotpot(hotpot_dir)
 create_canary_link(canary) else end
 return load_hotpot()
