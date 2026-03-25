assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
local _local_1_ = require("hotpot.const")
local HOTPOT_CACHE_ROOT = _local_1_.HOTPOT_CACHE_ROOT
do
  local case_2_ = vim.uv.fs_stat(HOTPOT_CACHE_ROOT)
  if (case_2_ == nil) then
    local _ = vim.fn.mkdir(HOTPOT_CACHE_ROOT, "p")
    local Context = require("hotpot.context")
    local ctx = Context.new(vim.fn.stdpath("config"))
    Context.sync(ctx)
  elseif ((_G.type(case_2_) == "table") and (case_2_.type == "directory")) then
  elseif ((_G.type(case_2_) == "table") and (nil ~= case_2_.type)) then
    local t = case_2_.type
    local msg = "Hotpot: %s exists but is not directory, is %s, consider removing it?"
    vim.notify(string.format(msg, HOTPOT_CACHE_ROOT, t), vim.log.levels.ERROR, {})
  else
  end
end
vim.cmd.packadd("config")
do
  local autocmd = require("hotpot.autocmd")
  autocmd.enable()
end
local function _4_()
  return require("hotpot.aot.fennel")()
end
package.preload["fennel"] = _4_
local function setup(_3foptions)
  local default = {fennel = {byo = false}}
  local options = vim.tbl_extend("force", default, (_3foptions or {}))
  if (true == options.fennel.byo) then
    package.preload["fennel"] = nil
    return nil
  else
    return nil
  end
end
return {setup = setup}