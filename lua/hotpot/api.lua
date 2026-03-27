local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local M, m = {}, {}
local function bind_compile(ctx)
  local function _2_(source, _3foptions)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:5", 2)
    else
    end
    return pcall(R.context["compile-string"], ctx, source, vim.tbl_extend("force", (_3foptions or {}), {filename = "--hotpot-api-compile"}))
  end
  return _2_
end
local function bind_eval(ctx)
  local function _4_(source, _3foptions)
    if (nil == source) then
      _G.error("Missing argument source on fnl/hotpot/api.fnl:13", 2)
    else
    end
    return pcall(R.context["eval-string"], ctx, source, vim.tbl_extend("force", (_3foptions or {}), {filename = "--hotpot-api-eval"}))
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
local function bind_locate(ctx)
  if ((_G.type(ctx) == "table") and (ctx.kind == "api")) then
    return nil
  else
    local _ = ctx
    local function _8_(what)
      if (nil == what) then
        _G.error("Missing argument what on fnl/hotpot/api.fnl:30", 2)
      else
      end
      if (what == "source") then
        return ctx.path.source
      elseif (what == "destination") then
        return ctx.path.dest
      elseif (nil ~= what) then
        local path = what
        local real_path = (vim.uv.fs_realpath(path) or path)
        local _let_10_ = R.const
        local NVIM_CONFIG_ROOT = _let_10_.NVIM_CONFIG_ROOT
        local init_fnl = vim.fs.joinpath(NVIM_CONFIG_ROOT, "init.fnl")
        local init_lua = vim.fs.joinpath(NVIM_CONFIG_ROOT, "init.lua")
        local ext = string.match(real_path, "%.([^%.]+)$")
        local case_11_, case_12_ = real_path, ext
        local and_13_ = (case_11_ == init_fnl)
        if and_13_ then
          and_13_ = _
        end
        if and_13_ then
          return init_lua
        else
          local and_15_ = (case_11_ == init_lua)
          if and_15_ then
            and_15_ = _
          end
          if and_15_ then
            return init_fnl
          elseif (true and (case_12_ == "fnlm")) then
            local _0 = case_11_
            return real_path
          elseif (true and (case_12_ == "fnl")) then
            local _0 = case_11_
            local case_17_ = vim.fs.relpath(ctx.path.source, path)
            if (nil ~= case_17_) then
              local rel_path = case_17_
              local renamed = string.gsub(string.gsub(rel_path, "^fnl/", "lua/"), "%.fnl$", ".lua")
              return vim.fs.joinpath(ctx.path.dest, renamed)
            elseif (case_17_ == nil) then
              return nil, string.format("%s not under context source %s", path, ctx.path.source)
            else
              return nil
            end
          elseif (true and (case_12_ == "lua")) then
            local _0 = case_11_
            local case_19_ = vim.fs.relpath(ctx.path.dest, path)
            if (nil ~= case_19_) then
              local rel_path = case_19_
              local renamed = string.gsub(string.gsub("^lua/", "fnl/"), "%.lua$", ".fnl")
              return vim.fs.joinpath(ctx.path.source, renamed)
            elseif (case_19_ == nil) then
              return nil, string.format("%s not under context destination %s", path, ctx.path.dest)
            else
              return nil
            end
          elseif (true and (nil ~= case_12_)) then
            local _0 = case_11_
            local ext0 = case_12_
            return nil, string.format("Unsupported extension %s, must be .fnl, .fnlm and .lua", ext0)
          else
            return nil
          end
        end
      else
        return nil
      end
    end
    return _8_
  end
end
local function bind_context(ctx)
  local base = {compile = bind_compile(ctx), eval = bind_eval(ctx), sync = bind_sync(ctx), locate = bind_locate(ctx)}
  if ctx.transform then
    local function _24_(source, _3ffilename)
      if (nil == source) then
        _G.error("Missing argument source on fnl/hotpot/api.fnl:70", 2)
      else
      end
      return ctx.transform(source, (_3ffilename or "--hotpot-api-transform"))
    end
    base.transform = _24_
  else
  end
  return base
end
M.context = function(_3fpath)
  local case_27_, case_28_ = pcall(R.context.new, _3fpath)
  if ((case_27_ == true) and (nil ~= case_28_)) then
    local ctx = case_28_
    return bind_context(ctx)
  elseif ((case_27_ == false) and (nil ~= case_28_)) then
    local err = case_28_
    return nil, err
  else
    return nil
  end
end
return M