local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local M, m = {}, {}
local function bind_compile(ctx)
  local function _2_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    local case_4_, case_5_ = pcall(R.context["compile-string"], ctx, source, {filename = "--hotpot-api-compile"})
    if ((case_4_ == true) and (nil ~= case_5_)) then
      local lua_code = case_5_
      return lua_code
    elseif ((case_4_ == false) and (nil ~= case_5_)) then
      local err = case_5_
      return nil, err
    else
      return nil
    end
  end
  return _2_
end
local function bind_eval(ctx)
  local function _7_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:11", 2)
    else
    end
    local case_9_ = R.util.pack(pcall(R.context["eval-string"], ctx, source, {filename = "--hotpot-api-eval"}))
    if ((_G.type(case_9_) == "table") and (case_9_[1] == true)) then
      local returns = case_9_
      return unpack(returns, 2, returns.n)
    elseif ((_G.type(case_9_) == "table") and (case_9_[1] == false) and (nil ~= case_9_[2])) then
      local err = case_9_[2]
      return nil, err
    else
      return nil
    end
  end
  return _7_
end
local function bind_sync(ctx)
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _11_(_3foptions)
      return pcall(R.context.sync, ctx, _3foptions)
    end
    return _11_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx)}
  if ctx.transform then
    local function _13_(source, _3ffilename)
      if (nil == source) then
        _G.error("Missing argument source on fnl/hotpot/api.fnl:29", 2)
      else
      end
      return ctx.transform(source, (_3ffilename or "--hotpot-api-transform"))
    end
    base.transform = _13_
  else
  end
  local _17_
  do
    local t_16_ = ctx
    if (nil ~= t_16_) then
      t_16_ = t_16_.path
    else
    end
    if (nil ~= t_16_) then
      t_16_ = t_16_.source
    else
    end
    _17_ = t_16_
  end
  if _17_ then
    base.path = {source = ctx.path.source, destination = ctx.path.dest}
  else
  end
  return base
end
M.context = function(_3fpath)
  local case_21_, case_22_ = pcall(R.context.new, _3fpath)
  if ((case_21_ == true) and (nil ~= case_22_)) then
    local ctx = case_22_
    return bind_context(ctx)
  elseif ((case_21_ == false) and (nil ~= case_22_)) then
    local err = case_22_
    return nil, err
  else
    return nil
  end
end
return M