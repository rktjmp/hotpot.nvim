 local uv = vim.loop





 local function require_fennel()
 return require("hotpot.fennel") end

 local function fennel_version()
 return require_fennel().version end

 local function file_exists_3f(path)
 return uv.fs_access(path, "R") end

 local function file_missing_3f(path)
 return not file_exists_3f(path) end

 local function search_rtp(partial_path)




 local found = nil
 local paths = {("lua/" .. partial_path .. ".fnl"), ("lua/" .. partial_path .. "/init.fnl")}

 for _, path in ipairs(paths) do if found then break end
 local _0_ = vim.api.nvim_get_runtime_file(path, false) if ((type(_0_) == "table") and (nil ~= (_0_)[1])) then local path_23 = (_0_)[1]
 found = path_23 elseif (_0_ == nil) then end end

 return found end

 local function search_package_path(partial_path)


 local templates = (package.path .. ";")

 local found = nil
 for template in string.gmatch(templates, "(.-);") do if found then break end
 local full_path local function _0_(...) return string.gsub(template, "%?", ...) end

 full_path = string.gsub(_0_(partial_path), "%.lua$", ".fnl")
 if file_exists_3f(full_path) then
 found = full_path end end
 return found end

 local function locate_module(modname)


 local partial_path = string.gsub(modname, "%.", "/")
 local _0_ = search_rtp(partial_path) if (nil ~= _0_) then local path_23 = _0_
 return path_23 elseif (_0_ == nil) then
 return search_package_path(partial_path) end end

 local function fnl_path_to_compiled_path(path, prefix) local function _0_(...) return (prefix .. ...) end











 return string.gsub(_0_(uv.fs_realpath(path)), "%.fnl$", ".lua") end

 local function file_stale_3f(newer, older)


 return (uv.fs_stat(newer).mtime.sec > uv.fs_stat(older).mtime.sec) end

 local function needs_compilation_3f(fnl_path, lua_path)
 return (file_missing_3f(lua_path) or file_stale_3f(fnl_path, lua_path)) end

 local function compile_string(string, options)



 local fennel = require_fennel()
 local function compile()
 return fennel["compile-string"](string, (otions or {})) end
 return xpcall(compile, fennel.traceback) end

 local function maybe_compile(fnl_path, lua_path)
 local _0_ = needs_compilation_3f(fnl_path, lua_path) if (_0_ == false) then
 return lua_path elseif (_0_ == true) then



 vim.fn.mkdir(string.match(lua_path, "(.+)/.-%.lua"), "p")
 local fnl_in = io.open(fnl_path, "r") local lua_out = io.open(lua_path, "w") local function close_handlers_0_(ok_0_, ...) lua_out:close() fnl_in:close() if ok_0_ then return ... else return error(..., 0) end end local function _1_() local lines = fnl_in:read("*a")

 local _2_, _3_ = compile_string(lines, {correlate = true, filename = fnl_path}) if ((_2_ == true) and (nil ~= _3_)) then local code = _3_ lua_out:write(code)



 return lua_path elseif ((_2_ == false) and (nil ~= _3_)) then local errors = _3_

 os.remove(lua_path)
 vim.api.nvim_err_write(errors)
 return ("Compilation failure for " .. fnl_path) end end return close_handlers_0_(xpcall(_1_, (package.loaded.fennel or debug).traceback)) end end


 local function create_loader(path)
 local function _0_(modname)
 return dofile(path) end return _0_ end

 local function searcher(config, modname)






 local _0_ = locate_module(modname) if (nil ~= _0_) then local fnl_path = _0_


 local lua_path = fnl_path_to_compiled_path(fnl_path, config.prefix)

 maybe_compile(fnl_path, lua_path)
 return create_loader(lua_path) elseif (_0_ == nil) then


 return nil end end

 local function default_config()
 return {prefix = (vim.fn.stdpath("cache") .. "/hotpot/")} end local has_setup = false


 local function setup() if not has_setup then

 local config = default_config() local function _0_(...) return searcher(config, ...) end
 table.insert(package.loaders, 1, _0_) has_setup = true
 return nil end end

 local function print_compiled(ok, result)
 local _0_ = {ok, result} if ((type(_0_) == "table") and ((_0_)[1] == true) and (nil ~= (_0_)[2])) then local code = (_0_)[2]
 return print(code) elseif ((type(_0_) == "table") and ((_0_)[1] == false) and (nil ~= (_0_)[2])) then local error = (_0_)[2]
 return vim.api.nvim_err_write(errors) end end

 local function show_buf(buf)
 local lines = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false))


 return print_compiled(compile_string(lines, {filename = "hotpot-show"})) end

 local function show_selection()
 local _let_0_ = vim.fn.getpos("'<") local buf = _let_0_[1] local from = _let_0_[2]
 local _let_1_ = vim.fn.getpos("'>") local _ = _let_1_[1] local to = _let_1_[2]
 local lines = vim.api.nvim_buf_get_lines(buf, (from - 1), to, false)
 local lines0 = table.concat(lines)


 return print_compiled(compile_string(lines0, {filename = "hotpot-show"})) end

 return {compile_string = compile_string, fennel = require_fennel, fennel_version = fennel_version, searcher = searcher, setup = setup, show_buf = show_buf, show_selection = show_selection}
