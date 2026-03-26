local M, m = {}, {}
local function bind_compile(ctx)
  local Context = require("hotpot.context")
  local function _1_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    return pcall(Context.compile, ctx, source, {filename = "--hotpot-api-compile"})
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
    return pcall(Context.eval, ctx, source, {filename = "--hotpot-api-eval"})
  end
  return _3_
end
local function bind_sync(ctx)
  local Context = require("hotpot.context")
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _5_(options)
      if (nil == options) then
        _G.error("Missing argument options on fnl/hotpot/api.fnl:17", 2)
      else
      end
      return pcall(Context.sync, ctx, options)
    end
    return _5_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx), transform = ctx}
  if ctx.path then
    base.path = {source = ctx.source, destination = ctx.destination}
    return nil
  else
    return nil
  end
end
M.context = function(_3fpath)
  local Context = require("hotpot.context")
  local case_9_, case_10_ = pcall(Context.new, _3fpath)
  if ((case_9_ == true) and (nil ~= case_10_)) then
    local ctx = case_10_
    return bind_context(ctx)
  elseif ((case_9_ == false) and (nil ~= case_10_)) then
    local err = case_10_
    return nil, err
  else
    return nil
  end
end
return M.context