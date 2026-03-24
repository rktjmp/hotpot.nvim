local uv = vim.loop
local function read_file_21(path)
  local fh = assert(io.open(path, "r"), ("fs.read-file! io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
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
  return close_handlers_13_(_G.xpcall(_2_, or_8_.traceback))
end
local function write_file_21(path, lines)
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
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
  return close_handlers_13_(_G.xpcall(_11_, or_17_.traceback))
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
  local mtime = _let_20_.mtime
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
  if (nil == head) then
    _G.error("Missing argument head on fnl/hotpot/fs.fnl:33", 2)
  else
  end
  local function _23_(...)
    local t = head
    for _, part in ipairs({...}) do
      t = (t .. "/" .. part)
    end
    return t
  end
  return vim.fs.normalize(_23_(...))
end
local function what_is_at(path)
  local case_24_, case_25_, case_26_ = uv.fs_stat(path)
  if ((_G.type(case_24_) == "table") and (nil ~= case_24_.type)) then
    local type = case_24_.type
    return type
  elseif ((case_24_ == nil) and true and (case_26_ == "ENOENT")) then
    local _ = case_25_
    return "nothing"
  elseif ((case_24_ == nil) and (nil ~= case_25_) and true) then
    local err = case_25_
    local _ = case_26_
    return nil, string.format("uv.fs_stat error %s", err)
  else
    return nil
  end
end
local function make_path(path)
  local path0 = vim.fs.normalize(path)
  local backwards, _here = string.match(path0, string.format("(.+)%s(.+)$", "/"))
  local case_28_ = what_is_at(path0)
  if (case_28_ == "directory") then
    return true
  elseif (case_28_ == "nothing") then
    assert(make_path(backwards))
    return assert(uv.fs_mkdir(path0, 493))
  elseif (nil ~= case_28_) then
    local other = case_28_
    return error(string.format("could not create path because %s exists at %s", other, path0))
  else
    return nil
  end
end
local function rm_file(path)
  local case_30_, case_31_ = uv.fs_unlink(path)
  if (case_30_ == true) then
    return true
  elseif ((case_30_ == nil) and (nil ~= case_31_)) then
    local e = case_31_
    return false, e
  else
    return nil
  end
end
local function copy_file(from, to)
  local function _33_(...)
    local case_34_, case_35_ = ...
    if (nil ~= case_34_) then
      local dir = case_34_
      local function _36_(...)
        local case_37_, case_38_ = ...
        if (case_37_ == true) then
          local function _39_(...)
            local case_40_, case_41_ = ...
            if (case_40_ == true) then
              return true
            elseif ((case_40_ == nil) and (nil ~= case_41_)) then
              local e = case_41_
              return false, e
            else
              return nil
            end
          end
          return _39_(uv.fs_copyfile(from, to))
        elseif ((case_37_ == nil) and (nil ~= case_38_)) then
          local e = case_38_
          return false, e
        else
          return nil
        end
      end
      return _36_(make_path(dir))
    elseif ((case_34_ == nil) and (nil ~= case_35_)) then
      local e = case_35_
      return false, e
    else
      return nil
    end
  end
  return _33_(vim.fs.dirname(to))
end
return {["read-file!"] = read_file_21, ["write-file!"] = write_file_21, ["file-exists?"] = file_exists_3f, ["file-missing?"] = file_missing_3f, ["file-mtime"] = file_mtime, ["file-stat"] = file_stat, ["is-lua-path?"] = is_lua_path_3f, ["is-fnl-path?"] = is_fnl_path_3f, ["join-path"] = join_path, ["make-path"] = make_path, ["rm-file"] = rm_file, ["copy-file"] = copy_file}