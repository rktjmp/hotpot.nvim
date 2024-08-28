local data = {}
local M = {}
local api = vim.api
local function resolve_buf_id(id)
  local nvim_buf_call = api["nvim_buf_call"]
  local nvim_get_current_buf = api["nvim_get_current_buf"]
  if (0 == id) then
    return nvim_buf_call(id, nvim_get_current_buf)
  else
    return id
  end
end
local function record_attachment(buf, ns, au_group, handler)
  data[buf] = {ns = ns, buf = buf, ["au-group"] = au_group, handler = handler, err = nil}
  return nil
end
local function record_detachment(buf)
  data[buf] = nil
  return nil
end
local function set_buf_err(buf, err)
  data[buf]["err"] = err
  return nil
end
local function data_for_buf(buf)
  return data[buf]
end
local function reset_diagnostic(ns)
  return vim.diagnostic.reset(ns)
end
local function render_error_diagnostic(buf, ns, err)
  local function set_diagnostic(kind, file, line, msg, err0)
    local msg0 = string.gsub(msg, " in strict mode", "")
    return vim.diagnostic.set(ns, buf, {{lnum = line, col = 0, message = msg0, severity = vim.diagnostic.severity.ERROR, source = "hotpot-diagnostic", user_data = err0}})
  end
  local _2_, _3_, _4_, _5_ = string.match(err, "([^:]-):([-%d:?]+) ([%w]+) error: (.-)\n")
  if ((_2_ == "unknown") and (_3_ == "?:?") and (nil ~= _4_) and (nil ~= _5_)) then
    local kind = _4_
    local msg = _5_
    return set_diagnostic(kind, "unknown", 0, ("(error had no line number)" .. msg), err)
  elseif ((nil ~= _2_) and (nil ~= _3_) and (nil ~= _4_) and (nil ~= _5_)) then
    local file = _2_
    local line_col = _3_
    local kind = _4_
    local msg = _5_
    local _6_ = string.match(line_col, "([%d?]+)")
    if (_6_ == "?") then
      return set_diagnostic(kind, file, 0, ("(error had no line number)" .. msg), err)
    elseif (nil ~= _6_) then
      local line = _6_
      return set_diagnostic(kind, file, (tonumber(line) - 1), msg, err)
    else
      return nil
    end
  else
    local _ = _2_
    return nil
  end
end
local function make_handler(buf, ns)
  local _let_9_ = require("hotpot.api.get_text")
  local get_buf_text = _let_9_["get-buf"]
  local _let_10_ = require("hotpot.lang.fennel.compiler")
  local compile_string = _let_10_["compile-string"]
  local allowed_globals
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for n, _ in pairs(_G) do
      local val_23_auto = n
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    allowed_globals = tbl_21_auto
  end
  local fname
  do
    local _12_ = api.nvim_buf_get_name(buf)
    if (_12_ == "") then
      fname = nil
    elseif (nil ~= _12_) then
      local any = _12_
      fname = any
    else
      fname = nil
    end
  end
  local compiler_options
  do
    local _let_14_ = require("hotpot.runtime")
    local config_for_context = _let_14_["config-for-context"]
    compiler_options = config_for_context((fname or vim.fn.getcwd())).compiler
  end
  local kind
  do
    local _15_ = string.find((fname or ""), "macros?%.fnl$")
    if (nil ~= _15_) then
      local any = _15_
      kind = "macro"
    elseif (_15_ == nil) then
      kind = "module"
    else
      kind = nil
    end
  end
  local preprocessor
  local function _17_(_241)
    return compiler_options.preprocessor(_241, {["macro?"] = (kind == "macro"), path = fname, modname = nil})
  end
  preprocessor = _17_
  local plugins
  if (kind == "module") then
    plugins = compiler_options.modules.plugins
  elseif (kind == "macro") then
    plugins = compiler_options.macros.plugins
  else
    plugins = nil
  end
  local local_compiler_options = vim.tbl_extend("keep", {filename = fname, allowedGlobals = allowed_globals, plugins = plugins, ["error-pinpoint"] = false}, compiler_options.modules)
  local function _19_()
    local buf_text
    do
      local wrap
      if (kind == "module") then
        local function _20_(_241)
          return _241
        end
        wrap = _20_
      elseif (kind == "macro") then
        local function _21_(_241)
          return string.format("(macro ___hotpot-dignostics-wrap [] %s )", _241)
        end
        wrap = _21_
      else
        wrap = nil
      end
      buf_text = wrap(preprocessor(get_buf_text(buf), {}))
    end
    do
      local _23_, _24_ = compile_string(buf_text, local_compiler_options, compiler_options.macros)
      if ((_23_ == true) and true) then
        local _ = _24_
        set_buf_err(buf, nil)
        reset_diagnostic(ns)
      elseif ((_23_ == false) and (nil ~= _24_)) then
        local err = _24_
        set_buf_err(buf, err)
        render_error_diagnostic(buf, ns, err)
      else
      end
    end
    return nil
  end
  return _19_
