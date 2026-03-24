local M, m = {}, {}
local function buf_write_post_callback(event)
  local Context = require("hotpot.context")
  local path = event.match
  do
    local case_1_ = Context.nearest(path)
    if (nil ~= case_1_) then
      local root = case_1_
      local case_2_, case_3_ = Context.new(root)
      if (nil ~= case_2_) then
        local ctx = case_2_
        Context.sync(ctx)
      elseif ((case_2_ == nil) and (nil ~= case_3_)) then
        local err = case_3_
        vim.notify(err, vim.log.level.ERROR, {})
      else
      end
    else
    end
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