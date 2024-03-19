local M = {}
local PID = vim.fn.getpid()
local _2apath_2a = vim.fs.normalize(string.format("%s/%s", vim.fn.stdpath("log"), "hotpot.log"))
local function view(x)
  local _1_, _2_ = pcall(require, "fennel")
  if ((_1_ == true) and ((_G.type(_2_) == "table") and (nil ~= _2_.view))) then
    local view0 = _2_.view
    return view0(x)
  elseif ((_1_ == false) and true) then
    local _ = _2_
    return vim.inspect(x)
  else
    return nil
  end
end
local _2alog_fd_2a = nil
local function open(path)
  if not _2alog_fd_2a then
    local _4_, _5_ = io.open(path, "a")
    if (nil ~= _4_) then
      local fd = _4_
      fd:setvbuf("line")
      _2alog_fd_2a = fd
    elseif ((_4_ == nil) and (nil ~= _5_)) then
      local e = _5_
      error(e)
    else
    end
  else
  end
  return _2alog_fd_2a
end
local function write(...)
  local fd = open(_2apath_2a())
  fd:write(...)
  return nil
end
local function expand_string(msg, ...)
  local vargs = {...}
  local n = select("#", ...)
  local details
  do
    local tbl_19_auto = {}
    local i_20_auto = 0
    for i = 1, n do
      local val_21_auto
      do
        local v = vargs[i]
        local _8_ = type(v)
        if (_8_ == "string") then
          val_21_auto = v
        else
          local _ = _8_
          val_21_auto = view(v)
        end
      end
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    details = tbl_19_auto
  end
  return string.format(msg, unpack(details))
end
local function msg__3elogline(msg)
  return ("(" .. PID .. ") " .. os.date("%FT%T%z") .. ": " .. msg .. "\n")
end
M.path = function()
  return _2apath_2a
end
M.info = function(msg, ...)
  local msg0
  do
    local _11_ = type(msg)
    if (_11_ == "string") then
      msg0 = expand_string(msg, ...)
    else
      local _ = _11_
      msg0 = view(msg)
    end
  end
  return write(msg__3elogline(msg0))
end
return M