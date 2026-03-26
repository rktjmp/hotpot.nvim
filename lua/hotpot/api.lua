local M, m = {}, {}
local function bind_compile(ctx)
  local Context = require("hotpot.context")
  local function _1_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    local case_3_, case_4_ = pcall(Context["compile-string"], ctx, source, {filename = "--hotpot-api-compile"})
    if ((case_3_ == true) and (nil ~= case_4_)) then
      local lua_code = case_4_
      return lua_code
    elseif ((case_3_ == false) and (nil ~= case_4_)) then
      local err = case_4_
      return nil, err
    else
      return nil
    end
  end
  return _1_
end
local function bind_eval(ctx)
  local Context = require("hotpot.context")
  local _let_6_ = require("hotpot.util")
  local pack = _let_6_.pack
  local function _7_(source)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:13", 2)
    else
    end
    local case_9_ = pack(pcall(Context["eval-string"], ctx, source, {filename = "--hotpot-api-eval"}))
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
  local Context = require("hotpot.context")
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _11_(_3foptions)
      return pcall(Context.sync, ctx, _3foptions)
    end
    return _11_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx), transform = ctx.transform}
  if ctx.transform then
    local function _13_(source, _3ffilename)
      if (nil == source) then
        _G.error("Missing argument source on fnl/hotpot/api.fnl:33", 2)
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
  local Context = require("hotpot.context")
  local case_21_, case_22_ = pcall(Context.new, _3fpath)
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