assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
do
  local cache_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "hotpot", "opt", "config")
  local case_1_ = vim.uv.fs_stat(cache_dir)
  if (case_1_ == nil) then
    local _ = vim.fn.mkdir(cache_dir, "p")
    local Context = require("hotpot.context")
    local ctx = Context.new(vim.fn.stdpath("config"))
    Context.sync(ctx)
  elseif ((_G.type(case_1_) == "table") and (case_1_.type == "directory")) then
  elseif ((_G.type(case_1_) == "table") and (nil ~= case_1_.type)) then
    local t = case_1_.type
    local msg = "Hotpot: %s exists but is not directory, is %s, consider removing it?"
    vim.notify(string.format(msg, cache_dir, t), vim.log.levels.ERROR, {})
  else
  end
end
vim.cmd.packadd("config")
do
  local autocmd = require("hotpot.autocmd")
  autocmd.enable()
end
local function _3_()
  return require("hotpot.aot.fennel")()
end
package.preload["fennel"] = _3_
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