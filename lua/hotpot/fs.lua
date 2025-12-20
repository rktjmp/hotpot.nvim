local uv = vim.loop
local function read_file_21(path)
  local fh = assert(io.open(path, "r"), ("fs.read-file! io.open failed:" .. path))
  local function close_handlers_12_(ok_13_, ...)
    fh:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _2_()
    return fh:read("*a")
  end
  local _4_
  do
    local t_3_ = _G
    if (nil ~= t_3_) then
      t_3_ = t_3_.package
    else
    end
    if (nil ~= t_3_) then
      t_3_ = t_3_.loaded
    else
    end
    if (nil ~= t_3_) then
      t_3_ = t_3_.fennel
    else
    end
    _4_ = t_3_
  end
  local or_8_ = _4_ or _G.debug
  if not or_8_ then
    local function _9_()
      return ""
    end
    or_8_ = {traceback = _9_}
  end
  return close_handlers_12_(_G.xpcall(_2_, or_8_.traceback))
end
local function write_file_21(path, lines)
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
  local function close_handlers_12_(ok_13_, ...)
    fh:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _11_()
    return fh:write(lines)
  end
  local _13_
  do
    local t_12_ = _G
    if (nil ~= t_12_) then
      t_12_ = t_12_.package
    else
    end
    if (nil ~= t_12_) then
      t_12_ = t_12_.loaded
    else
    end
    if (nil ~= t_12_) then
      t_12_ = t_12_.fennel
    else
    end
    _13_ = t_12_
  end
  local or_17_ = _13_ or _G.debug
  if not or_17_ then
    local function _18_()
      return ""
    end
    or_17_ = {traceback = _18_}
  end
  return close_handlers_12_(_G.xpcall(_11_, or_17_.traceback))
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
  local _let_20_ = uv.fs_stat(path)
  local mtime = _let_20_["mtime"]
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
  local function _22_(...)
    local t = head
    for _, part in ipairs({...}) do
      t = (t .. "/" .. part)
    end
    return t
  end
  return vim.fs.normalize(_22_(...))
end
local function what_is_at(path)
  local _23_, _24_, _25_ = uv.fs_stat(path)
  if ((_G.type(_23_) == "table") and (nil ~= _23_.type)) then
    local type = _23_.type
    return type
  elseif ((_23_ == nil) and true and (_25_ == "ENOENT")) then
    local _ = _24_
    return "nothing"
  elseif ((_23_ == nil) and (nil ~= _24_) and true) then
    local err = _24_
    local _ = _25_
    return nil, string.format("uv.fs_stat error %s", err)
  else
    return nil
  end
end
local function make_path(path)
  local path0 = vim.fs.normalize(path)
  local backwards, _here = string.match(path0, string.format("(.+)%s(.+)$", "/"))
  local _27_ = what_is_at(path0)
  if (_27_ == "directory") then
    return true
  elseif (_27_ == "nothing") then
    assert(make_path(backwards))
    return assert(uv.fs_mkdir(path0, 493))
  elseif (nil ~= _27_) then
    local other = _27_
    return error(string.format("could not create path because %s exists at %s", other, path0))
  else
    return nil
  end
end
local function rm_file(path)
  local _29_, _30_ = uv.fs_unlink(path)
  if (_29_ == true) then
    return true
  elseif ((_29_ == nil) and (nil ~= _30_)) then
    local e = _30_
    return false, e
  else
    return nil
  end
end
local function copy_file(from, to)
  local function _32_(...)
    local _33_, _34_ = ...
    if (nil ~= _33_) then
      local dir = _33_
      local function _35_(...)
        local _36_, _37_ = ...
        if (_36_ == true) then
          local function _38_(...)
            local _39_, _40_ = ...
            if (_39_ == true) then
              return true
            elseif ((_39_ == nil) and (nil ~= _40_)) then
              local e = _40_
              return false, e
            else
              return nil
            end
          end
          return _38_(uv.fs_copyfile(from, to))
        elseif ((_36_ == nil) and (nil ~= _37_)) then
          local e = _37_
          return false, e
        else
          return nil
        end
      end
      return _35_(make_path(dir))
    elseif ((_33_ == nil) and (nil ~= _34_)) then
      local e = _34_
      return false, e
    else
      return nil
    end
  end
  return _32_(vim.fs.dirname(to))
end
return {["read-file!"] = read_file_21, ["write-file!"] = write_file_21, ["file-exists?"] = file_exists_3f, ["file-missing?"] = file_missing_3f, ["file-mtime"] = file_mtime, ["file-stat"] = file_stat, ["is-lua-path?"] = is_lua_path_3f, ["is-fnl-path?"] = is_fnl_path_3f, ["join-path"] = join_path, ["make-path"] = make_path, ["rm-file"] = rm_file, ["copy-file"] = copy_file}