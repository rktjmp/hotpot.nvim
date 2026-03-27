local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local M, m = {}, {}
local function bind_compile(ctx)
  local function _2_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    return pcall(R.context["compile-string"], ctx, source, {filename = "--hotpot-api-compile"})
  end
  return _2_
end
local function bind_eval(ctx)
  local function _4_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:9", 2)
    else
    end
    return pcall(R.context["eval-string"], ctx, source, {filename = "--hotpot-api-eval"})
  end
  return _4_
end
local function bind_sync(ctx)
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _6_(_3foptions)
      return pcall(R.context.sync, ctx, _3foptions)
    end
    return _6_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx)}
  if ctx.transform then
    local function _8_(source, _3ffilename)
      if (nil == source) then
        _G.error("Missing argument source on fnl/hotpot/api.fnl:25", 2)
      else
      end
      return ctx.transform(source, (_3ffilename or "--hotpot-api-transform"))
    end
    base.transform = _8_
  else
  end
  local _12_
  do
    local t_11_ = ctx
    if (nil ~= t_11_) then
      t_11_ = t_11_.path
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.source
    else
    end
    _12_ = t_11_
  end
  if _12_ then
    base.path = {source = ctx.path.source, destination = ctx.path.dest}
  else
  end
  return base
end
M.context = function(_3fpath)
  local case_16_, case_17_ = pcall(R.context.new, _3fpath)
  if ((case_16_ == true) and (nil ~= case_17_)) then
    local ctx = case_17_
    return bind_context(ctx)
  elseif ((case_16_ == false) and (nil ~= case_17_)) then
    local err = case_17_
    return nil, err
  else
    return nil
  end
end
return M