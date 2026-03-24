local uv = (vim.uv or vim.loop)
local function _2_(...)
  local case_1_ = vim.health
  if ((_G.type(case_1_) == "table") and (nil ~= case_1_.ok) and (nil ~= case_1_.info) and (nil ~= case_1_.error) and (nil ~= case_1_.start) and (nil ~= case_1_.warn)) then
    local ok = case_1_.ok
    local info = case_1_.info
    local error = case_1_.error
    local start = case_1_.start
    local warn = case_1_.warn
    return {report_start = start, report_warn = warn, report_info = info, report_error = error, report_ok = ok}
  elseif (nil ~= case_1_) then
    local other = case_1_
    return other
  else
    return nil
  end
end
local _local_4_ = _2_(...)
local report_start = _local_4_.report_start
local report_info = _local_4_.report_info
local report_ok = _local_4_.report_ok
local report_error = _local_4_.report_error
local report_warn = _local_4_.report_warn
local function fmt(s, ...)
  return string.format(s, ...)
end
local function bytes__3ehuman(bytes)
  local function f(b)
    return (b / 1024)
  end
  local function _5_(...)
    local and_6_ = ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2]))
    if and_6_ then
      local bytes0 = (...)[1]
      local unit = (...)[2]
      and_6_ = (1023 < bytes0)
    end
    if and_6_ then
      local bytes0 = (...)[1]
      local unit = (...)[2]
      local function _8_(...)
        local and_9_ = ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2]))
        if and_9_ then
          local kbytes = (...)[1]
          local unit0 = (...)[2]
          and_9_ = (1023 < kbytes)
        end
        if and_9_ then
          local kbytes = (...)[1]
          local unit0 = (...)[2]
          local function _11_(...)
            local and_12_ = ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2]))
            if and_12_ then
              local mbytes = (...)[1]
              local unit1 = (...)[2]
              and_12_ = (1023 < mbytes)
            end
            if and_12_ then
              local mbytes = (...)[1]
              local unit1 = (...)[2]
              local function _14_(...)
                if ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2])) then
                  local gbytes = (...)[1]
                  local unit2 = (...)[2]
                  return fmt(unit2, gbytes)
                elseif ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2])) then
                  local size = (...)[1]
                  local unit2 = (...)[2]
                  return fmt(unit2, size)
                else
                  return nil
                end
              end
              return _14_({f(mbytes), "%.2fbg"})
            elseif ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2])) then
              local size = (...)[1]
              local unit1 = (...)[2]
              return fmt(unit1, size)
            else
              return nil
            end
          end
          return _11_({f(kbytes), "%.2fmb"})
        elseif ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2])) then
          local size = (...)[1]
          local unit0 = (...)[2]
          return fmt(unit0, size)
        else
          return nil
        end
      end
      return _8_({f(bytes0), "%dkb"})
    elseif ((_G.type(...) == "table") and (nil ~= (...)[1]) and (nil ~= (...)[2])) then
      local size = (...)[1]
      local unit = (...)[2]
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
  local function _19_()
    local size0 = 0
    for _, p in ipairs(paths) do
      local _21_
      do
        local t_20_ = uv.fs_stat(p)
        if (nil ~= t_20_) then
          t_20_ = t_20_.size
        else
        end
        _21_ = t_20_
      end
      size0 = (size0 + (_21_ or 0))
    end
    return size0
  end
  size = bytes__3ehuman(_19_())
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %s", count, size))
end
local function log_report()
  report_start("Hotpot Log")
  local logger = require("hotpot.logger")
  local path = logger.path()
  local size
  do
    local case_23_ = uv.fs_stat(path)
    if (case_23_ == nil) then
      size = 0
    elseif ((_G.type(case_23_) == "table") and (nil ~= case_23_.size)) then
      local size0 = case_23_.size
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
    local function _26_()
      print("hi")
      ok_3f = true
      return nil
    end
    package.preload[modname] = _26_
    package.loaded[modname] = nil
    do
      local case_27_, case_28_ = pcall(func, "hotpot-health-preload-check")
      if ((case_27_ == true) and (nil ~= case_28_)) then
        local f = case_28_
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
    local case_31_ = find_searcher_index(luarocks_searcher)
    if (case_31_ == 1) then
      report_ok("Luarocks package.loader index: 1")
    elseif (nil ~= case_31_) then
      local n = case_31_
      report_warn(fmt("Luarocks package.loader index: %s, expected 1", n))
    else
    end
  end
  local case_33_ = find_searcher_index(hotpot_searcher)
  if (case_33_ == 2) then
    return report_ok(fmt("Hotpot package.loader index: %s", 2))
  elseif (case_33_ == 3) then
    return check_searcher_preload_then_hotpot(2, 3)
  elseif (nil ~= case_33_) then
    local n = case_33_
    return report_error(fmt("Hotpot package.loader index: %s, expected 2 or 3 when using luarocks.", n))
  else
    return nil
  end
end
local function searcher_report_when_normal(hotpot_searcher)
  local case_35_ = find_searcher_index(hotpot_searcher)
  if (case_35_ == 2) then
    return check_searcher_preload_then_hotpot(1, 2)
  elseif (nil ~= case_35_) then
    local n = case_35_
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
  local _let_39_ = require("hotpot.loader")
  local hotpot_searcher = _let_39_.searcher
  local case_40_ = package.loaded["luarocks.loader"]
  if ((_G.type(case_40_) == "table") and (nil ~= case_40_.luarocks_loader)) then
    local luarocks_searcher = case_40_.luarocks_loader
    return searcher_report_when_luarocks(hotpot_searcher, luarocks_searcher)
  else
    local _ = case_40_
    return searcher_report_when_normal(hotpot_searcher)
  end
end
local function check()
  disk_report()
  log_report()
  return searcher_report()
end
return {check = check}