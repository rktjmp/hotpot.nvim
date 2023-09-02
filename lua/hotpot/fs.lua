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
local path_sep = string.match(package.config, "(.-)\n")
local function path_separator()
  return path_sep
end
local function join_path(head, ...)
  _G.assert((nil ~= head), "Missing argument head on fnl/hotpot/fs.fnl:51")
  local path_sep0 = path_separator()
  local dup_pat = ("[" .. path_sep0 .. "]+")
  local joined
  do
    local t = head
    for _, part in ipairs({...}) do
      t = (t .. path_separator() .. part)
    end
    joined = t
  end
  local de_duped = string.gsub(joined, dup_pat, path_sep0)
  return de_duped
end
local function dirname(path)
  local pattern = string.format("%s[^%s]+$", path_sep, path_sep)
  local _8_ = string.find(path, pattern)
  if (_8_ == nil) then
    return error(("Could not extract dirname from path: " .. path))
  elseif (nil ~= _8_) then
    local n = _8_
    return string.sub(path, 1, n)
  else
    return nil
  end
end
local function what_is_at(path)
  local _10_, _11_, _12_ = uv.fs_stat(path)
  if ((_G.type(_10_) == "table") and (nil ~= (_10_).type)) then
    local type = (_10_).type
    return type
  elseif ((_10_ == nil) and true and (_12_ == "ENOENT")) then
    local _ = _11_
    return "nothing"
  elseif ((_10_ == nil) and (nil ~= _11_) and true) then
    local err = _11_
    local _ = _12_
    return nil, string.format("uv.fs_stat error %s", err)
  else
    return nil
  end
end
local function make_path(path)
  local backwards, _here = string.match(path, string.format("(.+)%s(.+)$", path_sep))
  local _14_ = what_is_at(path)
  if (_14_ == "directory") then
    return true
  elseif (_14_ == "nothing") then
    assert(make_path(backwards))
    return assert(uv.fs_mkdir(path, 493))
  elseif (nil ~= _14_) then
    local other = _14_
    return error(string.format("could not create path because %s exists at %s", other, path))
  else
    return nil
  end
end
local function rm_file(path)
  local _16_, _17_ = uv.fs_unlink(path)
  if (_16_ == true) then
    return true
  elseif ((_16_ == nil) and (nil ~= _17_)) then
    local e = _17_
    return false, e
  else
    return nil
  end
end
local function copy_file(from, to)
  local function _19_(...)
    local _20_, _21_ = ...
    if (nil ~= _20_) then
      local dir = _20_
      local function _22_(...)
        local _23_, _24_ = ...
        if (_23_ == true) then
          local function _25_(...)
            local _26_, _27_ = ...
            if (_26_ == true) then
              return true
            elseif ((_26_ == nil) and (nil ~= _27_)) then
              local e = _27_
              return false, e
            else
              return nil
            end
          end
          return _25_(uv.fs_copyfile(from, to))
        elseif ((_23_ == nil) and (nil ~= _24_)) then
          local e = _24_
          return false, e
        else
          return nil
        end
      end
      return _22_(make_path(dir))
    elseif ((_20_ == nil) and (nil ~= _21_)) then
      local e = _21_
      return false, e
    else
      return nil
    end
  end
  return _19_(dirname(to))
end
local function normalise_path(path)
  return vim.fs.normalize(path, {expand_env = false})
end
return {["read-file!"] = read_file_21, ["write-file!"] = write_file_21, ["file-exists?"] = file_exists_3f, ["file-missing?"] = file_missing_3f, ["file-mtime"] = file_mtime, ["file-stat"] = file_stat, ["is-lua-path?"] = is_lua_path_3f, ["is-fnl-path?"] = is_fnl_path_3f, ["join-path"] = join_path, ["make-path"] = make_path, dirname = dirname, ["path-separator"] = path_separator, ["rm-file"] = rm_file, ["copy-file"] = copy_file, ["normalise-path"] = normalise_path}