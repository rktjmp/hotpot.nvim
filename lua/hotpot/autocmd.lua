local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local notify_error = _local_1_["notify-error"]
local M, m = {}, {}
local function silly_lsp_notification(buf, ctx, report)
  if _G.__hotpot_lsp then
    local client_id = R.lsp["start-lsp"]({root = ctx.path.source})
    return R.lsp["emit-report"](client_id, report)
  else
    return nil
  end
end
local function buf_write_post_callback(event)
  local Context = R.Context
  local path = event.match
  local buf = event.buf
  do
    local case_3_ = Context.nearest(path)
    if (nil ~= case_3_) then
      local root = case_3_
      local function _4_(...)
        local case_5_, case_6_ = ...
        if ((case_5_ == true) and (nil ~= case_6_)) then
          local ctx = case_6_
          local function _7_(...)
            local case_8_, case_9_ = ...
            if ((case_8_ == true) and (nil ~= case_9_)) then
              local report = case_9_
              return silly_lsp_notification(buf, ctx, report)
            elseif ((case_8_ == false) and (nil ~= case_9_)) then
              local err = case_9_
              return notify_error(err)
            else
              return nil
            end
          end
          return _7_(pcall(Context.sync, ctx))
        elseif ((case_5_ == false) and (nil ~= case_6_)) then
          local err = case_6_
          return notify_error(err)
        else
          return nil
        end
      end
      _4_(pcall(Context.new, root))
    elseif (case_3_ == nil) then
    else
    end
  end
  return nil
end
local _2aaugroup_id_2a = nil
M.enable = function()
  if not _2aaugroup_id_2a then
    local augroup_id = vim.api.nvim_create_augroup("hotpot-fnl-ft", {clear = true})
    _2aaugroup_id_2a = augroup_id
    return vim.api.nvim_create_autocmd({"BufWritePost"}, {pattern = {"*.fnl", "*.fnlm"}, group = augroup_id, callback = buf_write_post_callback})
  else
    return nil
  end
end
M.disable = function()
  if _2aaugroup_id_2a then
    vim.api.nvim_del_augroup_by_id(_2aaugroup_id_2a)
    _2aaugroup_id_2a = nil
    return nil
  else
    return nil
  end
end
M["enabled?"] = function()
  return (nil ~= _2aaugroup_id_2a)
end
return M