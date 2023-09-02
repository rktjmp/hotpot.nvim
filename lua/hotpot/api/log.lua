local function log_path()
  local _let_1_ = require("hotpot.fs")
  local join_path = _let_1_["join-path"]
  return join_path(vim.fn.stdpath("cache"), "hotpot.log")
end
return {["log-path"] = log_path}