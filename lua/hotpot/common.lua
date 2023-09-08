local function inspect(...)
  local _let_1_ = require("hotpot.fennel")
  local view = _let_1_["view"]
  print(view({...}))
  return ...
end
local function set_lazy_proxy(t, lookup)
  for k, _ in pairs(lookup) do
    t[("__" .. k)] = string.format("lazy loaded on %s key access", k)
  end
  local function __index(t0, k)
    local mod
    do
      local _2_ = lookup[k]
      if (nil ~= _2_) then
        mod = require(_2_)
      else
        mod = _2_
      end
    end
    if mod then
      t0[k] = mod
      t0[("__" .. k)] = nil
      return mod
    else
      return nil
    end
  end
  return setmetatable(t, {__index = __index})
end
local function put_new(t, k, v)
  if (nil == t[k]) then
    t[k] = v
    return t
  else
    return t
  end
end
local function any_3f(f, seq)
  local x = false
  for _, v in ipairs(seq) do
    if x then break end
    if f(v) then
      x = true
    else
      x = false
    end
  end
  return x
end
local function none_3f(f, seq)
  return not any_3f(f, seq)
end
local function map(f, seq)
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, v in ipairs(seq) do
    local val_19_auto = f(v)
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function filter(f, seq)
  local function _8_(_241)
    if f(_241) then
      return _241
    else
      return nil
    end
  end
  return map(_8_, seq)
end
local function string_3f(x)
  return ("string" == type(x))
end
local function boolean_3f(x)
  return ("boolean" == type(x))
end
local function table_3f(x)
  return ("table" == type(x))
end
local function nil_3f(x)
  return (nil == x)
end
local function function_3f(x)
  return ("function" == type(x))
end
return {fmt = string.format, inspect = inspect, ["set-lazy-proxy"] = set_lazy_proxy, ["put-new"] = put_new, map = map, filter = filter, ["any?"] = any_3f, ["none?"] = none_3f, ["string?"] = string_3f, ["boolean?"] = boolean_3f, ["function?"] = function_3f, ["table?"] = table_3f, ["nil?"] = nil_3f}