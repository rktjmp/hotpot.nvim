local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local notify_error = _local_1_["notify-error"]
local M, m = {}, {}
local home_path = vim.fs.normalize("~")
local function silly_lsp_notification(buf, ctx, report)
  local client_id
  local function _3_()
    local case_2_ = vim.fs.relpath(home_path, ctx.path.source)
    if (case_2_ == nil) then
      return ctx.path.source
    elseif (nil ~= case_2_) then
      local ctx_rel = case_2_
      return ("~/" .. ctx_rel)
    else
      return nil
    end
  end
  client_id = R.lsp["start-lsp"](_3_())
  local case_5_ = vim.lsp.buf_attach_client(buf, client_id)
  if (case_5_ == true) then
    local client = vim.lsp.get_client_by_id(client_id)
    R.lsp["emit-report"](client_id, ctx, report)
    vim.lsp.buf_detach_client(buf, client_id)
    return client:stop()
  else
    return nil
  end
end
local function buf_write_post_callback(event)
  local Context = R.Context
  local path = event.match
  local buf = event.buf
  do
    local case_7_ = Context.nearest(path)
    if (nil ~= case_7_) then
      local root = case_7_
      local function _8_(...)
        local case_9_, case_10_ = ...
        if ((case_9_ == true) and (nil ~= case_10_)) then
          local ctx = case_10_
          local function _11_(...)
            local case_12_, case_13_ = ...
            if ((case_12_ == true) and (nil ~= case_13_)) then
              local report = case_13_
              return silly_lsp_notification(buf, ctx, report)
            elseif ((case_12_ == false) and (nil ~= case_13_)) then
              local err = case_13_
              return notify_error(err)
            else
              return nil
            end
          end
          return _11_(pcall(Context.sync, ctx))
        elseif ((case_9_ == false) and (nil ~= case_10_)) then
          local err = case_10_
          return notify_error(err)
        else
          return nil
        end
      end
      _8_(pcall(Context.new, root))
    elseif (case_7_ == nil) then
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