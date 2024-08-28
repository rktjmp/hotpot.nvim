local uv = (vim.uv or vim.loop)
local function _2_(...)
  local _1_ = vim.health
  if ((_G.type(_1_) == "table") and (nil ~= _1_.ok) and (nil ~= _1_.info) and (nil ~= _1_.error) and (nil ~= _1_.start)) then
    local ok = _1_.ok
    local info = _1_.info
    local error = _1_.error
    local start = _1_.start
    return {report_start = start, report_info = info, report_error = error, report_ok = ok}
  elseif (nil ~= _1_) then
    local other = _1_
    return other
  else
    return nil
  end
end
local _local_4_ = _2_(...)
local report_start = _local_4_["report_start"]
local report_info = _local_4_["report_info"]
local report_ok = _local_4_["report_ok"]
local report_error = _local_4_["report_error"]
local function fmt(s, ...)
  return string.format(s, ...)
end
local function bytes__3ehuman(bytes)
  local function f(b)
    return (b / 1024)
  end
  local function _5_(...)
    local _6_ = ...
    local and_7_ = ((_G.type(_6_) == "table") and (nil ~= _6_[1]) and (nil ~= _6_[2]))
    if and_7_ then
      local bytes0 = _6_[1]
      local unit = _6_[2]
      and_7_ = (1023 < bytes0)
    end
    if and_7_ then
      local bytes0 = _6_[1]
      local unit = _6_[2]
      local function _9_(...)
        local _10_ = ...
        local and_11_ = ((_G.type(_10_) == "table") and (nil ~= _10_[1]) and (nil ~= _10_[2]))
        if and_11_ then
          local kbytes = _10_[1]
          local unit0 = _10_[2]
          and_11_ = (1023 < kbytes)
        end
        if and_11_ then
          local kbytes = _10_[1]
          local unit0 = _10_[2]
          local function _13_(...)
            local _14_ = ...
            local and_15_ = ((_G.type(_14_) == "table") and (nil ~= _14_[1]) and (nil ~= _14_[2]))
            if and_15_ then
              local mbytes = _14_[1]
              local unit1 = _14_[2]
              and_15_ = (1023 < mbytes)
            end
            if and_15_ then
              local mbytes = _14_[1]
              local unit1 = _14_[2]
              local function _17_(...)
                local _18_ = ...
                if ((_G.type(_18_) == "table") and (nil ~= _18_[1]) and (nil ~= _18_[2])) then
                  local gbytes = _18_[1]
                  local unit2 = _18_[2]
                  return fmt(unit2, gbytes)
                elseif ((_G.type(_18_) == "table") and (nil ~= _18_[1]) and (nil ~= _18_[2])) then
                  local size = _18_[1]
                  local unit2 = _18_[2]
                  return fmt(unit2, size)
                else
                  return nil
                end
              end
              return _17_({f(mbytes), "%.2fbg"})
            elseif ((_G.type(_14_) == "table") and (nil ~= _14_[1]) and (nil ~= _14_[2])) then
              local size = _14_[1]
              local unit1 = _14_[2]
              return fmt(unit1, size)
            else
              return nil
            end
          end
          return _13_({f(kbytes), "%.2fmb"})
        elseif ((_G.type(_10_) == "table") and (nil ~= _10_[1]) and (nil ~= _10_[2])) then
          local size = _10_[1]
          local unit0 = _10_[2]
          return fmt(unit0, size)
        else
          return nil
        end
      end
      return _9_({f(bytes0), "%dkb"})
    elseif ((_G.type(_6_) == "table") and (nil ~= _6_[1]) and (nil ~= _6_[2])) then
      local size = _6_[1]
      local unit = _6_[2]
      return fmt(unit, size)
    else
      return nil
    end
  end
  return _5_({bytes, "%db"})
end
local function disk_info()
  report_start("Hotpot Cache Data")
  local runtime = require("hotpot.runtime")
  local config = runtime["user-config"]()
  local cache_root = runtime["cache-root-path"]()
  local paths = vim.fn.globpath(cache_root, "**", true, true, true)
  local count = #paths
  local size
  local function _23_()
    local size0 = 0
    for _, p in ipairs(paths) do
      local _25_
      do
        local t_24_ = uv.fs_stat(p)
        if (nil ~= t_24_) then
          t_24_ = t_24_.size
        else
        end
        _25_ = t_24_
      end
      size0 = (size0 + _25_ + 0)
    end
    return size0
  end
  size = bytes__3ehuman(_23_())
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %s", count, size))
end
local function log_info()
  report_start("Hotpot Log")
  local logger = require("hotpot.logger")
  local path = logger.path()
  local size
  do
    local _27_ = uv.fs_stat(path)
    if (_27_ == nil) then
      size = 0
    elseif ((_G.type(_27_) == "table") and (nil ~= _27_.size)) then
      local size0 = _27_.size
      size = bytes__3ehuman(size0)
    else
      size = nil
    end
  end
  report_info(fmt("Log path: %s", path))
  return report_info(fmt("Log size: %s", size))
end
local function searcher_info()
  report_start("Hotpot Module Searcher")
  local _let_29_ = require("hotpot.loader")
  local searcher = _let_29_["searcher"]
  local expected_index = 2
  local actual_index
  do
    local x = nil
    for i, v in ipairs(package.loaders) do
      if x then break end
      if (searcher == v) then
        x = i
      else
        x = nil
      end
    end
    actual_index = x
  end
  if (expected_index == actual_index) then
    return report_ok(fmt("package.loader index: %s", actual_index))
  else
    report_error(fmt("package.loader index: %s, requires: %s", actual_index, expected_index))
    if vim.loader.enabled then
      return report_info(fmt("Ensure you are calling `vim.loader.enable()` before `require('hotpot')`"))
    else
      return nil
    end
  end
end
local function check()
  disk_info()
  log_info()
  return searcher_info()
end
return {check = check}