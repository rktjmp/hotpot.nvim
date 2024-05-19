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
  local lua_missing_3f
  local function _7_()
    return file_missing_3f(lua_path)
  end
  lua_missing_3f = _7_
  local function files_changed_3f()
    local stale_3f = false
    for _, historic_file in ipairs(files) do
      if stale_3f then break end
      local _let_8_ = historic_file
      local path = _let_8_["path"]
      local historic_size = _let_8_["size"]
      local _let_9_ = _let_8_["mtime"]
      local hsec = _let_9_["sec"]
      local hnsec = _let_9_["nsec"]
      local _let_10_ = file_stat(path)
      local current_size = _let_10_["size"]
      local _let_11_ = _let_10_["mtime"]
      local csec = _let_11_["sec"]
      local cnsec = _let_11_["nsec"]
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_12_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_12_["compile-record"]
  local _let_13_ = require("hotpot.runtime")
  local config_for_context = _let_13_["config-for-context"]
  local _let_14_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_14_["compiler"]
  local _let_15_ = compiler
  local modules_options = _let_15_["modules"]
  local macros_options = _let_15_["macros"]
  local preprocessor = _let_15_["preprocessor"]
  if needs_compilation_3f(record) then
    local function _16_(...)
      local _17_, _18_ = ...
      if ((_17_ == true) and (nil ~= _18_)) then
        local deps = _18_
        local function _19_(...)
          local _20_, _21_ = ...
          if (nil ~= _20_) then
            local record0 = _20_
            local function _22_(...)
              local _23_, _24_ = ...
              if (nil ~= _23_) then
                local record1 = _23_
                return loadfile(record1["lua-path"])
              elseif ((_23_ == false) and (nil ~= _24_)) then
                local e = _24_
                local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record0["src-path"], e)
                return error(msg, 0)
              else
                local _ = _23_
                return nil
              end
            end
            return _22_(save_record(record0))
          elseif ((_20_ == false) and (nil ~= _21_)) then
            local e = _21_
            local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
            return error(msg, 0)
          else
            local _ = _20_
            return nil
          end
        end
        return _19_(set_record_files(record, deps))
      elseif ((_17_ == false) and (nil ~= _18_)) then
        local e = _18_
        local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
        return error(msg, 0)
      else
        local _ = _17_
        return nil
      end
    end
    return _16_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function handle_cache_lua_path(lua_path_in_cache)
  local _29_ = fetch_record(lua_path_in_cache)
  if (nil ~= _29_) then
    local record = _29_
    if (file_exists_3f(record["src-path"]) and file_missing_3f(record["lua-colocation-path"])) then
      return record_loadfile(record)
    else
      rm_file(lua_path_in_cache)
      drop_record(record)
      return REPEAT_SEARCH
    end
  elseif (_29_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function find_module(modname)
  local function search_by_existing_lua(modname0)
    local _32_ = vim.loader.find(modname0)
    if ((_G.type(_32_) == "table") and ((_G.type(_32_[1]) == "table") and (nil ~= _32_[1].modpath))) then
      local found_lua_path = _32_[1].modpath
      local cache_affix = cache_path_for_compiled_artefact()
      local make_loader
      do
        local _33_ = string.find(found_lua_path, cache_affix, 1, true)
        if (_33_ == 1) then
          make_loader = handle_cache_lua_path
        else
          local _ = _33_
          make_loader = loadfile
        end
      end
      local _35_, _36_ = make_loader(found_lua_path)
      if (_35_ == REPEAT_SEARCH) then
        return search_by_existing_lua(modname0)
      else
        local _3floader = _35_
        return _3floader
      end
    elseif ((_G.type(_32_) == "table") and (_32_[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_39_ = require("hotpot.searcher")
      local mod_search = _let_39_["mod-search"]
      local function _40_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _40_
    end
    local _41_ = search_runtime_path(modname0)
    if ((_G.type(_41_) == "table") and (nil ~= _41_[1])) then
      local src_path = _41_[1]
      local function _42_(...)
        local _43_ = ...
        if (nil ~= _43_) then
          local index = _43_
          local function _44_(...)
            local _45_ = ...
            if (nil ~= _45_) then
              local loader = _45_
              local function _46_(...)
                local _47_, _48_ = ...
                if ((_47_ == false) and (nil ~= _48_)) then
                  local e = _48_
                  return e
                else
                  local __85_auto = _47_
                  return ...
                end
              end
              return _46_(loader)
            else
              local __85_auto = _45_
              return ...
            end
          end
          return _44_(record_loadfile(index))
        else
          local __85_auto = _43_
          return ...
        end
      end
      return _42_(make_module_record(modname0, src_path))
    else
      local _ = _41_
      return false
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_53_ = require("hotpot.searcher")
      local mod_search = _let_53_["mod-search"]
      local function _54_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _54_
    end
    local _55_ = search_package_path(modname0)
    if ((_G.type(_55_) == "table") and (nil ~= _55_[1])) then
      local modpath = _55_[1]
      local _let_56_ = require("hotpot.fennel")
      local dofile = _let_56_["dofile"]
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compiling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _57_()
        return dofile(modpath)
      end
      return _57_
    else
      local _ = _55_
      return false
    end
  end
  local function _59_(...)
    local _60_ = ...
    if (_60_ == false) then
      local function _61_(...)
        local _62_ = ...
        if (_62_ == false) then
          local function _63_(...)
            local _64_ = ...
            if (_64_ == false) then
              return nil
            else
              local _3floader = _64_
              return _3floader
            end
          end
          return _63_(search_by_package_path(modname))
        else
          local _3floader = _62_
          return _3floader
        end
      end
      return _61_(search_by_rtp_fnl(modname))
    else
      local _3floader = _60_
      return _3floader
    end
  end
  return _59_(search_by_existing_lua(modname))
end
local function searcher(modname, ...)
  if not ("hotpot." == string.sub(modname, 1, 7)) then
    return find_module(modname)
  else
    return nil
  end
end
local function make_record_loader(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/init.fnl:160")
  return record_loadfile(record)
end
return {searcher = searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-record-loader"] = make_record_loader}