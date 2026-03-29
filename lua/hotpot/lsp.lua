local R = require("hotpot.util")
local M, m = {}, {}
local capabilities = {}
m.initialize = function(_params, callback)
  return callback(nil, {capabilities = capabilities})
end
m.shutdown = function(_params, callback)
  return callback(nil, nil)
end
M.cmd = function(dispatchers)
  if (nil == dispatchers) then
    _G.error("Missing argument dispatchers on fnl/hotpot/lsp.fnl:12", 2)
  else
  end
  local res = {}
  local meta = {dispatchers = dispatchers, ["request-id"] = 0, ["closing?"] = false}
  res.request = function(method, params, callback)
    do
      local case_2_ = m[method]
      if (case_2_ == nil) then
      elseif (nil ~= case_2_) then
        local func = case_2_
        func(params, callback)
      else
      end
    end
    meta["request-id"] = (meta["request-id"] + 1)
    return true, meta["request-id"]
  end
  res.notify = function(method, params)
    if (method == "exit") then
      return dispatchers.on_exit(0, 15)
    else
      return nil
    end
  end
  res.is_closing = function()
    return meta["closing?"]
  end
  res.terminate = function()
    meta["closing?"] = true
    return nil
  end
  return res
end
local function start_lsp(root)
  local client_id = vim.lsp.start({cmd = M.cmd, name = string.format("hotpot@%s", root), root_dir = root}, {attach = false})
  return client_id
end
local function emit_report(client_id, ctx, report)
  local client = vim.lsp.get_client_by_id(client_id)
  local handler = (client.handlers["$/progress"] or vim.lsp.handlers["$/progress"])
  local ctx_token_id = ctx.path.source
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
  local _6_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _7_ in ipairs(report.errors) do
      local fnl_rel = _7_["fnl-rel"]
      local val_28_ = string.format("Error: %s", fnl_rel)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _6_ = tbl_26_
  end
  send_progress(("hotpot-sync-errored-" .. ctx_token_id), "Sync: errors", "Errors...", _6_, string.format("Errors for %d files", #report.errors))
  local _9_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _10_ in ipairs(report.cleaned) do
      local lua_abs = _10_["lua-abs"]
      local val_28_ = string.format("Clean: %s", lua_abs)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _9_ = tbl_26_
  end
  send_progress(("hotpot-sync-cleaned-" .. ctx_token_id), "Sync: cleaning", "Cleaning...", _9_, string.format("Cleaned %d files", #report.cleaned))
  local _12_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _13_ in ipairs(report.compiled) do
      local fnl_rel = _13_["fnl-rel"]
      local val_28_ = string.format("Sync: %s", fnl_rel)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _12_ = tbl_26_
  end
  return send_progress(("hotpot-sync-compiled-" .. ctx_token_id), "Sync: compiling", "Syncing...", _12_, string.format("Synced %d files", #report.compiled))
end
return {["start-lsp"] = start_lsp, ["emit-report"] = emit_report}