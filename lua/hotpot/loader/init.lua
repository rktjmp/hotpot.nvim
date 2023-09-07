local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = require("hotpot.fs")
local file_exists_3f = _local_2_["file-exists?"]
local file_missing_3f = _local_2_["file-missing?"]
local file_stat = _local_2_["file-stat"]
local rm_file = _local_2_["rm-file"]
local join_path = _local_2_["join-path"]
local REPEAT_SEARCH = "REPEAT_SEARCH"
local function cache_path_for_compiled_artefact(...)
  local _let_3_ = require("hotpot.runtime")
  local cache_root_path = _let_3_["cache-root-path"]
  return join_path(cache_root_path(), "compiled", ...)
end
local _local_4_ = require("hotpot.loader.record")
local fetch_index = _local_4_["fetch"]
local save_index = _local_4_["save"]
local drop_index = _local_4_["drop"]
local lua_file_modified_3f = _local_4_["lua-file-modified?"]
local replace_index_files = _local_4_["set-record-files"]
local _local_5_ = require("hotpot.lang.fennel")
local make_module_record = _local_5_["make-module-record"]
local _local_6_ = require("hotpot.loader.record.module")
local set_index_target_cache = _local_6_["retarget-cache"]
local set_index_target_colocation = _local_6_["retarget-colocation"]
local _local_7_ = require("hotpot.loader.sigil")
local wants_colocation_3f = _local_7_["wants-colocation?"]
local function needs_cleanup()
  return "TODO"
end
local function bust_vim_loader_index(record)
  if record["cache-root-path"] then
    vim.loader.reset(record["cache-root-path"])
  else
  end
  if record["colocation-root-path"] then
    vim.loader.reset(record["colocation-root-path"])
  else
  end
  return true
end
local function needs_compilation_3f(record)
  local _let_10_ = record
  local lua_path = _let_10_["lua-path"]
  local files = _let_10_["files"]
  local function lua_missing_3f()
    return file_missing_3f(record["lua-path"])
  end
  local function files_changed_3f()
    local stale_3f = false
    for _, _11_ in ipairs(files) do
      local _each_12_ = _11_
      local path = _each_12_["path"]
      local historic_size = _each_12_["size"]
      local _each_13_ = _each_12_["mtime"]
      local hsec = _each_13_["sec"]
      local hnsec = _each_13_["nsec"]
      if stale_3f then break end
      local _let_14_ = file_stat(path)
      local current_size = _let_14_["size"]
      local _let_15_ = _let_14_["mtime"]
      local csec = _let_15_["sec"]
      local cnsec = _let_15_["nsec"]
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_16_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_16_["compile-record"]
  local _let_17_ = require("hotpot.runtime")
  local config_for_context = _let_17_["config-for-context"]
  local _let_18_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_18_["compiler"]
  local _let_19_ = compiler
  local modules_options = _let_19_["modules"]
  local macros_options = _let_19_["macros"]
  local preprocessor = _let_19_["preprocessor"]
  if needs_compilation_3f(record) then
    local function _20_(...)
      local _21_, _22_ = ...
      if ((_21_ == true) and (nil ~= _22_)) then
        local deps = _22_
        local function _23_(...)
          local _24_, _25_ = ...
          if (nil ~= _24_) then
            local record0 = _24_
            local function _26_(...)
              local _27_, _28_ = ...
              if (nil ~= _27_) then
                local record1 = _27_
                local function _29_(...)
                  local _30_, _31_ = ...
                  if true then
                    local _ = _30_
                    local function _32_(...)
                      local _33_, _34_ = ...
                      if (_33_ == "TODO") then
                        return loadfile(record1["lua-path"])
                      elseif ((_33_ == false) and (nil ~= _34_)) then
                        local e = _34_
                        return e
                      elseif true then
                        local _0 = _33_
                        return nil
                      else
                        return nil
                      end
                    end
                    return _32_(needs_cleanup())
                  elseif ((_30_ == false) and (nil ~= _31_)) then
                    local e = _31_
                    return e
                  elseif true then
                    local _ = _30_
                    return nil
                  else
                    return nil
                  end
                end
                return _29_(bust_vim_loader_index(record1))
              elseif ((_27_ == false) and (nil ~= _28_)) then
                local e = _28_
                return e
              elseif true then
                local _ = _27_
                return nil
              else
                return nil
              end
            end
            return _26_(save_index(record0))
          elseif ((_24_ == false) and (nil ~= _25_)) then
            local e = _25_
            return e
          elseif true then
            local _ = _24_
            return nil
          else
            return nil
          end
        end
        return _23_(replace_index_files(record, deps))
      elseif ((_21_ == false) and (nil ~= _22_)) then
        local e = _22_
        return e
      elseif true then
        local _ = _21_
        return nil
      else
        return nil
      end
    end
    return _20_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function query_user(prompt, ...)
  local function _42_(...)
    local l = {{}, {}}
    for _, _43_ in ipairs({...}) do
      local _each_44_ = _43_
      local option = _each_44_[1]
      local action = _each_44_[2]
      table.insert(l[1], option)
      table.insert(l[2], action)
      l = l
    end
    return l
  end
  local _let_41_ = _42_(...)
  local options = _let_41_[1]
  local actions = _let_41_[2]
  local action = nil
  local function on_choice(item, index)
    if (index == nil) then
      vim.notify("\nNo response, doing nothing and passing on to the next lua loader.\n", vim.log.levels.WARN)
      local function _45_()
        return nil
      end
      action = _45_
      return nil
    elseif (nil ~= index) then
      local n = index
      action = actions[n]
      return nil
    else
      return nil
    end
  end
  vim.ui.select(options, {prompt = prompt}, on_choice)
  return action()
