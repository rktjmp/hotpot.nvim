local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = vim.api
local nvim_create_autocmd = _local_2_["nvim_create_autocmd"]
local nvim_create_augroup = _local_2_["nvim_create_augroup"]
local nvim_del_augroup_by_id = _local_2_["nvim_del_augroup_by_id"]
local function generate_runtime_loaders(plugin_type, glob, path)
  local _let_3_ = require("hotpot.loader")
  local make_record_loader = _let_3_["make-record-loader"]
  local _let_4_ = require("hotpot.loader.record")
  local fetch_record = _let_4_["fetch"]
  local _let_5_ = require("hotpot.lang.fennel")
  local make_runtime_record = _let_5_["make-runtime-record"]
  local _let_6_ = require("hotpot.searcher")
  local glob_search = _let_6_["glob-search"]
  local _let_7_ = require("hotpot.fs")
  local file_exists_3f = _let_7_["file-exists?"]
  local tbl_19_auto = {}
  local i_20_auto = 0
  for _, fnl_path in ipairs(glob_search({glob = glob, path = path, ["all?"] = true})) do
    local val_21_auto
    local function _8_(...)
      local _9_ = ...
      if (nil ~= _9_) then
        local lua_twin_path = _9_
        local function _10_(...)
          local _11_ = ...
          if (_11_ == false) then
            local plugin_type0 = (string.match(fnl_path, ("/(after)/" .. plugin_type)) or plugin_type)
            local modname = string.gsub(string.match(fnl_path, (plugin_type0 .. "/(.-)%.fnl$")), "/", ".")
            local fresh_record = make_runtime_record(modname, fnl_path, {["runtime-type"] = plugin_type0})
            local record = (fetch_record(fresh_record["lua-path"]) or fresh_record)
            local _12_ = make_record_loader(record)
            local function _13_(...)
              local loader = _12_
              return ("function" == type(loader))
            end
            if ((nil ~= _12_) and _13_(...)) then
              local loader = _12_
              return {loader = loader, modname = record.modname, modpath = record["src-path"]}
            else
              local function _14_(...)
                local msg = _12_
                return ("string" == type(msg))
              end
              if ((nil ~= _12_) and _14_(...)) then
                local msg = _12_
                return vim.notify(msg, vim.log.levels.ERROR)
              else
                return nil
              end
            end
          elseif (_11_ == true) then
            return nil
          else
            return nil
          end
        end
        return _10_(file_exists_3f(lua_twin_path))
      elseif (_9_ == true) then
        return nil
      else
        return nil
      end
    end
    val_21_auto = _8_(string.gsub(fnl_path, "fnl$", "lua"))
    if (nil ~= val_21_auto) then
      i_20_auto = (i_20_auto + 1)
      do end (tbl_19_auto)[i_20_auto] = val_21_auto
    else
    end
  end
  return tbl_19_auto
end
local function find_runtime_plugins(plugin_type, glob, _3fpath)
  local _let_19_ = require("hotpot.fs")
  local file_exists_3f = _let_19_["file-exists?"]
  local rm_file = _let_19_["rm-file"]
  local _let_20_ = require("hotpot.searcher")
  local glob_search = _let_20_["glob-search"]
  local _let_21_ = require("hotpot.loader.record")
  local fetch = _let_21_["fetch"]
  local drop = _let_21_["drop"]
  local path = (_3fpath or vim.go.rtp)
  local loaders = generate_runtime_loaders(plugin_type, glob, path)
  for _, _22_ in ipairs(loaders) do
    local _each_23_ = _22_
    local loader = _each_23_["loader"]
    local modname = _each_23_["modname"]
    local modpath = _each_23_["modpath"]
    local _24_, _25_ = pcall(loader, modname, modpath)
    if ((_24_ == true) and true) then
      local _0 = _25_
    elseif ((_24_ == false) and (nil ~= _25_)) then
      local e = _25_
      vim.notify(e, vim.log.levels.ERROR)
    else
    end
  end
  for _, s_path in ipairs({"lua/hotpot-runtime-%s/**/*.lua", "lua/hotpot-runtime-after/%s/**/*.lua"}) do
    for _0, lua_path in ipairs(glob_search({glob = fmt(s_path, plugin_type), ["all?"] = true})) do
      local _27_ = fetch(lua_path)
      if (nil ~= _27_) then
        local record = _27_
        if not file_exists_3f(record["src-path"]) then
          rm_file(lua_path)
          drop(record)
        else
        end
      else
      end
    end
  end
  return nil
end
local function find_ftplugins(event)
  local _let_30_ = event
  local filetype = _let_30_["match"]
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s_*.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s/*.fnl", filetype))
  find_runtime_plugins("indent", fmt("indent/%s.fnl", filetype))
  return nil
end
local enabled_3f = false
local augroup_id = nil
local function enable()
  if (vim.go.loadplugins and not enabled_3f) then
    augroup_id = nvim_create_augroup("hotpot-nvim-runtime-loaders", {})
    enabled_3f = true
    nvim_create_autocmd("FileType", {callback = find_ftplugins, desc = "Execute ftplugin/*.fnl files", group = augroup_id})
    if (1 == vim.v.vim_did_enter) then
      return find_runtime_plugins("plugin", "plugin/**/*.fnl")
    else
      local function _31_()
        return find_runtime_plugins("plugin", "plugin/**/*.fnl")
      end
      return nvim_create_autocmd("VimEnter", {callback = _31_, desc = "Execute plugin/**/*.fnl files", once = true, group = augroup_id})
    end
  else
    return nil
  end
end
local function disable()
  if augroup_id then
    nvim_del_augroup_by_id(augroup_id)
    augroup_id = nil
    enabled_3f = false
    return nil
  else
    return nil
  end
end
return {enable = enable, disable = disable}