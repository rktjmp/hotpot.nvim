local uv = (vim.uv or vim.loop)
local function _2_(...)
  local _1_ = vim.health
  if ((_G.type(_1_) == "table") and (nil ~= _1_.ok) and (nil ~= _1_.info) and (nil ~= _1_.error) and (nil ~= _1_.start) and (nil ~= _1_.warn)) then
    local ok = _1_.ok
    local info = _1_.info
    local error = _1_.error
    local start = _1_.start
    local warn = _1_.warn
    return {report_start = start, report_warn = warn, report_info = info, report_error = error, report_ok = ok}
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
local report_warn = _local_4_["report_warn"]
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
local function disk_report()
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
      size0 = (size0 + (_25_ or 0))
    end
    return size0
  end
  size = bytes__3ehuman(_23_())
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %s", count, size))
end
local function log_report()
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
local function find_searcher_index(searcher)
  local x = nil
  for i, v in ipairs(package.loaders) do
    if x then break end
    if (searcher == v) then
      x = i
    else
      x = nil
    end
  end
  return x
end
local function check_searcher_preload_then_hotpot(preloader_index, hotpot_index)
  local function loader_func_is_preload_loader_3f(func)
    local ok_3f = false
    local modname = "hotpot-health-preload-check"
    local function _30_()
      print("hi")
      ok_3f = true
      return nil
    end
    package.preload[modname] = _30_
    package.loaded[modname] = nil
    do
      local _31_, _32_ = pcall(func, "hotpot-health-preload-check")
      if ((_31_ == true) and (nil ~= _32_)) then
        local f = _32_
        f()
      else
      end
    end
    package.preload[modname] = nil
    package.loaded[modname] = nil
    return ok_3f
  end
  if loader_func_is_preload_loader_3f(package.loaders[preloader_index]) then
    report_ok(fmt("Preload package.loader index: %s", preloader_index))
    report_ok(fmt("Hotpot package.loader index: %s", hotpot_index))
    return true
  else
    report_warn(fmt("Unknown package.loader index: %s, may or may not interfere with Hotpot.", preloader_index))
    report_warn(fmt("Hotpot package.loader index: %s", hotpot_index))
    return false
  end
end
local function searcher_report_when_luarocks(hotpot_searcher, luarocks_searcher)
  report_info("Luarocks.loader is present.")
  do
    local _35_ = find_searcher_index(luarocks_searcher)
    if (_35_ == 1) then
      report_ok("Luarocks package.loader index: 1")
    elseif (nil ~= _35_) then
      local n = _35_
      report_warn(fmt("Luarocks package.loader index: %s, expected 1", n))
    else
    end
  end
  local _37_ = find_searcher_index(hotpot_searcher)
  if (_37_ == 2) then
    return report_ok(fmt("Hotpot package.loader index: %s", 2))
  elseif (_37_ == 3) then
    return check_searcher_preload_then_hotpot(2, 3)
  elseif (nil ~= _37_) then
    local n = _37_
    return report_error(fmt("Hotpot package.loader index: %s, expected 2 or 3 when using luarocks.", n))
  else
    return nil
  end
end
local function searcher_report_when_normal(hotpot_searcher)
  local _39_ = find_searcher_index(hotpot_searcher)
  if (_39_ == 2) then
    return check_searcher_preload_then_hotpot(1, 2)
  elseif (nil ~= _39_) then
    local n = _39_
    report_error(fmt("Hotpot package.loader index: %s, expected 2.", n))
    if vim.loader.enabled then
      return report_info(fmt("Ensure you are calling `vim.loader.enable()` before `require('hotpot')`"))
    else
      return nil
    end
  else
    return nil
  end
end
local function searcher_report()
  report_start("Hotpot Module Searcher")
  if vim.loader.enabled then
    report_info("vim.loader is enabled.")
  else
  end
  local _let_43_ = require("hotpot.loader")
  local hotpot_searcher = _let_43_["searcher"]
  local _44_ = package.loaded["luarocks.loader"]
  if ((_G.type(_44_) == "table") and (nil ~= _44_.luarocks_loader)) then
    local luarocks_searcher = _44_.luarocks_loader
    return searcher_report_when_luarocks(hotpot_searcher, luarocks_searcher)
  else
    local _ = _44_
    return searcher_report_when_normal(hotpot_searcher)
  end
end
local function check()
  disk_report()
  log_report()
  return searcher_report()
end
return {check = check}