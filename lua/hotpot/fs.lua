 local uv = vim.loop

 local function read_file(path)
 local fh = io.open(path, "r") local function close_handlers_0_(ok_0_, ...) fh:close() if ok_0_ then return ... else return error(..., 0) end end local function _0_() return fh:read("*a") end return close_handlers_0_(xpcall(_0_, (package.loaded.fennel or debug).traceback)) end


 local function write_file(path, lines)
 local fh = io.open(path, "w") local function close_handlers_0_(ok_0_, ...) fh:close() if ok_0_ then return ... else return error(..., 0) end end local function _0_() return fh:write(lines) end return close_handlers_0_(xpcall(_0_, (package.loaded.fennel or debug).traceback)) end


 local function file_exists_3f(path)
 return uv.fs_access(path, "R") end

 local function file_missing_3f(path)
 return not file_exists_3f(path) end

 local function file_stale_3f(newer, older)


 return (uv.fs_stat(newer).mtime.sec > uv.fs_stat(older).mtime.sec) end

 return {["file-exists?"] = file_exists_3f, ["file-missing?"] = file_missing_3f, ["file-stale?"] = file_stale_3f, ["read-file"] = read_file, ["write-file"] = write_file}
