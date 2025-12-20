local fmt = string.format
local _local_1_ = require("hotpot.fs")
local file_exists_3f = _local_1_["file-exists?"]
local file_missing_3f = _local_1_["file-missing?"]
local file_stat = _local_1_["file-stat"]
local rm_file = _local_1_["rm-file"]
local join_path = _local_1_["join-path"]
local _local_2_ = require("hotpot.loader.record")
local fetch_record = _local_2_.fetch
local save_record = _local_2_.save
local drop_record = _local_2_.drop
local set_record_files = _local_2_["set-files"]
local _local_3_ = require("hotpot.lang.fennel")
local make_module_record = _local_3_["make-module-record"]
local REPEAT_SEARCH = "REPEAT_SEARCH"
local function cache_path_for_compiled_artefact(...)
  local _let_4_ = require("hotpot.runtime")
  local cache_root_path = _let_4_["cache-root-path"]
  return join_path(cache_root_path(), "compiled", ...)
end
local function needs_compilation_3f(record)
  local lua_path = record["lua-path"]
  local files = record.files
  local lua_missing_3f
  local function _5_()
    return file_missing_3f(lua_path)
  end
  lua_missing_3f = _5_
  local function files_changed_3f()
    local stale_3f = false
    for _, historic_file in ipairs(files) do
      if stale_3f then break end
      local path = historic_file.path
      local historic_size = historic_file.size
      local _let_6_ = historic_file.mtime
      local hsec = _let_6_.sec
      local hnsec = _let_6_.nsec
      local _let_7_ = file_stat(path)
      local current_size = _let_7_.size
      local _let_8_ = _let_7_.mtime
      local csec = _let_8_.sec
      local cnsec = _let_8_.nsec
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_9_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_9_["compile-record"]
  local _let_10_ = require("hotpot.runtime")
  local config_for_context = _let_10_["config-for-context"]
  local _let_11_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_11_.compiler
  local modules_options = compiler.modules
  local macros_options = compiler.macros
  local preprocessor = compiler.preprocessor
  if needs_compilation_3f(record) then
    local function _12_(...)
      local case_13_, case_14_ = ...
      if ((case_13_ == true) and (nil ~= case_14_)) then
        local deps = case_14_
        local function _15_(...)
          local case_16_, case_17_ = ...
          if (nil ~= case_16_) then
            local record0 = case_16_
            local function _18_(...)
              local case_19_, case_20_ = ...
              if (nil ~= case_19_) then
                local record1 = case_19_
                return loadfile(record1["lua-path"])
              elseif ((case_19_ == false) and (nil ~= case_20_)) then
                local e = case_20_
                local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record0["src-path"], e)
                return error(msg, 0)
              else
                local _ = case_19_
                return nil
              end
            end
            return _18_(save_record(record0))
          elseif ((case_16_ == false) and (nil ~= case_17_)) then
            local e = case_17_
            local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
            return error(msg, 0)
          else
            local _ = case_16_
            return nil
          end
        end
        return _15_(set_record_files(record, deps))
      elseif ((case_13_ == false) and (nil ~= case_14_)) then
        local e = case_14_
        local msg = fmt("\nHotpot could not compile the file `%s`:\n\n%s", record["src-path"], e)
        return error(msg, 0)
      else
        local _ = case_13_
        return nil
      end
    end
    return _12_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function handle_cache_lua_path(lua_path_in_cache)
  local case_25_ = fetch_record(lua_path_in_cache)
  if (nil ~= case_25_) then
    local record = case_25_
    if (file_exists_3f(record["src-path"]) and file_missing_3f(record["lua-colocation-path"])) then
      return record_loadfile(record)
    else
      rm_file(lua_path_in_cache)
      drop_record(record)
      return REPEAT_SEARCH
    end
  elseif (case_25_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function find_module(modname)
  local function search_by_preload(modname0)
    return (package.preload[modname0] or false)
  end
  local function search_by_existing_lua(modname0)
    local case_28_ = vim.loader.find(modname0)
    if ((_G.type(case_28_) == "table") and ((_G.type(case_28_[1]) == "table") and (nil ~= case_28_[1].modpath))) then
      local found_lua_path = case_28_[1].modpath
      local cache_affix = cache_path_for_compiled_artefact()
      local make_loader
      do
        local case_29_ = string.find(found_lua_path, cache_affix, 1, true)
        if (case_29_ == 1) then
          make_loader = handle_cache_lua_path
        else
          local _ = case_29_
          make_loader = loadfile
        end
      end
      local case_31_, case_32_ = make_loader(found_lua_path)
      if (case_31_ == REPEAT_SEARCH) then
        return search_by_existing_lua(modname0)
      else
        local _3floader = case_31_
        return _3floader
      end
    elseif ((_G.type(case_28_) == "table") and (case_28_[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_35_ = require("hotpot.searcher")
      local mod_search = _let_35_["mod-search"]
      local function _36_(modname1)
        return mod_search({prefix = "fnl", extensions = {"fnl"}, modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _36_
    end
    local case_37_ = search_runtime_path(modname0)
    if ((_G.type(case_37_) == "table") and (nil ~= case_37_[1])) then
      local src_path = case_37_[1]
      local function _38_(...)
        if (nil ~= ...) then
          local index = ...
          local function _39_(...)
            if (nil ~= ...) then
              local loader = ...
              local function _40_(...)
                local case_41_, case_42_ = ...
                if ((case_41_ == false) and (nil ~= case_42_)) then
                  local e = case_42_
                  return e
                else
                  local __43_ = case_41_
                  return ...
                end
              end
              return _40_(loader)
            else
              local __43_ = ...
              return ...
            end
          end
          return _39_(record_loadfile(index))
        else
          local __43_ = ...
          return ...
        end
      end
      return _38_(make_module_record(modname0, src_path))
    else
      local _ = case_37_
      return false
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_47_ = require("hotpot.searcher")
      local mod_search = _let_47_["mod-search"]
      local function _48_(modname1)
        return mod_search({prefix = "fnl", extensions = {"fnl"}, modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _48_
    end
    local case_49_ = search_package_path(modname0)
    if ((_G.type(case_49_) == "table") and (nil ~= case_49_[1])) then
      local modpath = case_49_[1]
      local _let_50_ = require("hotpot.fennel")
      local dofile = _let_50_.dofile
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compiling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _51_()
        return dofile(modpath)
      end
      return _51_
    else
      local _ = case_49_
      return false
    end
  end
  local function _53_(...)
    if (... == false) then
      local function _54_(...)
        if (... == false) then
          local function _55_(...)
            if (... == false) then
              local function _56_(...)
                if (... == false) then
                  return nil
                else
                  local _3floader = ...
                  return _3floader
                end
              end
              return _56_(search_by_package_path(modname))
            else
              local _3floader = ...
              return _3floader
            end
          end
          return _55_(search_by_rtp_fnl(modname))
        else
          local _3floader = ...
          return _3floader
        end
      end
      return _54_(search_by_existing_lua(modname))
    else
      local _3floader = ...
      return _3floader
    end
  end
  return _53_(search_by_preload(modname))
end
local function searcher(modname, ...)
  if not ("hotpot." == string.sub(modname, 1, 7)) then
    return find_module(modname)
  else
    return nil
  end
end
local function make_record_loader(record)
  if (nil == record) then
    _G.error("Missing argument record on fnl/hotpot/loader/init.fnl:197", 2)
  else
  end
  return record_loadfile(record)
end
return {searcher = searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-record-loader"] = make_record_loader}