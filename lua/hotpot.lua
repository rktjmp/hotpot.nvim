if (nil == _G.__hotpot_disable_version_check) then
  assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
else
end
local _local_2_ = require("hotpot.util")
local R = _local_2_.R
local HOTPOT_CONFIG_CACHE_ROOT = R.const.HOTPOT_CONFIG_CACHE_ROOT
local HOTPOT_FENNEL_UPDATE_ROOT = R.const.HOTPOT_FENNEL_UPDATE_ROOT
local HOTPOT_FENNEL_UPDATE_LUA_ROOT = R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT
do
  local case_3_ = vim.uv.fs_stat(HOTPOT_CONFIG_CACHE_ROOT)
  if (case_3_ == nil) then
    local _ = vim.fn.mkdir(HOTPOT_CONFIG_CACHE_ROOT, "p")
    local Context = R.Context
    local function _4_(...)
      local case_5_, case_6_ = ...
      if ((case_5_ == true) and (nil ~= case_6_)) then
        local ctx = case_6_
        local function _7_(...)
          local case_8_, case_9_ = ...
          if (case_8_ == true) then
            return "ok"
          elseif ((case_8_ == false) and (nil ~= case_9_)) then
            local err = case_9_
            vim.notify("Hotpot encountered an error syncing during first-time startup.", vim.log.levels.WARN)
            vim.notify("You should still be able to edit fnl files to fixe the issue.", vim.log.levels.WARN)
            return vim.notify(err, vim.log.levels.ERR)
          else
            return nil
          end
        end
        return _7_(pcall(Context.sync, ctx))
      elseif ((case_5_ == false) and (nil ~= case_6_)) then
        local err = case_6_
        vim.notify("Hotpot encountered an error syncing during first-time startup.", vim.log.levels.WARN)
        vim.notify("You should still be able to edit fnl files to fixe the issue.", vim.log.levels.WARN)
        return vim.notify(err, vim.log.levels.ERR)
      else
        return nil
      end
    end
    _4_(pcall(Context.new, vim.fn.stdpath("config")))
  elseif ((_G.type(case_3_) == "table") and (case_3_.type == "directory")) then
  elseif ((_G.type(case_3_) == "table") and (nil ~= case_3_.type)) then
    local t = case_3_.type
    local msg = table.concat({"Hotpot: %s exists but is not directory, is %s, consider removing it?", "Hotpot probably wont function correctly."}, "\n")
    vim.notify(string.format(msg, HOTPOT_CONFIG_CACHE_ROOT, t), vim.log.levels.ERROR, {})
  else
  end
end
do
  local case_13_ = vim.uv.fs_stat(HOTPOT_FENNEL_UPDATE_LUA_ROOT)
  if (case_13_ == nil) then
    vim.fn.mkdir(HOTPOT_FENNEL_UPDATE_LUA_ROOT, "p")
  else
  end
end
vim.cmd.packadd(vim.fs.basename(HOTPOT_CONFIG_CACHE_ROOT))
vim.cmd.packadd(vim.fs.basename(HOTPOT_FENNEL_UPDATE_ROOT))
do
  local autocmd = R.autocmd
  local command = R.command
  autocmd.enable()
  command.enable()
end
local function _15_()
  return require("hotpot.fennel")
end
package.preload["fennel"] = _15_
local function setup(_3foptions)
  return true
end
return {setup = setup}