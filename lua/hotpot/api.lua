local M, m = {}, {}
local function bind_compile(ctx)
  local Context = require("hotpot.context")
  local function _1_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    return pcall(Context["compile-string"], ctx, source, {filename = "--hotpot-api-compile"})
  end
  return _1_
end
local function bind_eval(ctx)
  local Context = require("hotpot.context")
  local function _3_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:10", 2)
    else
    end
    return pcall(Context["eval-string"], ctx, source, {filename = "--hotpot-api-eval"})
  end
  return _3_
end
local function bind_sync(ctx)
  local Context = require("hotpot.context")
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _5_(_3foptions)
      return pcall(Context.sync, ctx, _3foptions)
    end
    return _5_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx), transform = ctx.transform}
  if ctx.path then
    base.path = {source = ctx.path.source, destination = ctx.path.dest}
  else
  end
  return base
end
M.context = function(_3fpath)
  local Context = require("hotpot.context")
  local case_8_, case_9_ = pcall(Context.new, _3fpath)
  if ((case_8_ == true) and (nil ~= case_9_)) then
    local ctx = case_9_
    return bind_context(ctx)
  elseif ((case_8_ == false) and (nil ~= case_9_)) then
    local err = case_9_
    return nil, err
  else
    return nil
  end
end
return M