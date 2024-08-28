local fmt = string["format"]
local nvim_create_autocmd = vim.api["nvim_create_autocmd"]
local nvim_create_augroup = vim.api["nvim_create_augroup"]
local nvim_del_augroup_by_id = vim.api["nvim_del_augroup_by_id"]
local function generate_runtime_loaders(plugin_type, glob, path)
  local _let_1_ = require("hotpot.loader")
  local make_record_loader = _let_1_["make-record-loader"]
  local _let_2_ = require("hotpot.loader.record")
  local fetch_record = _let_2_["fetch"]
  local _let_3_ = require("hotpot.lang.fennel")
  local make_runtime_record = _let_3_["make-runtime-record"]
  local _let_4_ = require("hotpot.searcher")
  local glob_search = _let_4_["glob-search"]
  local _let_5_ = require("hotpot.fs")
  local file_exists_3f = _let_5_["file-exists?"]
  local tbl_21_auto = {}
  local i_22_auto = 0
  for _, fnl_path in ipairs(glob_search({glob = glob, path = path, ["all?"] = true})) do
    local val_23_auto
    local function _6_(...)
      local _7_ = ...
      if (nil ~= _7_) then
        local lua_twin_path = _7_
        local function _8_(...)
          local _9_ = ...
          if (_9_ == false) then
            local plugin_type0 = (string.match(fnl_path, ("/(after)/" .. plugin_type)) or plugin_type)
            local modname = string.gsub(string.match(fnl_path, (plugin_type0 .. "/(.-)%.fnl$")), "/", ".")
            local fresh_record = make_runtime_record(modname, fnl_path, {["runtime-type"] = plugin_type0})
            local record = (fetch_record(fresh_record["lua-path"]) or fresh_record)
            local _10_ = make_record_loader(record)
            local and_11_ = (nil ~= _10_)
            if and_11_ then
              local loader = _10_
              and_11_ = ("function" == type(loader))
            end
            if and_11_ then
              local loader = _10_
              return {loader = loader, modname = record.modname, modpath = record["src-path"]}
            else
              local and_13_ = (nil ~= _10_)
              if and_13_ then
                local msg = _10_
                and_13_ = ("string" == type(msg))
              end
              if and_13_ then
                local msg = _10_
                return vim.notify(msg, vim.log.levels.ERROR)
              else
                return nil
              end
            end
          elseif (_9_ == true) then
            return nil
          else
            return nil
          end
        end
        return _8_(file_exists_3f(lua_twin_path))
      elseif (_7_ == true) then
        return nil
      else
        return nil
      end
    end
    val_23_auto = _6_(string.gsub(fnl_path, "fnl$", "lua"))
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
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
    local loader = _22_["loader"]
    local modname = _22_["modname"]
    local modpath = _22_["modpath"]
    local _23_, _24_ = pcall(loader, modname, modpath)
    if ((_23_ == true) and true) then
      local _0 = _24_
    elseif ((_23_ == false) and (nil ~= _24_)) then
      local e = _24_
      vim.notify(e, vim.log.levels.ERROR)
    else
    end
  end
  for _, s_path in ipairs({"lua/hotpot-runtime-%s/**/*.lua", "lua/hotpot-runtime-after/%s/**/*.lua"}) do
    for _0, lua_path in ipairs(glob_search({glob = fmt(s_path, plugin_type), ["all?"] = true})) do
      local _26_ = fetch(lua_path)
      if (nil ~= _26_) then
        local record = _26_
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
  local filetype = event["match"]
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
      local function _29_()
        return find_runtime_plugins("plugin", "plugin/**/*.fnl")
      end
      return nvim_create_autocmd("VimEnter", {callback = _29_, desc = "Execute plugin/**/*.fnl files", once = true, group = augroup_id})
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