end
local function handle_cache_lua_path(modname, lua_path_in_cache)
  local function has_overwrite_permission_3f(lua_path, src_path)
    local function _47_()
      return true
    end
    local function _48_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _47_}, {"No, keep the lua file and dont ask again.", _48_})
  end
  local function clean_cache_and_compile(lua_path_in_cache0, record)
    local function _49_(...)
      local _50_ = ...
      if (_50_ == true) then
        local function _51_(...)
          local _52_ = ...
          if (_52_ == true) then
            local function _53_(...)
              local _54_ = ...
              if (nil ~= _54_) then
                local record0 = _54_
                local function _55_(...)
                  local _56_ = ...
                  if (nil ~= _56_) then
                    local record1 = _56_
                    return record_loadfile(record1)
                  elseif true then
                    local __75_auto = _56_
                    return ...
                  else
                    return nil
                  end
                end
                return _55_(set_index_target_colocation(record0))
              elseif true then
                local __75_auto = _54_
                return ...
              else
                return nil
              end
            end
            return _53_(make_module_record(modname, record["src-path"]))
          elseif true then
            local __75_auto = _52_
            return ...
          else
            return nil
          end
        end
        return _51_(drop_index(record))
      elseif true then
        local __75_auto = _50_
        return ...
      else
        return nil
      end
    end
    return _49_(rm_file(lua_path_in_cache0))
  end
  local _61_ = fetch_index(lua_path_in_cache)
  if (nil ~= _61_) then
    local record = _61_
    if file_exists_3f(record["src-path"]) then
      if wants_colocation_3f(record["sigil-path"]) then
        if file_exists_3f(record["lua-colocation-path"]) then
          if has_overwrite_permission_3f(record["lua-colocation-path"], record["src-path"]) then
            return clean_cache_and_compile(lua_path_in_cache, record)
          else
            rm_file(lua_path_in_cache)
            drop_index(record)
            return loadfile(record["lua-colocation-path"])
          end
        else
          return clean_cache_and_compile(lua_path_in_cache, record)
        end
      else
        return record_loadfile(record)
      end
    else
      rm_file(lua_path_in_cache)
      drop_index(record)
      return REPEAT_SEARCH
    end
  elseif (_61_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function _68_(...)
  local function handler_for_missing_fnl(modname, lua_path, record)
    if file_missing_3f(record["src-path"]) then
      if lua_file_modified_3f(record) then
        local function _69_()
          rm_file(lua_path)
          drop_index(record)
          local function _70_()
            return REPEAT_SEARCH
          end
          return _70_
        end
        local function _71_()
          drop_index(record)
          local function _72_()
            return loadfile(lua_path)
          end
          return _72_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but the original fennel source file has been removed.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file.", _69_}, {"No, keep the lua file, dont ask again.", _71_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _73_()
          return REPEAT_SEARCH
        end
        return _73_
      end
    else
      return nil
    end
  end
  local function handler_for_colocation_denied(modname, lua_path, record)
    if not wants_colocation_3f(record["sigil-path"]) then
      if lua_file_modified_3f(record) then
        local function _76_()
          rm_file(lua_path)
          drop_index(record)
          local function _77_()
            return REPEAT_SEARCH
          end
          return _77_
        end
        local function _78_()
          drop_index(record)
          local function _79_()
            return loadfile(lua_path)
          end
          return _79_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but colocation permission have been denied.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file and try to recompile into cache.", _76_}, {"No, keep the lua file, dont ask again.", _78_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _80_()
          return REPEAT_SEARCH
        end
        return _80_
      end
    else
      return nil
    end
  end
  local function handler_for_changes_overwrite(modname, lua_path, record)
    if (needs_compilation_3f(record) and lua_file_modified_3f(record)) then
      local function _83_()
        local function _84_()
          return record_loadfile(record)
        end
        return _84_
      end
      local function _85_()
        local function _86_()
          return loadfile(lua_path)
        end
        return _86_
      end
      return query_user(fmt(("The file %s was built by Hotpot but changes have been made to the file by something else.\n" .. "Continuing will overwrite those changes\n" .. "Overwrite lua with new code?"), lua_path), {"Yes, recompile the fennel source.", _83_}, {"No, keep the lua file for now.", _85_})
    else
      return nil
    end
  end
  local function handler_for_known_colocation(modname, lua_path, record)
    local function _88_(...)
      local _89_ = ...
      if (_89_ == nil) then
        local function _90_(...)
          local _91_ = ...
          if (_91_ == nil) then
            local function _92_(...)
              local _93_ = ...
              if (_93_ == nil) then
                return record_loadfile(record)
              elseif (nil ~= _93_) then
                local func = _93_
                return func()
              else
                return nil
              end
            end
            return _92_(handler_for_changes_overwrite(modname, lua_path, record))
          elseif (nil ~= _91_) then
            local func = _91_
            return func()
          else
            return nil
          end
        end
        return _90_(handler_for_colocation_denied(modname, lua_path, record))
      elseif (nil ~= _89_) then
        local func = _89_
        return func()
      else
        return nil
      end
    end
    return _88_(handler_for_missing_fnl(modname, lua_path, record))
  end
  return {["handler-for-known-colocation"] = handler_for_known_colocation}
end
local _local_67_ = _68_(...)
local handler_for_known_colocation = _local_67_["handler-for-known-colocation"]
local function _98_(...)
  local function has_overwrite_permission_3f(lua_path, src_path)
    local function _99_()
      return true
    end
    local function _100_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _99_}, {"No, keep the lua file for now.", _100_})
  end
  local function handler_for_unknown_colocation(modname, lua_path)
    local _let_101_ = make_module_record(modname, lua_path, {["unsafely?"] = true})
    local sigil_path = _let_101_["sigil-path"]
    local src_path = _let_101_["src-path"]
    if (file_exists_3f(src_path) and wants_colocation_3f(sigil_path) and has_overwrite_permission_3f(lua_path, src_path)) then
      local function _102_(...)
        local _103_ = ...
        if (nil ~= _103_) then
          local record = _103_
          local function _104_(...)
            local _105_ = ...
            if (nil ~= _105_) then
              local record0 = _105_
              local function _106_(...)
                local _107_ = ...
                if (nil ~= _107_) then
                  local loader = _107_
                  local function _108_(...)
                    local _109_, _110_ = ...
                    if ((_109_ == false) and (nil ~= _110_)) then
                      local e = _110_
                      return e
                    elseif true then
                      local __75_auto = _109_
                      return ...
                    else
                      return nil
                    end
                  end
                  return _108_(loader)
                elseif true then
                  local __75_auto = _107_
                  return ...
                else
                  return nil
                end
              end
              return _106_(record_loadfile(record0))
            elseif true then
              local __75_auto = _105_
              return ...
            else
              return nil
            end
          end
          return _104_(set_index_target_colocation(record))
        elseif true then
          local __75_auto = _103_
          return ...
        else
          return nil
        end
      end
      return _102_(make_module_record(modname, src_path))
    else
      return loadfile(lua_path)
    end
  end
  return {["handler-for-unknown-colocation"] = handler_for_unknown_colocation}
