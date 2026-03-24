local M, m = {}, {}
local function buf_write_post_callback(event)
  local config_root = vim.fn.stdpath("config")
  local Context = require("hotpot.context")
  local path = event.match
  local context_root
  do
    local case_1_ = vim.fs.relpath(config_root, path)
    if (nil ~= case_1_) then
      local path_inside_config = case_1_
      context_root = config_root
    elseif (case_1_ == nil) then
      context_root = vim.fs.root(path, ".hotpot.fnl")
    else
      context_root = nil
    end
  end
  if context_root then
    local case_3_, case_4_ = Context.new(context_root)
    if (nil ~= case_3_) then
      local ctx = case_3_
      Context.sync(ctx)
    elseif ((case_3_ == nil) and (nil ~= case_4_)) then
      local err = case_4_
      vim.notify(err, vim.log.level.ERROR, {})
    else
    end
  else
  end
  return nil
end
local _2aaugroup_id_2a = nil
M.enable = function()
  if not _2aaugroup_id_2a then
    local augroup_id = vim.api.nvim_create_augroup("hotpot-fnl-ft", {clear = true})
    vim.api.nvim_create_autocmd({"BufWritePost"}, {pattern = {"*.fnl", "*.fnlm"}, callback = buf_write_post_callback})
    _2aaugroup_id_2a = augroup_id
    return nil
  else
    return nil
  end
end
M.disable = function()
  if _2aaugroup_id_2a then
    vim.api.nvim_delete_augroup_by_id(_2aaugroup_id_2a)
    _2aaugroup_id_2a = nil
    return nil
  else
    return nil
  end
end
return M