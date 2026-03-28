local function pack(...)
  local tmp_9_ = {...}
  tmp_9_["n"] = select("#", ...)
  return tmp_9_
end
local function file_mtime(path)
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/util.fnl:8", 2)
  else
  end
  local case_2_, case_3_ = vim.uv.fs_stat(path)
  if ((_G.type(case_2_) == "table") and ((_G.type(case_2_.mtime) == "table") and (nil ~= case_2_.mtime.sec) and (nil ~= case_2_.mtime.nsec))) then
    local sec = case_2_.mtime.sec
    local nsec = case_2_.mtime.nsec
    local function _4_(this, other)
      return ((sec == other.sec) and (nsec == other.nsec))
    end
    local function _5_(this, other)
      return ((other.sec < sec) or ((other.sec == sec) and (other.nsec < nsec)))
    end
    local function _6_(this, other)
      return ((sec < other.sec) or ((sec == other.sec) and (nsec < other.nsec)))
    end
    return {["equal?"] = _4_, ["after?"] = _5_, ["before?"] = _6_, path = path, sec = sec, nsec = nsec}
  elseif ((case_2_ == nil) and (nil ~= case_3_)) then
    local err = case_3_
    return nil
  else
    return nil
  end
end
local function file_read(path)
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/util.fnl:23", 2)
  else
  end
  local fh = assert(io.open(path, "r"), ("read io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _10_()
    return fh:read("*a")
  end
  local _12_
  do
    local t_11_ = _G
    if (nil ~= t_11_) then
      t_11_ = t_11_.package
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.loaded
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.fennel
    else
    end
    _12_ = t_11_
  end
  local or_16_ = _12_ or _G.debug
  if not or_16_ then
    local function _17_()
      return ""
    end
    or_16_ = {traceback = _17_}
  end
  return close_handlers_13_(_G.xpcall(_10_, or_16_.traceback))
end
local function file_write(path, lines)
  if (nil == lines) then
    _G.error("Missing argument lines on fnl/hotpot/util.fnl:27", 2)
  else
  end
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/util.fnl:27", 2)
  else
  end
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("write io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _21_()
    return fh:write(lines)
  end
  local _23_
  do
    local t_22_ = _G
    if (nil ~= t_22_) then
      t_22_ = t_22_.package
    else
    end
    if (nil ~= t_22_) then
      t_22_ = t_22_.loaded
    else
    end
    if (nil ~= t_22_) then
      t_22_ = t_22_.fennel
    else
    end
    _23_ = t_22_
  end
  local or_27_ = _23_ or _G.debug
  if not or_27_ then
    local function _28_()
      return ""
    end
    or_27_ = {traceback = _28_}
  end
  return close_handlers_13_(_G.xpcall(_21_, or_27_.traceback))
end
local function nest(t, namespace)
  local function _29_(t0, key)
    local lowkey = string.lower(key)
    local case_30_ = rawget(t0, lowkey)
    if (nil ~= case_30_) then
      local mod = case_30_
      return mod
    elseif (case_30_ == nil) then
      local modname = (namespace .. "." .. lowkey)
      local mod = require(modname)
      t0[lowkey] = mod
      local case_31_ = type(mod)
      if (case_31_ == "table") then
        return nest(mod, modname)
      else
        local _ = case_31_
        return mod
      end
    else
      return nil
    end
  end
  return setmetatable(t, {__index = _29_})
end
local R = nest({}, "hotpot")
local function notify_error(msg, ...)
  if (nil == msg) then
    _G.error("Missing argument msg on fnl/hotpot/util.fnl:52", 2)
  else
  end
  return vim.notify(string.format(msg, ...), vim.log.levels.ERROR)
end
local function notify_warn(msg, ...)
  if (nil == msg) then
    _G.error("Missing argument msg on fnl/hotpot/util.fnl:53", 2)
  else
  end
  return vim.notify(string.format(msg, ...), vim.log.levels.WARN)
end
local function notify_info(msg, ...)
  if (nil == msg) then
    _G.error("Missing argument msg on fnl/hotpot/util.fnl:54", 2)
  else
  end
  return vim.notify(string.format(msg, ...), vim.log.levels.INFO)
end
return {["notify-error"] = notify_error, ["notify-warn"] = notify_warn, ["notify-info"] = notify_info, ["file-read"] = file_read, ["file-write"] = file_write, ["file-mtime"] = file_mtime, pack = pack, R = R}