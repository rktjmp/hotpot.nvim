local _local_1_ = string
local fmt = _local_1_["format"]
local function generate_runtime_loaders(plugin_type, glob, path)
  local _let_2_ = require("hotpot.loader")
  local make_record_loader = _let_2_["make-record-loader"]
  local _let_3_ = require("hotpot.loader.record")
  local fetch_record = _let_3_["fetch"]
  local _let_4_ = require("hotpot.lang.fennel")
  local make_runtime_record = _let_4_["make-runtime-record"]
  local _let_5_ = require("hotpot.searcher")
  local glob_search = _let_5_["glob-search"]
  local _let_6_ = require("hotpot.fs")
  local file_exists_3f = _let_6_["file-exists?"]
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, fnl_path in ipairs(glob_search({glob = glob, path = path, ["all?"] = true})) do
    local val_19_auto
    local function _7_(...)
      local _8_ = ...
      if (nil ~= _8_) then
        local lua_twin_path = _8_
        local function _9_(...)
          local _10_ = ...
          if (_10_ == false) then
            local plugin_type0 = (string.match(fnl_path, ("/(after)/" .. plugin_type)) or plugin_type)
            local modname = string.gsub(string.match(fnl_path, (plugin_type0 .. "/(.-)%.fnl$")), "/", ".")
            local fresh_record = make_runtime_record(modname, fnl_path, {["runtime-type"] = plugin_type0})
            local record = (fetch_record(fresh_record["lua-path"]) or fresh_record)
            local _11_ = make_record_loader(record)
            local function _12_(...)
              local loader = _11_
              return ("function" == type(loader))
            end
            if ((nil ~= _11_) and _12_(...)) then
              local loader = _11_
              return {loader = loader, modname = record.modname, modpath = record["src-path"]}
            else
              local function _13_(...)
                local msg = _11_
                return ("string" == type(msg))
              end
              if ((nil ~= _11_) and _13_(...)) then
                local msg = _11_
                return vim.notify(msg, vim.log.levels.ERROR)
              else
                return nil
              end
            end
          elseif (_10_ == true) then
            return nil
          else
            return nil
          end
        end
        return _9_(file_exists_3f(lua_twin_path))
      elseif (_8_ == true) then
        return nil
      else
        return nil
      end
    end
    val_19_auto = _7_(string.gsub(fnl_path, "fnl$", "lua"))
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function find_runtime_plugins(plugin_type, glob, _3fpath)
  local _let_18_ = require("hotpot.fs")
  local file_exists_3f = _let_18_["file-exists?"]
  local rm_file = _let_18_["rm-file"]
  local _let_19_ = require("hotpot.searcher")
  local glob_search = _let_19_["glob-search"]
  local _let_20_ = require("hotpot.loader.record")
  local fetch = _let_20_["fetch"]
  local drop = _let_20_["drop"]
  local path = (_3fpath or vim.go.rtp)
  local loaders = generate_runtime_loaders(plugin_type, glob, path)
  for _, _21_ in ipairs(loaders) do
    local _each_22_ = _21_
    local loader = _each_22_["loader"]
    local modname = _each_22_["modname"]
    local modpath = _each_22_["modpath"]
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
  local _let_29_ = event
  local filetype = _let_29_["match"]
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s_*.fnl", filetype))
  find_runtime_plugins("ftplugin", fmt("ftplugin/%s/*.fnl", filetype))
  find_runtime_plugins("indent", fmt("indent/%s.fnl", filetype))
  return nil
end
local enabled_3f = false
local function enable()
  local _let_30_ = vim.api
  local nvim_create_autocmd = _let_30_["nvim_create_autocmd"]
  local nvim_create_augroup = _let_30_["nvim_create_augroup"]
  local au_group = nvim_create_augroup("hotpot-nvim-runtime-loaders", {})
  if (vim.go.loadplugins and not enabled_3f) then
    enabled_3f = true
    nvim_create_autocmd("FileType", {callback = find_ftplugins, desc = "Execute ftplugin/*.fnl files", group = au_group})
    if (1 == vim.v.vim_did_enter) then
      return find_runtime_plugins("plugin", "plugin/**/*.fnl")
    else
      local function _31_()
        return find_runtime_plugins("plugin", "plugin/**/*.fnl")
      end
      return nvim_create_autocmd("VimEnter", {callback = _31_, desc = "Execute plugin/**/*.fnl files", once = true, group = au_group})
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