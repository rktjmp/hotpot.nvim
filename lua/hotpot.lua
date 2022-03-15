 assert((1 == vim.fn.has("nvim-0.6")), "Hotpot requires neovim 0.6+")

 local uv = vim.loop


 local path_sep = string.match(package.config, "(.-)\n")
 local function path_separator() return path_sep end
 local function join_path(head, ...) _G.assert((nil ~= head), "Missing argument head on fnl/hotpot.fnl:8")
 local t = head for _, part in ipairs({...}) do
 t = (t .. path_separator() .. part) end return t end

 local function canary_link_path(lua_dir)
 return join_path(lua_dir, "canary") end

 local function canary_valid_3f(canary_link_dir)






 local _1_, _2_ = uv.fs_realpath(canary_link_path(canary_link_dir)) if ((_1_ == nil) and (nil ~= _2_)) then local err = _2_ return false elseif (nil ~= _1_) then local path = _1_ return true else return nil end end



 local function canary_path(fnl_dir)

 local canary_folder = join_path(fnl_dir, "..", "canary")
 local handle = uv.fs_opendir(canary_folder, nil, 1)
 local files = uv.fs_readdir(handle)
 local _ = uv.fs_closedir(handle)
 local canary_name = files[1].name
 return join_path(canary_folder, canary_name) end

 local function make_canary(fnl_dir, lua_dir)

 local current_canary_path = canary_path(fnl_dir)
 local canary_link_from = canary_link_path(lua_dir)
 uv.fs_unlink(canary_link_from)
 return uv.fs_symlink(current_canary_path, canary_link_from) end

 local function load_hotpot(cache_dir, fnl_dir)



 local hotpot = require("hotpot.runtime")
 hotpot.install()
 do end (hotpot)["install"] = nil
 hotpot["uninstall"] = nil
 return hotpot end
















 local function bootstrap_compile(fnl_dir, lua_dir)
 local function compile_file(fnl_src, lua_dest)

 local _let_4_ = require("hotpot.fennel") local compile_string = _let_4_["compile-string"]
 local fnl_file = io.open(fnl_src)
 local lua_file = io.open(lua_dest, "w") local function close_handlers_8_auto(ok_9_auto, ...) lua_file:close() fnl_file:close() if ok_9_auto then return ... else return error(..., 0) end end local function _6_() local fnl_code = fnl_file:read("*a")

 local lua_code = compile_string(fnl_code, {filename = fnl_src, correlate = true}) return lua_file:write(lua_code) end return close_handlers_8_auto(_G.xpcall(_6_, (package.loaded.fennel or debug).traceback)) end



 local function compile_dir(fennel, in_dir, out_dir)


 local scanner = uv.fs_scandir(in_dir)
 local function _7_() return uv.fs_scandir_next(scanner) end for name, type in _7_ do
 local _8_ = type if (_8_ == "directory") then

 local in_down = join_path(in_dir, name)
 local out_down = join_path(out_dir, name)
 vim.fn.mkdir(out_down, "p")
 compile_dir(fennel, in_down, out_down) elseif (_8_ == "file") then

 local in_file = join_path(in_dir, name)
 local out_name = string.gsub(name, ".fnl$", ".lua")
 local out_file = join_path(out_dir, out_name)
 if not ((name == "macros.fnl") or (name == "hotpot.fnl")) then

 compile_file(in_file, out_file) else end else end end return nil end

 do local fnl_dir_search_path = join_path(fnl_dir, "?.fnl")
 local fennel = require("hotpot.fennel")
 local saved = {path = fennel.path, ["macro-path"] = fennel["macro-path"]}


 fennel.path = (fnl_dir_search_path .. ";" .. fennel.path)
 fennel["macro-path"] = (fnl_dir_search_path .. ";" .. fennel.path)
 table.insert(package.loaders, fennel.searcher)

 compile_dir(fennel, fnl_dir, lua_dir)

 fennel.path = saved.path
 fennel["macro-path"] = saved["macro-path"]
 do local done = nil for i, check in ipairs(package.loaders) do if done then break end
 if (check == fennel.searcher) then
 done = table.remove(package.loaders, i) else done = nil end end end

 make_canary(fnl_dir, lua_dir) end

 do local cache_dir = join_path(vim.fn.stdpath("cache"), "hotpot")
 vim.fn.mkdir(cache_dir, "p") end
 return true end



 local hotpot_dot_lua = join_path("lua", "hotpot.lua")
 local lop = (-1 * (1 + #hotpot_dot_lua))




 local hotpot_rtp_path = string.sub(uv.fs_realpath(vim.api.nvim_get_runtime_file(hotpot_dot_lua, false)[1]), 1, lop)
 local hotpot_fnl_dir = join_path(hotpot_rtp_path, "fnl")
 local hotpot_lua_dir = join_path(hotpot_rtp_path, "lua")
 local _12_ = canary_valid_3f(hotpot_lua_dir) if (_12_ == true) then
 return load_hotpot(hotpot_lua_dir, hotpot_fnl_dir) elseif (_12_ == false) then

 bootstrap_compile(hotpot_fnl_dir, hotpot_lua_dir)
 return load_hotpot(hotpot_lua_dir, hotpot_fnl_dir) else return nil end
