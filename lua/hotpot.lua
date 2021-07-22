 local _local_0_ = require("hotpot.compiler") local compile_string = _local_0_["compile-string"]
 local module_searcher = require("hotpot.searcher.module")

 local function default_config()
 return {prefix = (vim.fn.stdpath("cache") .. "/hotpot/")} end local has_run_setup = false


 local function setup() if not has_run_setup then

 local config = default_config() local function _0_(...) return module_searcher(config, ...) end
 table.insert(package.loaders, 1, _0_) has_run_setup = true
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



 local function _0_() return __fnl_global__require_2dfennel() end local function _1_() return (__fnl_global__require_2dfennel()).version end return {compile_string = compile_string, fennel = _0_, fennel_version = _1_, setup = setup, show_buf = show_buf, show_selection = show_selection}
