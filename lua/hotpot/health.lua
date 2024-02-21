local uv = (vim.uv or vim.loop)
local _local_1_ = vim.health
local report_start = _local_1_["report_start"]
local report_info = _local_1_["report_info"]
local function fmt(s, ...)
  return string.format(s, ...)
end
local function disk_info()
  report_start("Hotpot Data")
  local runtime = require("hotpot.runtime")
  local config = runtime["user-config"]()
  local cache_root = runtime["cache-root-path"]()
  local paths = vim.fn.globpath(cache_root, "**", true, true, true)
  local count = #paths
  local size
  do
    local size0 = 0
    for _, p in ipairs(paths) do
      local function _2_(...)
        local t_3_ = uv.fs_stat(p)
        if (nil ~= t_3_) then
          t_3_ = t_3_.size
        else
        end
        return t_3_
      end
      size0 = (size0 + _2_() + 0)
    end
    size = size0
  end
  local size0 = math.floor((size / 1024))
  report_info(fmt("Cache root path: %s", cache_root))
  return report_info(fmt("Cache size: %s files, %skb", count, size0))
end
local function check()
  return disk_info()
end
return {check = check}