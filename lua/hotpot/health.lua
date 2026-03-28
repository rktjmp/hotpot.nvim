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
  vim.health.start(":Hotpot fennel version")
  local case_5_, case_6_ = pcall(require, "hotpot.update-fennel.fennel")
  if ((case_5_ == true) and (nil ~= case_6_)) then
    local mod = case_6_
    return vim.health.info(string.format("Using custom Fennel version: `%s`", mod.version))
  elseif (case_5_ == false) then
    return vim.health.info(string.format("Using default Fennel version: `%s`", R.fennel.version))
  else
    return nil
  end
end
local function check()
  do
    local config = vim.fn.stdpath("config")
    local ctx = R.context.new(config)
    context_report(config, ctx)
  end
  do
    local case_8_ = R.context.nearest(vim.uv.cwd())
    if (nil ~= case_8_) then
      local root = case_8_
      local case_9_, case_10_ = pcall(R.context.new, root)
      if ((case_9_ == true) and (nil ~= case_10_)) then
        local ctx = case_10_
        context_report(root, ctx)
      elseif ((case_9_ == nil) and (nil ~= case_10_)) then
        local err = case_10_
        context_report(root, nil, err)
      else
      end
    else
    end
  end
  return fennel_update_report()
end
return {check = check}