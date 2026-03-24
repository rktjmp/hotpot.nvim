local methods = {}
methods.compile = function(ctx, options)
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/aot/api/context.fnl:5", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/aot/api/context.fnl:5", 2)
  else
  end
  return nil
end
local function create(_3fpath_to_hotpot_fnl_or_nil)
  local ctx = {}
  return setmetatable(ctx, methods)
end
return create