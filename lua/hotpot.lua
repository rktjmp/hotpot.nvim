assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
local _local_1_ = require("hotpot.const")
local HOTPOT_CONFIG_CACHE_ROOT = _local_1_.HOTPOT_CONFIG_CACHE_ROOT
local setup_3f = false
if not setup_3f then
  do
    local case_2_ = vim.uv.fs_stat(HOTPOT_CONFIG_CACHE_ROOT)
    if (case_2_ == nil) then
      local _ = vim.fn.mkdir(HOTPOT_CONFIG_CACHE_ROOT, "p")
      local Context = require("hotpot.context")
      local ctx = Context.new(vim.fn.stdpath("config"))
      Context.sync(ctx)
    elseif ((_G.type(case_2_) == "table") and (case_2_.type == "directory")) then
    elseif ((_G.type(case_2_) == "table") and (nil ~= case_2_.type)) then
      local t = case_2_.type
      local msg = table.concat({"Hotpot: %s exists but is not directory, is %s, consider removing it?", "Hotpot probably wont function correctly."}, "\n")
      vim.notify(string.format(msg, HOTPOT_CONFIG_CACHE_ROOT, t), vim.log.levels.ERROR, {})
    else
    end
  end
  vim.cmd.packadd("hotpot-config-cache")
  do
    local autocmd = require("hotpot.autocmd")
    autocmd.enable()
  end
  local function _4_()
    return require("hotpot.fennel")
  end
  package.preload["fennel"] = _4_
  setup_3f = true
else
end
local function setup(_3foptions)
  return true
end
return {setup = setup}