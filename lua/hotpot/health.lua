local uv = (vim.uv or vim.loop)
local _local_1_ = vim.health
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
  local function _2_(...)
    local _3_ = ...
    local function _4_(...)
      local bytes0 = _3_[1]
      local unit = _3_[2]
      return (1023 < bytes0)
    end
    if (((_G.type(_3_) == "table") and (nil ~= _3_[1]) and (nil ~= _3_[2])) and _4_(...)) then
      local bytes0 = _3_[1]
      local unit = _3_[2]
      local function _5_(...)
        local _6_ = ...
        local function _7_(...)
          local kbytes = _6_[1]
          local unit0 = _6_[2]
          return (1023 < kbytes)
        end
        if (((_G.type(_6_) == "table") and (nil ~= _6_[1]) and (nil ~= _6_[2])) and _7_(...)) then
          local kbytes = _6_[1]
          local unit0 = _6_[2]
          local function _8_(...)
            local _9_ = ...
            local function _10_(...)
              local mbytes = _9_[1]
              local unit1 = _9_[2]
              return (1023 < mbytes)
            end
            if (((_G.type(_9_) == "table") and (nil ~= _9_[1]) and (nil ~= _9_[2])) and _10_(...)) then
              local mbytes = _9_[1]
              local unit1 = _9_[2]
              local function _11_(...)
                local _12_ = ...
                if ((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) then
                  local gbytes = _12_[1]
                  local unit2 = _12_[2]
                  return fmt(unit2, gbytes)
                elseif ((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) then
                  local size = _12_[1]
                  local unit2 = _12_[2]
                  return fmt(unit2, size)
                else
                  return nil
                end
              end
              return _11_({f(mbytes), "%.2fbg"})
            elseif ((_G.type(_9_) == "table") and (nil ~= _9_[1]) and (nil ~= _9_[2])) then
              local size = _9_[1]
              local unit1 = _9_[2]
              return fmt(unit1, size)
            else
              return nil
            end
          end
          return _8_({f(kbytes), "%.2fmb"})
        elseif ((_G.type(_6_) == "table") and (nil ~= _6_[1]) and (nil ~= _6_[2])) then
          local size = _6_[1]
          local unit0 = _6_[2]
          return fmt(unit0, size)
        else
          return nil
        end
      end
      return _5_({f(bytes0), "%dkb"})
    elseif ((_G.type(_3_) == "table") and (nil ~= _3_[1]) and (nil ~= _3_[2])) then
      local size = _3_[1]
      local unit = _3_[2]
      return fmt(unit, size)
    else
      return nil
    end
  end
  return _2_({bytes, "%db"})
end
local function disk_info()
  report_start("Hotpot Cache Data")
  local runtime = require("hotpot.runtime")
  local config = runtime["user-config"]()
  local cache_root = runtime["cache-root-path"]()
  local paths = vim.fn.globpath(cache_root, "**", true, true, true)
  local count = #paths
  local size
  local function _17_()
    local size0 = 0
    for _, p in ipairs(paths) do
      local function _18_(...)
        local t_19_ = uv.fs_stat(p)
        if (nil ~= t_19_) then
          t_19_ = t_19_.size
        else
        end
        return t_19_
      end
      size0 = (size0 + _18_() + 0)
    end
    return size0
  end
  size = bytes__3ehuman(_17_())
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %s", count, size))
end
local function log_info()
  report_start("Hotpot Log")
  local logger = require("hotpot.logger")
  local path = logger.path()
  local size
  do
    local _21_ = uv.fs_stat(path)
    if (_21_ == nil) then
      size = 0
    elseif ((_G.type(_21_) == "table") and (nil ~= _21_.size)) then
      local size0 = _21_.size
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
  local _let_23_ = require("hotpot.loader")
  local searcher = _let_23_["searcher"]
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