local function pack(...)
  local tmp_9_ = {...}
  tmp_9_["n"] = select("#", ...)
  return tmp_9_
end
local function nest(t, namespace)
  local function _1_(t0, key)
    local lowkey = string.lower(key)
    local case_2_ = rawget(t0, lowkey)
    if (nil ~= case_2_) then
      local mod = case_2_
      return mod
    elseif (case_2_ == nil) then
      local modname = (namespace .. "." .. lowkey)
      local mod = require(modname)
      t0[lowkey] = mod
      local case_3_ = type(mod)
      if (case_3_ == "table") then
        return nest(mod, modname)
      else
        local _ = case_3_
        return mod
      end
    else
      return nil
    end
  end
  return setmetatable(t, {__index = _1_})
end
local R = nest({}, "hotpot")
return {pack = pack, R = R}