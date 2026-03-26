if (nil == _G.__hotpot_disable_version_check) then
  assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
else
end
local _local_2_ = require("hotpot.const")
local HOTPOT_CONFIG_CACHE_ROOT = _local_2_.HOTPOT_CONFIG_CACHE_ROOT
do
  local case_3_ = vim.uv.fs_stat(HOTPOT_CONFIG_CACHE_ROOT)
  if (case_3_ == nil) then
    local _ = vim.fn.mkdir(HOTPOT_CONFIG_CACHE_ROOT, "p")
    local Context = require("hotpot.context")
    local ctx = Context.new(vim.fn.stdpath("config"))
    Context.sync(ctx)
  elseif ((_G.type(case_3_) == "table") and (case_3_.type == "directory")) then
  elseif ((_G.type(case_3_) == "table") and (nil ~= case_3_.type)) then
    local t = case_3_.type
    local msg = table.concat({"Hotpot: %s exists but is not directory, is %s, consider removing it?", "Hotpot probably wont function correctly."}, "\n")
    vim.notify(string.format(msg, HOTPOT_CONFIG_CACHE_ROOT, t), vim.log.levels.ERROR, {})
  else
  end
end
vim.cmd.packadd(vim.fs.basename(HOTPOT_CONFIG_CACHE_ROOT))
do
  local autocmd = require("hotpot.autocmd")
  autocmd.enable()
end
local function _5_()
  return require("hotpot.fennel")
end
package.preload["fennel"] = _5_
local function setup(_3foptions)
  return true
end
return {setup = setup}