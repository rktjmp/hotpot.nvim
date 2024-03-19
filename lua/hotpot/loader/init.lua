local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = require("hotpot.fs")
local file_exists_3f = _local_2_["file-exists?"]
local file_missing_3f = _local_2_["file-missing?"]
local file_stat = _local_2_["file-stat"]
local rm_file = _local_2_["rm-file"]
local join_path = _local_2_["join-path"]
local _local_3_ = require("hotpot.loader.record")
local fetch_record = _local_3_["fetch"]
local save_record = _local_3_["save"]
local drop_record = _local_3_["drop"]
local set_record_files = _local_3_["set-files"]
local _local_4_ = require("hotpot.lang.fennel")
local make_module_record = _local_4_["make-module-record"]
local REPEAT_SEARCH = "REPEAT_SEARCH"
local function cache_path_for_compiled_artefact(...)
  local _let_5_ = require("hotpot.runtime")
  local cache_root_path = _let_5_["cache-root-path"]
  return join_path(cache_root_path(), "compiled", ...)
end
local function needs_compilation_3f(record)
  local _let_6_ = record
  local lua_path = _let_6_["lua-path"]
  local files = _let_6_["files"]
  local function lua_missing_3f()
    return file_missing_3f(record["lua-path"])
  end
  local function files_changed_3f()
    local stale_3f = false
    for _, historic_file in ipairs(files) do
      if stale_3f then break end
      local _let_7_ = historic_file
      local path = _let_7_["path"]
      local historic_size = _let_7_["size"]
      local _let_8_ = _let_7_["mtime"]
      local hsec = _let_8_["sec"]
      local hnsec = _let_8_["nsec"]
      local _let_9_ = file_stat(path)
      local current_size = _let_9_["size"]
      local _let_10_ = _let_9_["mtime"]
      local csec = _let_10_["sec"]
      local cnsec = _let_10_["nsec"]
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_11_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_11_["compile-record"]
  local _let_12_ = require("hotpot.runtime")
  local config_for_context = _let_12_["config-for-context"]
  local _let_13_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_13_["compiler"]
  local _let_14_ = compiler
  local modules_options = _let_14_["modules"]
  local macros_options = _let_14_["macros"]
  local preprocessor = _let_14_["preprocessor"]
  if needs_compilation_3f(record) then
    local function _15_(...)
      local _16_, _17_ = ...
      if ((_16_ == true) and (nil ~= _17_)) then
        local deps = _17_
        local function _18_(...)
          local _19_, _20_ = ...
          if (nil ~= _19_) then
            local record0 = _19_
            local function _21_(...)
              local _22_, _23_ = ...
              if (nil ~= _22_) then
                local record1 = _22_
                return loadfile(record1["lua-path"])
              elseif ((_22_ == false) and (nil ~= _23_)) then
                local e = _23_
                local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record0["src-path"], e)
                return error(msg, 0)
              else
                local _ = _22_
                return nil
              end
            end
            return _21_(save_record(record0))
          elseif ((_19_ == false) and (nil ~= _20_)) then
            local e = _20_
            local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
            return error(msg, 0)
          else
            local _ = _19_
            return nil
          end
        end
        return _18_(set_record_files(record, deps))
      elseif ((_16_ == false) and (nil ~= _17_)) then
        local e = _17_
        local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
        return error(msg, 0)
      else
        local _ = _16_
        return nil
      end
    end
    return _15_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function handle_cache_lua_path(lua_path_in_cache)
  local _28_ = fetch_record(lua_path_in_cache)
  if (nil ~= _28_) then
    local record = _28_
    if (file_exists_3f(record["src-path"]) and file_missing_3f(record["lua-colocation-path"])) then
      return record_loadfile(record)
    else
      rm_file(lua_path_in_cache)
      drop_record(record)
      return REPEAT_SEARCH
    end
  elseif (_28_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function find_module(modname)
  local function search_by_existing_lua(modname0)
    local _31_ = vim.loader.find(modname0)
    if ((_G.type(_31_) == "table") and ((_G.type(_31_[1]) == "table") and (nil ~= _31_[1].modpath))) then
      local found_lua_path = _31_[1].modpath
      local cache_affix = cache_path_for_compiled_artefact()
      local make_loader
      do
        local _32_ = string.find(found_lua_path, cache_affix, 1, true)
        if (_32_ == 1) then
          make_loader = handle_cache_lua_path
        else
          local _ = _32_
          make_loader = loadfile
        end
      end
      local _34_, _35_ = make_loader(found_lua_path)
      if (_34_ == REPEAT_SEARCH) then
        return search_by_existing_lua(modname0)
      else
        local _3floader = _34_
        return _3floader
      end
    elseif ((_G.type(_31_) == "table") and (_31_[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_38_ = require("hotpot.searcher")
      local mod_search = _let_38_["mod-search"]
      local function _39_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _39_
    end
    local _40_ = search_runtime_path(modname0)
    if ((_G.type(_40_) == "table") and (nil ~= _40_[1])) then
      local src_path = _40_[1]
      local function _41_(...)
        local _42_ = ...
        if (nil ~= _42_) then
          local index = _42_
          local function _43_(...)
            local _44_ = ...
            if (nil ~= _44_) then
              local loader = _44_
              local function _45_(...)
                local _46_, _47_ = ...
                if ((_46_ == false) and (nil ~= _47_)) then
                  local e = _47_
                  return e
                else
                  local __85_auto = _46_
                  return ...
                end
              end
              return _45_(loader)
            else
              local __85_auto = _44_
              return ...
            end
          end
          return _43_(record_loadfile(index))
        else
          local __85_auto = _42_
          return ...
        end
      end
      return _41_(make_module_record(modname0, src_path))
    else
      local _ = _40_
      return false
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_52_ = require("hotpot.searcher")
      local mod_search = _let_52_["mod-search"]
      local function _53_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _53_
    end
    local _54_ = search_package_path(modname0)
    if ((_G.type(_54_) == "table") and (nil ~= _54_[1])) then
      local modpath = _54_[1]
      local _let_55_ = require("hotpot.fennel")
      local dofile = _let_55_["dofile"]
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compiling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _56_()
        return dofile(modpath)
      end
      return _56_
    else
      local _ = _54_
      return false
    end
  end
  local function _58_(...)
    local _59_ = ...
    if (_59_ == false) then
      local function _60_(...)
        local _61_ = ...
        if (_61_ == false) then
          local function _62_(...)
            local _63_ = ...
            if (_63_ == false) then
              return nil
            else
              local _3floader = _63_
              return _3floader
            end
          end
          return _62_(search_by_package_path(modname))
        else
          local _3floader = _61_
          return _3floader
        end
      end
      return _60_(search_by_rtp_fnl(modname))
    else
      local _3floader = _59_
      return _3floader
    end
  end
  return _58_(search_by_existing_lua(modname))
end
local function searcher(modname, ...)
  if not ("hotpot." == string.sub(modname, 1, 7)) then
    return find_module(modname)
  else
    return nil
  end
end
local function make_record_loader(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/init.fnl:161")
  return record_loadfile(record)
end
return {searcher = searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-record-loader"] = make_record_loader}