end
local _local_97_ = _98_(...)
local handler_for_unknown_colocation = _local_97_["handler-for-unknown-colocation"]
local function handle_colo_lua_path(modname, lua_path)
  local _116_ = fetch_index(lua_path)
  if (nil ~= _116_) then
    local record = _116_
    return handler_for_known_colocation(modname, lua_path, record)
  elseif (_116_ == nil) then
    return handler_for_unknown_colocation(modname, lua_path)
  else
    return nil
  end
end
local function find_module(modname)
  local function infer_lua_path_type(path)
    local cache_affix = fmt("^%s", vim.pesc(cache_path_for_compiled_artefact()))
    local _118_ = path:find(cache_affix)
    if (_118_ == 1) then
      return "cache"
    elseif true then
      local _ = _118_
      return "colocate"
    else
      return nil
    end
  end
  local function search_by_existing_lua(modname0)
    local _120_ = vim.loader.find(modname0)
    if ((_G.type(_120_) == "table") and ((_G.type((_120_)[1]) == "table") and (nil ~= ((_120_)[1]).modpath))) then
      local found_lua_path = ((_120_)[1]).modpath
      local f
      do
        local _121_ = infer_lua_path_type(found_lua_path)
        if (_121_ == "cache") then
          f = handle_cache_lua_path
        elseif (_121_ == "colocate") then
          f = handle_colo_lua_path
        else
          f = nil
        end
      end
      local _123_, _124_ = f(modname0, found_lua_path)
      if (_123_ == REPEAT_SEARCH) then
        return find_module(modname0)
      elseif true then
        local _3floader = _123_
        return _3floader
      else
        return nil
      end
    elseif ((_G.type(_120_) == "table") and ((_120_)[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_127_ = require("hotpot.searcher")
      local search = _let_127_["search"]
      local function _128_(modname1)
        return search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _128_
    end
    local _129_ = search_runtime_path(modname0)
    if ((_G.type(_129_) == "table") and (nil ~= (_129_)[1])) then
      local src_path = (_129_)[1]
      local function _130_(...)
        local _131_ = ...
        if (nil ~= _131_) then
          local index = _131_
          local function _132_(...)
            local _133_ = ...
            if (nil ~= _133_) then
              local index0 = _133_
              local function _134_(...)
                local _135_ = ...
                if (nil ~= _135_) then
                  local loader = _135_
                  local function _136_(...)
                    local _137_, _138_ = ...
                    if ((_137_ == false) and (nil ~= _138_)) then
                      local e = _138_
                      return e
                    elseif true then
                      local __75_auto = _137_
                      return ...
                    else
                      return nil
                    end
                  end
                  return _136_(loader)
                elseif true then
                  local __75_auto = _135_
                  return ...
                else
                  return nil
                end
              end
              return _134_(record_loadfile(index0))
            elseif true then
              local __75_auto = _133_
              return ...
            else
              return nil
            end
          end
          local function _142_(...)
            if wants_colocation_3f(index["sigil-path"]) then
              return set_index_target_colocation(index)
            else
              return set_index_target_cache(index)
            end
          end
          return _132_(_142_(...))
        elseif true then
          local __75_auto = _131_
          return ...
        else
          return nil
        end
      end
      return _130_(make_module_record(modname0, src_path))
    elseif (_129_ == nil) then
      return false
    else
      return nil
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_145_ = require("hotpot.searcher")
      local search = _let_145_["search"]
      local function _146_(modname1)
        return search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _146_
    end
    local _147_ = search_package_path(modname0)
    if ((_G.type(_147_) == "table") and (nil ~= (_147_)[1])) then
      local modpath = (_147_)[1]
      local _let_148_ = require("hotpot.fennel")
      local dofile = _let_148_["dofile"]
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _149_()
        return dofile(modpath)
      end
      return _149_
    elseif (_147_ == nil) then
      return false
    else
      return nil
    end
  end
  local function _151_(...)
    local _152_ = ...
    if (_152_ == false) then
      local function _153_(...)
        local _154_ = ...
        if (_154_ == false) then
          local function _155_(...)
            local _156_ = ...
            if (_156_ == false) then
              return nil
            elseif true then
              local _3floader = _156_
              return _3floader
            else
              return nil
            end
          end
          return _155_(search_by_package_path(modname))
        elseif true then
          local _3floader = _154_
          return _3floader
        else
          return nil
        end
      end
      return _153_(search_by_rtp_fnl(modname))
    elseif true then
      local _3floader = _152_
      return _3floader
    else
      return nil
    end
  end
  return _151_(search_by_existing_lua(modname))
end
local function make_searcher()
  local function searcher(modname, ...)
    local _160_ = ("hotpot." == string.sub(modname, 1, 7))
    if (_160_ == true) then
      return nil
    elseif (_160_ == false) then
      return (package.preload[modname] or find_module(modname))
    else
      return nil
    end
  end
  return searcher
end
local function make_record_loader(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/init.fnl:366")
  return record_loadfile(record)
end
return {["make-searcher"] = make_searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-record-loader"] = make_record_loader}