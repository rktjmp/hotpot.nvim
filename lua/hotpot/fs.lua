local uv = vim.loop
local function read_file_21(path)
  local fh = assert(io.open(path, "r"), ("fs.read-file! io.open failed:" .. path))
  local function close_handlers_10_auto(ok_11_auto, ...)
    fh:close()
    if ok_11_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _2_()
    return fh:read("*a")
  end
  return close_handlers_10_auto(_G.xpcall(_2_, (package.loaded.fennel or debug).traceback))
end
local function write_file_21(path, lines)
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
  local function close_handlers_10_auto(ok_11_auto, ...)
    fh:close()
    if ok_11_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _4_()
    return fh:write(lines)
  end
  return close_handlers_10_auto(_G.xpcall(_4_, (package.loaded.fennel or debug).traceback))
end
local function is_lua_path_3f(path)
  return (path and (nil ~= string.match(path, "%.lua$")))
end
local function is_fnl_path_3f(path)
  return (path and (nil ~= string.match(path, "%.fnl$")))
end
local function file_exists_3f(path)
  return uv.fs_access(path, "R")
end
local function file_missing_3f(path)
  return not file_exists_3f(path)
end
local function file_mtime(path)
  if not file_exists_3f(path) then
    local failed_what_1_auto = "(file-exists? path)"
    local err_2_auto = string.format("%s [failed: %s]", "cant check mtime of %s, does not exist", failed_what_1_auto)
    error(string.format(err_2_auto, path), 0)
  else
  end
  local _let_6_ = uv.fs_stat(path)
  local mtime = _let_6_["mtime"]
  return mtime.sec
end
local function file_stat(path)
  if not file_exists_3f(path) then
    local failed_what_1_auto = "(file-exists? path)"
    local err_2_auto = string.format("%s [failed: %s]", "cant check hash of %s, does not exist", failed_what_1_auto)
    error(string.format(err_2_auto, path), 0)
  else
  end
  return uv.fs_stat(path)
end
local function join_path(head, ...)
  _G.assert((nil ~= head), "Missing argument head on fnl/hotpot/fs.fnl:33")
  local function _8_(...)
    local t = head
    for _, part in ipairs({...}) do
      t = (t .. "/" .. part)
    end
    return t
  end
  return vim.fs.normalize(_8_(...))
end
local function what_is_at(path)
  local _9_, _10_, _11_ = uv.fs_stat(path)
  if ((_G.type(_9_) == "table") and (nil ~= _9_.type)) then
    local type = _9_.type
    return type
  elseif ((_9_ == nil) and true and (_11_ == "ENOENT")) then
    local _ = _10_
    return "nothing"
  elseif ((_9_ == nil) and (nil ~= _10_) and true) then
    local err = _10_
    local _ = _11_
    return nil, string.format("uv.fs_stat error %s", err)
  else
    return nil
  end
end
local function make_path(path)
  local path0 = vim.fs.normalize(path)
  local backwards, _here = string.match(path0, string.format("(.+)%s(.+)$", "/"))
  local _13_ = what_is_at(path0)
  if (_13_ == "directory") then
    return true
  elseif (_13_ == "nothing") then
    assert(make_path(backwards))
    return assert(uv.fs_mkdir(path0, 493))
  elseif (nil ~= _13_) then
    local other = _13_
    return error(string.format("could not create path because %s exists at %s", other, path0))
  else
    return nil
  end
end
local function rm_file(path)
  local _15_, _16_ = uv.fs_unlink(path)
  if (_15_ == true) then
    return true
  elseif ((_15_ == nil) and (nil ~= _16_)) then
    local e = _16_
    return false, e
  else
    return nil
  end
end
local function copy_file(from, to)
  local function _18_(...)
    local _19_, _20_ = ...
    if (nil ~= _19_) then
      local dir = _19_
      local function _21_(...)
        local _22_, _23_ = ...
        if (_22_ == true) then
          local function _24_(...)
            local _25_, _26_ = ...
            if (_25_ == true) then
              return true
            elseif ((_25_ == nil) and (nil ~= _26_)) then
              local e = _26_
              return false, e
            else
              return nil
            end
          end
          return _24_(uv.fs_copyfile(from, to))
        elseif ((_22_ == nil) and (nil ~= _23_)) then
          local e = _23_
          return false, e
        else
          return nil
        end
      end
      return _21_(make_path(dir))
    elseif ((_19_ == nil) and (nil ~= _20_)) then
      local e = _20_
      return false, e
    else
      return nil
    end
  end
  return _18_(vim.fs.dirname(to))
end
return {["read-file!"] = read_file_21, ["write-file!"] = write_file_21, ["file-exists?"] = file_exists_3f, ["file-missing?"] = file_missing_3f, ["file-mtime"] = file_mtime, ["file-stat"] = file_stat, ["is-lua-path?"] = is_lua_path_3f, ["is-fnl-path?"] = is_fnl_path_3f, ["join-path"] = join_path, ["make-path"] = make_path, ["rm-file"] = rm_file, ["copy-file"] = copy_file}