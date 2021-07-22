 local _local_0_ = require("hotpot.fs") local file_exists_3f = _local_0_["file-exists?"]

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

 return {["locate-module"] = locate_module}
