local R = require("hotpot.util")
local M, m = {}, {}
local capabilities = {}
m.initialize = function(_params, callback)
  return callback(nil, {capabilities = capabilities})
end
m.shutdown = function(_params, callback)
  return callback(nil, nil)
end
m.cmd = function(dispatchers)
  if (nil == dispatchers) then
    _G.error("Missing argument dispatchers on fnl/hotpot/lsp.fnl:12", 2)
  else
  end
  local res = {}
  local meta = {dispatchers = dispatchers, ["request-id"] = 0, ["closing?"] = false}
  res.request = function(method, params, callback)
    do
      local case_2_ = m[method]
      if (nil ~= case_2_) then
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
M["start-lsp"] = function(_5_)
  local root = _5_.root
  if (nil == root) then
    _G.error("Missing argument root on fnl/hotpot/lsp.fnl:37", 2)
  else
  end
  local home_path = vim.fs.normalize("~")
  local name_path
  do
    local case_7_ = vim.fs.relpath(home_path, root)
    if (case_7_ == nil) then
      name_path = root
    elseif (nil ~= case_7_) then
      local ctx_rel = case_7_
      name_path = ("~/" .. ctx_rel)
    else
      name_path = nil
    end
  end
  local client_id = vim.lsp.start({cmd = m.cmd, name = string.format("hotpot@%s", name_path), root_dir = root}, {attach = false})
  return client_id
end
local report_id = 0
M["emit-report"] = function(client_id, report)
  if (nil == report) then
    _G.error("Missing argument report on fnl/hotpot/lsp.fnl:80", 2)
  else
  end
  if (nil == client_id) then
    _G.error("Missing argument client-id on fnl/hotpot/lsp.fnl:80", 2)
  else
  end
  local client = vim.lsp.get_client_by_id(client_id)
  local handler = (client.handlers["$/progress"] or vim.lsp.handlers["$/progress"])
  local ctx_token_id = client.config.root_dir
  local lsp_ctx = {method = "$/progress", client_id = client_id}
  report_id = (1 + report_id)
  local function send_progress(token, title, begin_msg, report_msgs, end_msg)
    if (nil == end_msg) then
      _G.error("Missing argument end-msg on fnl/hotpot/lsp.fnl:87", 2)
    else
    end
    if (nil == report_msgs) then
      _G.error("Missing argument report-msgs on fnl/hotpot/lsp.fnl:87", 2)
    else
    end
    if (nil == begin_msg) then
      _G.error("Missing argument begin-msg on fnl/hotpot/lsp.fnl:87", 2)
    else
    end
    if (nil == title) then
      _G.error("Missing argument title on fnl/hotpot/lsp.fnl:87", 2)
    else
    end
    if (nil == token) then
      _G.error("Missing argument token on fnl/hotpot/lsp.fnl:87", 2)
    else
    end
    if (0 < #report_msgs) then
      handler(nil, {token = token, value = {kind = "begin", title = title, message = begin_msg, _percentage = 0}}, lsp_ctx)
      for i = 1, #report_msgs do
        handler(nil, {token = token, value = {kind = "report", message = report_msgs[i], _percentage = (100 * (i / #report_msgs))}}, lsp_ctx)
      end
      return handler(nil, {token = token, value = {kind = "end", message = end_msg, _percentage = 100}}, lsp_ctx)
    else
      return nil
    end
  end
  local _17_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _18_ in ipairs(report.errors) do
      local fnl_rel = _18_["fnl-rel"]
      local val_28_ = string.format("Error: %s", fnl_rel)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _17_ = tbl_26_
  end
  send_progress(("hotpot-sync-errored-" .. ctx_token_id .. report_id), "Sync: errors", "Errors...", _17_, string.format("Errors for %d files", #report.errors))
  local _20_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _21_ in ipairs(report.cleaned) do
      local lua_abs = _21_["lua-abs"]
      local val_28_ = string.format("Clean: %s", lua_abs)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _20_ = tbl_26_
  end
  send_progress(("hotpot-sync-cleaned-" .. ctx_token_id .. report_id), "Sync: cleaning", "Cleaning...", _20_, string.format("Cleaned %d files", #report.cleaned))
  local _23_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _24_ in ipairs(report.compiled) do
      local fnl_rel = _24_["fnl-rel"]
      local duration_ms = _24_["duration-ms"]
      local val_28_ = string.format("Sync: %s (%.2fms)", fnl_rel, duration_ms)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _23_ = tbl_26_
  end
  local function _26_()
    local sum = 0
    for _, _27_ in ipairs(report.compiled) do
      local duration_ms = _27_["duration-ms"]
      sum = (sum + duration_ms)
    end
    return sum
  end
  return send_progress(("hotpot-sync-compiled-" .. ctx_token_id .. report_id), "Sync: compiling", "Syncing...", _23_, string.format("Synced %d files (%.2fms)", #report.compiled, _26_()))
end
return M