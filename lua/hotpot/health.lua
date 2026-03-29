local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local notify_error = _local_1_["notify-error"]
local function context_report(root, ctx, err)
  vim.health.start((root .. " Context"))
  if (nil ~= ctx) then
    local ctx0 = ctx
    vim.health.info(string.format("target: {%s}", ctx0.target))
    vim.health.info(string.format("source: `%s`", ctx0.path.source))
    return vim.health.info(string.format("destination: `%s`", ctx0.path.dest))
  else
    local _ = ctx
    return vim.health.error(err)
  end
end
local function fennel_update_report()
  vim.health.start(":Hotpot fennel update")
  do
    local case_3_ = (1 == vim.fn.executable("curl"))
    if (case_3_ == true) then
      vim.health.ok("`curl` is executable")
    elseif (case_3_ == false) then
      vim.health.warn("`curl` is not executable", "Install curl to run `:Hotpot fennel update`")
    else
    end
  end
  do
    local case_5_ = vim.uv.fs_stat(R.const.HOTPOT_FENNEL_UPDATE_ROOT)
    if (case_5_ == nil) then
      vim.health.error(string.format("Target directory missing: `%s`", R.const.HOTPOT_FENNEL_UPDATE_ROOT), "Should be automatically created on load, check parent directory permissions?")
    elseif (_G.type(case_5_) == "table") then
      vim.health.ok(string.format("Target directory exists: `%s`", R.const.HOTPOT_FENNEL_UPDATE_ROOT))
    else
    end
  end
  local lua_mod = vim.fs.joinpath(R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT, "fennel.lua")
  if vim.uv.fs_stat(lua_mod) then
    vim.health.ok(string.format("Downloaded lua module exists: `%s`", lua_mod))
    local case_7_, case_8_ = pcall(require, "hotpot.fennel-update.fennel")
    if ((case_7_ == true) and (nil ~= case_8_)) then
      local mod = case_8_
      return vim.health.ok(string.format("Using custom Fennel version: `%s`", mod.version))
    elseif ((case_7_ == false) and (nil ~= case_8_)) then
      local err = case_8_
      return vim.health.error("Downloaded fennel could not be loaded.", err)
    else
      return nil
    end
  else
    return vim.health.info(string.format("Using default Fennel version: `%s`", R.fennel.version))
  end
end
local function check()
  do
    local config = vim.fn.stdpath("config")
    local ctx = R.context.new(config)
    local nearest = R.context.nearest(vim.uv.cwd())
    context_report(config, ctx)
    if (nearest and (config ~= nearest)) then
      local case_11_, case_12_ = pcall(R.context.new, nearest)
      if ((case_11_ == true) and (nil ~= case_12_)) then
        local ctx0 = case_12_
        context_report(nearest, ctx0)
      elseif ((case_11_ == nil) and (nil ~= case_12_)) then
        local err = case_12_
        context_report(nearest, nil, err)
      else
      end
    else
    end
  end
  return fennel_update_report()
end
return {check = check}