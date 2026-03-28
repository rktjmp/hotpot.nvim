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
return {["start-lsp"] = start_lsp}