end
local function do_attach(buf)
  local ns = api.nvim_create_namespace(("hotpot-diagnostic-for-buf-" .. buf))
  local handler = make_handler(buf, ns)
  local au_group = api.nvim_create_augroup(("hotpot-diagnostics-for-buf-" .. buf), {clear = true})
  api.nvim_create_autocmd({"TextChanged", "InsertLeave"}, {buffer = buf, group = au_group, desc = ("Hotpot diagnostics update autocmd for buf#" .. buf), callback = handler})
  local function _26_(_241)
    if ((_G.type(_241) == "table") and (_241.match == "fennel")) then
      return nil
    else
      local _ = _241
      return M.detach(buf)
    end
  end
  api.nvim_create_autocmd("FileType", {buffer = buf, group = au_group, desc = ("Hotpot diagnostics auto-detach on filetype change for buf#" .. buf), callback = _26_})
  record_attachment(buf, ns, au_group, handler)
  handler()
  return buf
end
M.attach = function(user_buf)
  local buf = resolve_buf_id(user_buf)
  do
    local _28_ = data_for_buf(buf)
    if (_28_ == nil) then
      do_attach(buf)
    else
    end
  end
  return buf
end
M.detach = function(user_buf, _3fopts)
  local buf = resolve_buf_id(user_buf)
  local _30_ = data_for_buf(buf)
  if ((_G.type(_30_) == "table") and (nil ~= _30_.ns) and (nil ~= _30_["au-group"])) then
    local ns = _30_.ns
    local au_group = _30_["au-group"]
    api.nvim_clear_autocmds({group = au_group, buffer = buf})
    reset_diagnostic(ns)
    record_detachment(buf)
    return nil
  else
    return nil
  end
end
M["error-for-buf"] = function(user_buf)
  local buf = resolve_buf_id(user_buf)
  local _32_ = data_for_buf(buf)
  if (_32_ == nil) then
    api.nvim_echo({{"Hotpot diagnostics not attached to buffer, could not get error", "DiagnosticWarn"}}, false, {})
    return nil
  elseif ((_G.type(_32_) == "table") and (nil ~= _32_.err)) then
    local err = _32_.err
    return err
  elseif ((_G.type(_32_) == "table") and (_32_.err == nil)) then
    return nil
  else
    return nil
  end
end
M.enable = function()
  local function attach_hotpot_diagnostics(event)
    if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
      local buf = event.buf
      M.attach(buf)
    else
    end
    return nil
  end
  if not data["au-group"] then
    data["au-group"] = api.nvim_create_augroup("hotpot-diagnostics-enabled", {clear = true})
    return api.nvim_create_autocmd("FileType", {group = data["au-group"], pattern = "fennel", desc = "Hotpot diagnostics auto-attach", callback = attach_hotpot_diagnostics})
  else
    return nil
  end
end
M.disable = function()
  api.nvim_clear_autocmds({group = data["au-group"]})
  for _, _36_ in pairs(data) do
    local buf = _36_["buf"]
    M.detach(buf)
  end
  data["au-group"] = nil
  return nil
end
return M