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
      local tmp_3_auto = lookup[k]
      if (nil ~= tmp_3_auto) then
        mod = require(tmp_3_auto)
      else
        mod = nil
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
  local tbl_21_auto = {}
  local i_22_auto = 0
  for _, v in ipairs(seq) do
    local val_23_auto = f(v)
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
end
local function reduce(f, acc, seq)
  local acc0 = acc
  for _, v in ipairs(seq) do
    acc0 = f(acc0, v)
  end
  return acc0
end
local function filter(f, seq)
  local function _7_(_241)
    if f(_241) then
      return _241
    else
      return nil
    end
  end
  return map(_7_, seq)
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
return {fmt = string.format, inspect = inspect, ["set-lazy-proxy"] = set_lazy_proxy, ["put-new"] = put_new, map = map, reduce = reduce, filter = filter, ["any?"] = any_3f, ["none?"] = none_3f, ["string?"] = string_3f, ["boolean?"] = boolean_3f, ["function?"] = function_3f, ["table?"] = table_3f, ["nil?"] = nil_3f}