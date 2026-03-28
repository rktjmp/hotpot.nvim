local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local notify_error = _local_1_["notify-error"]
local M, m = {}, {}
local home_path = vim.fs.normalize("~")
local function silly_lsp_notification(buf, ctx_root, report)
  local client_id
  local function _3_()
    local case_2_ = vim.fs.relpath(home_path, ctx_root)
    if (case_2_ == nil) then
      return ctx_root
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
    local handler = (client.handlers["$/progress"] or vim.lsp.handlers["$/progress"])
    local lsp_ctx = {method = "$/progress", client_id = client_id}
    local function send_progress(token, title, begin_msg, report_msgs, end_msg)
      if (0 < #report_msgs) then
        handler(nil, {token = token, value = {kind = "begin", message = begin_msg, _percentage = 0}}, lsp_ctx)
        for i = 1, #report_msgs do
          handler(nil, {token = token, value = {kind = "report", message = report_msgs[i], _percentage = (100 * (i / #report_msgs))}}, lsp_ctx)
        end
        return handler(nil, {token = token, value = {kind = "end", message = end_msg, _percentage = 100}}, lsp_ctx)
      else
        return nil
      end
    end
    local _7_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, _8_ in ipairs(report.errors) do
        local fnl_rel = _8_["fnl-rel"]
        local val_28_ = string.format("Error: %s", fnl_rel)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _7_ = tbl_26_
    end
    send_progress(("hotpot-sync-errored-" .. ctx_root), "Sync: errors", "Errors...", _7_, string.format("Errors for %d files", #report.errors))
    local _10_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, _11_ in ipairs(report.cleaned) do
        local lua_abs = _11_["lua-abs"]
        local val_28_ = string.format("Clean: %s", lua_abs)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _10_ = tbl_26_
    end
    send_progress(("hotpot-sync-cleaned-" .. ctx_root), "Sync: cleaning", "Cleaning...", _10_, string.format("Cleaned %d files", #report.cleaned))
    local _13_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, _14_ in ipairs(report.compiled) do
        local fnl_rel = _14_["fnl-rel"]
        local val_28_ = string.format("Sync: %s", fnl_rel)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _13_ = tbl_26_
    end
    send_progress(("hotpot-sync-compiled-" .. ctx_root), "Sync: compiling", "Syncing...", _13_, string.format("Synced %d files", #report.compiled))
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
    local case_17_ = Context.nearest(path)
    if (nil ~= case_17_) then
      local root = case_17_
      local function _18_(...)
        local case_19_, case_20_ = ...
        if ((case_19_ == true) and (nil ~= case_20_)) then
          local ctx = case_20_
          local function _21_(...)
            local case_22_, case_23_ = ...
            if ((case_22_ == true) and (nil ~= case_23_)) then
              local report = case_23_
              return silly_lsp_notification(buf, root, report)
            elseif ((case_22_ == false) and (nil ~= case_23_)) then
              local err = case_23_
              return notify_error(err)
            else
              return nil
            end
          end
          return _21_(pcall(Context.sync, ctx))
        elseif ((case_19_ == false) and (nil ~= case_20_)) then
          local err = case_20_
          return notify_error(err)
        else
          return nil
        end
      end
      _18_(pcall(Context.new, root))
    elseif (case_17_ == nil) then
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