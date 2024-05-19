local uv = (vim.uv or vim.loop)
local function _3_(...)
  local _2_ = vim.health
  if ((_G.type(_2_) == "table") and (nil ~= _2_.ok) and (nil ~= _2_.info) and (nil ~= _2_.error) and (nil ~= _2_.start)) then
    local ok = _2_.ok
    local info = _2_.info
    local error = _2_.error
    local start = _2_.start
    return {report_start = start, report_info = info, report_error = error, report_ok = ok}
  elseif (nil ~= _2_) then
    local other = _2_
    return other
  else
    return nil
  end
end
local _local_1_ = _3_(...)
local report_start = _local_1_["report_start"]
local report_info = _local_1_["report_info"]
local report_ok = _local_1_["report_ok"]
local report_error = _local_1_["report_error"]
local function fmt(s, ...)
  return string.format(s, ...)
end
local function bytes__3ehuman(bytes)
  local function f(b)
    return (b / 1024)
  end
  local function _5_(...)
    local _6_ = ...
    local function _7_(...)
      local bytes0 = _6_[1]
      local unit = _6_[2]
      return (1023 < bytes0)
    end
    if (((_G.type(_6_) == "table") and (nil ~= _6_[1]) and (nil ~= _6_[2])) and _7_(...)) then
      local bytes0 = _6_[1]
      local unit = _6_[2]
      local function _8_(...)
        local _9_ = ...
        local function _10_(...)
          local kbytes = _9_[1]
          local unit0 = _9_[2]
          return (1023 < kbytes)
        end
        if (((_G.type(_9_) == "table") and (nil ~= _9_[1]) and (nil ~= _9_[2])) and _10_(...)) then
          local kbytes = _9_[1]
          local unit0 = _9_[2]
          local function _11_(...)
            local _12_ = ...
            local function _13_(...)
              local mbytes = _12_[1]
              local unit1 = _12_[2]
              return (1023 < mbytes)
            end
            if (((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) and _13_(...)) then
              local mbytes = _12_[1]
              local unit1 = _12_[2]
              local function _14_(...)
                local _15_ = ...
                if ((_G.type(_15_) == "table") and (nil ~= _15_[1]) and (nil ~= _15_[2])) then
                  local gbytes = _15_[1]
                  local unit2 = _15_[2]
                  return fmt(unit2, gbytes)
                elseif ((_G.type(_15_) == "table") and (nil ~= _15_[1]) and (nil ~= _15_[2])) then
                  local size = _15_[1]
                  local unit2 = _15_[2]
                  return fmt(unit2, size)
                else
                  return nil
                end
              end
              return _14_({f(mbytes), "%.2fbg"})
            elseif ((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) then
              local size = _12_[1]
              local unit1 = _12_[2]
              return fmt(unit1, size)
            else
              return nil
            end
          end
          return _11_({f(kbytes), "%.2fmb"})
        elseif ((_G.type(_9_) == "table") and (nil ~= _9_[1]) and (nil ~= _9_[2])) then
          local size = _9_[1]
          local unit0 = _9_[2]
          return fmt(unit0, size)
        else
          return nil
        end
      end
      return _8_({f(bytes0), "%dkb"})
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
  local function _20_()
    local size0 = 0
    for _, p in ipairs(paths) do
      local function _21_(...)
        local t_22_ = uv.fs_stat(p)
        if (nil ~= t_22_) then
          t_22_ = t_22_.size
        else
        end
        return t_22_
      end
      size0 = (size0 + _21_() + 0)
    end
    return size0
  end
  size = bytes__3ehuman(_20_())
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %s", count, size))
end
local function log_info()
  report_start("Hotpot Log")
  local logger = require("hotpot.logger")
  local path = logger.path()
  local size
  do
    local _24_ = uv.fs_stat(path)
    if (_24_ == nil) then
      size = 0
    elseif ((_G.type(_24_) == "table") and (nil ~= _24_.size)) then
      local size0 = _24_.size
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
  local _let_26_ = require("hotpot.loader")
  local searcher = _let_26_["searcher"]
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