local _local_1_ = string
local fmt = _local_1_["format"]
local function generate_runtime_loaders(plugin_type, glob)
  local _let_2_ = require("hotpot.loader")
  local make_record_loader = _let_2_["make-record-loader"]
  local _let_3_ = require("hotpot.loader.record")
  local fetch_record = _let_3_["fetch"]
  local _let_4_ = require("hotpot.lang.fennel")
  local make_runtime_record = _let_4_["make-runtime-record"]
  local _let_5_ = require("hotpot.searcher")
  local glob_search = _let_5_["glob-search"]
  local search = _let_5_["search"]
  local find_all
  local function _6_()
    return glob_search({glob = glob, ["all?"] = true})
  end
  find_all = _6_
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, path in ipairs((find_all() or {})) do
    local val_19_auto
    do
      local modname = string.gsub(string.match(path, (plugin_type .. "/(.-)%.fnl$")), "/", ".")
      local fresh_record = make_runtime_record(modname, path, {["runtime-type"] = plugin_type, glob = glob})
      local record = (fetch_record(fresh_record["lua-path"]) or fresh_record)
      local _7_ = make_record_loader(record)
      local function _8_()
        local loader = _7_
        return ("function" == type(loader))
      end
      if ((nil ~= _7_) and _8_()) then
        local loader = _7_
        val_19_auto = {loader = loader, modname = record.modname, modpath = record["src-path"]}
      else
        local function _9_()
          local msg = _7_
          return ("string" == type(msg))
        end
        if ((nil ~= _7_) and _9_()) then
          local msg = _7_
          val_19_auto = vim.notify(msg, vim.log.levels.ERROR)
        else
          val_19_auto = nil
        end
      end
    end
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function find_runtime_plugins(plugin_type, glob)
  local _let_12_ = require("hotpot.fs")
  local file_exists_3f = _let_12_["file-exists?"]
  local rm_file = _let_12_["rm-file"]
  local _let_13_ = require("hotpot.searcher")
  local glob_search = _let_13_["glob-search"]
  local _let_14_ = require("hotpot.loader.record")
  local fetch = _let_14_["fetch"]
  local drop = _let_14_["drop"]
  local loaders = generate_runtime_loaders(plugin_type, glob)
  for _, _15_ in ipairs(loaders) do
    local _each_16_ = _15_
    local loader = _each_16_["loader"]
    local modname = _each_16_["modname"]
    local modpath = _each_16_["modpath"]
    local _17_, _18_ = pcall(loader, modname, modpath)
    if ((_17_ == true) and true) then
      local _0 = _18_
    elseif ((_17_ == false) and (nil ~= _18_)) then
      local e = _18_
      vim.notify(e, vim.log.levels.ERROR)
    else
    end
  end
  for _, lua_path in ipairs((glob_search({glob = fmt("lua/hotpot-runtime-%s/**/*.lua", plugin_type), ["all?"] = true}) or {})) do
    local _20_ = fetch(lua_path)
    if (nil ~= _20_) then
      local record = _20_
      if not file_exists_3f(record["src-path"]) then
        rm_file(lua_path)
        drop(record)
      else
      end
    else
    end
  end
  return nil
end
local function find_ftplugins(event)
  local _let_23_ = event
  local filetype = _let_23_["match"]
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s_*.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s/*.fnl", filetype))
  find_runtime_plugins("indent", fmt("indent/%s.fnl", filetype))
  return nil
end
local found_plugins_3f = false
local function find_plugins()
  if not found_plugins_3f then
    found_plugins_3f = true
    return find_runtime_plugins("plugin", "plugin/**/*.fnl")
  else
    return nil
  end
end
local found_after_3f = false
local function find_afters()
  if not found_after_3f then
    found_after_3f = true
    return find_runtime_plugins("after", "after/**/*.fnl")
  else
    return nil
  end
end
local enabled_3f = false
local function enable()
  local _let_26_ = vim.api
  local nvim_create_autocmd = _let_26_["nvim_create_autocmd"]
  local nvim_create_augroup = _let_26_["nvim_create_augroup"]
  local au_group = nvim_create_augroup("hotpot-nvim-runtime-loaders", {})
  if not enabled_3f then
    enabled_3f = true
    nvim_create_autocmd("FileType", {callback = find_ftplugins, desc = "Execute ftplugin/*.fnl files", group = au_group})
    nvim_create_autocmd("User", {callback = find_afters, pattern = "HotpotDelegateFnlAfter", desc = "Execute after/**/*.fnl files", group = au_group})
    if (1 == vim.v.vim_did_enter) then
      return find_plugins()
    else
      return nvim_create_autocmd("VimEnter", {callback = find_plugins, desc = "Execute plugin/**/*.fnl files", once = true, group = au_group})
    end
  else
    return nil
  end
end
local function disable()
  if enabled_3f then
    enabled_3f = false
    return vim.api.nvim_del_autocmd_by_name("hotpot-nvim-runtime-loaders")
  else
    return nil
  end
end
return {enable = enable, disable = disable}