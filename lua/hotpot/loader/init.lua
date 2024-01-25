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
local raw_wants_colocation_3f = _local_7_["wants-colocation?"]
local function wants_colocation_3f(sigil_path)
  if raw_wants_colocation_3f(sigil_path) then
    vim.notify_once(string.format(("Colocation is deprecated, please swap " .. "to `build = true` which provides a more " .. "consistent experience, see `:h hotpot-dot-hotpot.` (%s)"), sigil_path), vim.log.levels.WARN)
    return true
  else
    return false
  end
end
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
  local _let_11_ = record
  local lua_path = _let_11_["lua-path"]
  local files = _let_11_["files"]
  local function lua_missing_3f()
    return file_missing_3f(record["lua-path"])
  end
  local function files_changed_3f()
    local stale_3f = false
    for _, _12_ in ipairs(files) do
      local _each_13_ = _12_
      local path = _each_13_["path"]
      local historic_size = _each_13_["size"]
      local _each_14_ = _each_13_["mtime"]
      local hsec = _each_14_["sec"]
      local hnsec = _each_14_["nsec"]
      if stale_3f then break end
      local _let_15_ = file_stat(path)
      local current_size = _let_15_["size"]
      local _let_16_ = _let_15_["mtime"]
      local csec = _let_16_["sec"]
      local cnsec = _let_16_["nsec"]
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_17_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_17_["compile-record"]
  local _let_18_ = require("hotpot.runtime")
  local config_for_context = _let_18_["config-for-context"]
  local _let_19_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_19_["compiler"]
  local _let_20_ = compiler
  local modules_options = _let_20_["modules"]
  local macros_options = _let_20_["macros"]
  local preprocessor = _let_20_["preprocessor"]
  if needs_compilation_3f(record) then
    local function _21_(...)
      local _22_, _23_ = ...
      if ((_22_ == true) and (nil ~= _23_)) then
        local deps = _23_
        local function _24_(...)
          local _25_, _26_ = ...
          if (nil ~= _25_) then
            local record0 = _25_
            local function _27_(...)
              local _28_, _29_ = ...
              if (nil ~= _28_) then
                local record1 = _28_
                local function _30_(...)
                  local _31_, _32_ = ...
                  if true then
                    local _ = _31_
                    local function _33_(...)
                      local _34_, _35_ = ...
                      if (_34_ == "TODO") then
                        return loadfile(record1["lua-path"])
                      elseif ((_34_ == false) and (nil ~= _35_)) then
                        local e = _35_
                        return e
                      else
                        local _0 = _34_
                        return nil
                      end
                    end
                    return _33_(needs_cleanup())
                  elseif ((_31_ == false) and (nil ~= _32_)) then
                    local e = _32_
                    return e
                  else
                    local _ = _31_
                    return nil
                  end
                end
                return _30_(bust_vim_loader_index(record1))
              elseif ((_28_ == false) and (nil ~= _29_)) then
                local e = _29_
                return e
              else
                local _ = _28_
                return nil
              end
            end
            return _27_(save_index(record0))
          elseif ((_25_ == false) and (nil ~= _26_)) then
            local e = _26_
            return e
          else
            local _ = _25_
            return nil
          end
        end
        return _24_(replace_index_files(record, deps))
      elseif ((_22_ == false) and (nil ~= _23_)) then
        local e = _23_
        return e
      else
        local _ = _22_
        return nil
      end
    end
    return _21_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function query_user(prompt, ...)
  local function _43_(...)
    local l = {{}, {}}
    for _, _44_ in ipairs({...}) do
      local _each_45_ = _44_
      local option = _each_45_[1]
      local action = _each_45_[2]
      table.insert(l[1], option)
      table.insert(l[2], action)
      l = l
    end
    return l
  end
  local _let_42_ = _43_(...)
  local options = _let_42_[1]
  local actions = _let_42_[2]
  local action = nil
  local function on_choice(item, index)
    if (index == nil) then
      vim.notify("\nNo response, doing nothing and passing on to the next lua loader.\n", vim.log.levels.WARN)
      local function _46_()
        return nil
      end
      action = _46_
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
  print("")
  return action()
end
local function handle_cache_lua_path(modname, lua_path_in_cache)
  local function has_overwrite_permission_3f(lua_path, src_path)
    local function _48_()
      return true
    end
    local function _49_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _48_}, {"No, keep the lua file and dont ask again.", _49_})
  end
  local function clean_cache_and_compile(lua_path_in_cache0, record)
    local function _50_(...)
      local _51_ = ...
      if (_51_ == true) then
        local function _52_(...)
          local _53_ = ...
          if (_53_ == true) then
            local function _54_(...)
              local _55_ = ...
              if (nil ~= _55_) then
                local record0 = _55_
                local function _56_(...)
                  local _57_ = ...
                  if (nil ~= _57_) then
                    local record1 = _57_
                    return record_loadfile(record1)
                  else
                    local __84_auto = _57_
                    return ...
                  end
                end
                return _56_(set_index_target_colocation(record0))
              else
                local __84_auto = _55_
                return ...
              end
            end
            return _54_(make_module_record(modname, record["src-path"]))
          else
            local __84_auto = _53_
            return ...
          end
        end
        return _52_(drop_index(record))
      else
        local __84_auto = _51_
        return ...
      end
    end
    return _50_(rm_file(lua_path_in_cache0))
  end
  local _62_ = fetch_index(lua_path_in_cache)
  if (nil ~= _62_) then
    local record = _62_
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
  elseif (_62_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function _69_(...)
  local function handler_for_missing_fnl(modname, lua_path, record)
    if file_missing_3f(record["src-path"]) then
      if lua_file_modified_3f(record) then
        local function _70_()
          rm_file(lua_path)
          drop_index(record)
          local function _71_()
            return REPEAT_SEARCH
          end
          return _71_
        end
        local function _72_()
          drop_index(record)
          local function _73_()
            return loadfile(lua_path)
          end
          return _73_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but the original fennel source file has been removed.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file.", _70_}, {"No, keep the lua file, dont ask again.", _72_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _74_()
          return REPEAT_SEARCH
        end
        return _74_
      end
    else
      return nil
    end
  end
  local function handler_for_colocation_denied(modname, lua_path, record)
    if not wants_colocation_3f(record["sigil-path"]) then
      if lua_file_modified_3f(record) then
        local function _77_()
          rm_file(lua_path)
          drop_index(record)
          local function _78_()
            return REPEAT_SEARCH
          end
          return _78_
        end
        local function _79_()
          drop_index(record)
          local function _80_()
            return loadfile(lua_path)
          end
          return _80_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but colocation permission have been denied.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file and try to recompile into cache.", _77_}, {"No, keep the lua file, dont ask again.", _79_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _81_()
          return REPEAT_SEARCH
        end
        return _81_
      end
    else
      return nil
    end
  end
  local function handler_for_changes_overwrite(modname, lua_path, record)
    if (needs_compilation_3f(record) and lua_file_modified_3f(record)) then
      local function _84_()
        local function _85_()
          return record_loadfile(record)
        end
        return _85_
      end
      local function _86_()
        local function _87_()
          return loadfile(lua_path)
        end
        return _87_
      end
      return query_user(fmt(("The file %s was built by Hotpot but changes have been made to the file by something else.\n" .. "Continuing will overwrite those changes\n" .. "Overwrite lua with new code?"), lua_path), {"Yes, recompile the fennel source.", _84_}, {"No, keep the lua file for now.", _86_})
    else
      return nil
    end
  end
  local function handler_for_known_colocation(modname, lua_path, record)
    local function _89_(...)
      local _90_ = ...
      if (_90_ == nil) then
        local function _91_(...)
          local _92_ = ...
          if (_92_ == nil) then
            local function _93_(...)
              local _94_ = ...
              if (_94_ == nil) then
                return record_loadfile(record)
              elseif (nil ~= _94_) then
                local func = _94_
                return func()
              else
                return nil
              end
            end
            return _93_(handler_for_changes_overwrite(modname, lua_path, record))
          elseif (nil ~= _92_) then
            local func = _92_
            return func()
          else
            return nil
          end
        end
        return _91_(handler_for_colocation_denied(modname, lua_path, record))
      elseif (nil ~= _90_) then
        local func = _90_
        return func()
      else
        return nil
      end
    end
    return _89_(handler_for_missing_fnl(modname, lua_path, record))
  end
  return {["handler-for-known-colocation"] = handler_for_known_colocation}
end
local _local_68_ = _69_(...)
local handler_for_known_colocation = _local_68_["handler-for-known-colocation"]
local function _99_(...)
  local function has_overwrite_permission_3f(lua_path, src_path)
    local function _100_()
      return true
    end
    local function _101_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _100_}, {"No, keep the lua file for now.", _101_})
  end
  local function handler_for_unknown_colocation(modname, lua_path)
    local _let_102_ = make_module_record(modname, lua_path, {["unsafely?"] = true})
    local sigil_path = _let_102_["sigil-path"]
    local src_path = _let_102_["src-path"]
    if (file_exists_3f(src_path) and wants_colocation_3f(sigil_path) and has_overwrite_permission_3f(lua_path, src_path)) then
      local function _103_(...)
        local _104_ = ...
        if (nil ~= _104_) then
          local record = _104_
          local function _105_(...)
            local _106_ = ...
            if (nil ~= _106_) then
              local record0 = _106_
              local function _107_(...)
                local _108_ = ...
                if (nil ~= _108_) then
                  local loader = _108_
                  local function _109_(...)
                    local _110_, _111_ = ...
                    if ((_110_ == false) and (nil ~= _111_)) then
                      local e = _111_
                      return e
                    else
                      local __84_auto = _110_
                      return ...
                    end
                  end
                  return _109_(loader)
                else
                  local __84_auto = _108_
                  return ...
                end
              end
              return _107_(record_loadfile(record0))
            else
              local __84_auto = _106_
              return ...
            end
          end
          return _105_(set_index_target_colocation(record))
        else
          local __84_auto = _104_
          return ...
        end
      end
      return _103_(make_module_record(modname, src_path))
    else
      return loadfile(lua_path)
    end
  end
  return {["handler-for-unknown-colocation"] = handler_for_unknown_colocation}
end
local _local_98_ = _99_(...)
local handler_for_unknown_colocation = _local_98_["handler-for-unknown-colocation"]
local function handle_colo_lua_path(modname, lua_path)
  local _117_ = fetch_index(lua_path)
  if (nil ~= _117_) then
    local record = _117_
    return handler_for_known_colocation(modname, lua_path, record)
  elseif (_117_ == nil) then
    return handler_for_unknown_colocation(modname, lua_path)
  else
    return nil
  end
end
local function find_module(modname)
  local function infer_lua_path_type(path)
    local cache_affix = fmt("^%s", vim.pesc(cache_path_for_compiled_artefact()))
    local _119_ = path:find(cache_affix)
    if (_119_ == 1) then
      return "cache"
    else
      local _ = _119_
      return "colocate"
    end
  end
  local function search_by_existing_lua(modname0)
    local _121_ = vim.loader.find(modname0)
    if ((_G.type(_121_) == "table") and ((_G.type(_121_[1]) == "table") and (nil ~= _121_[1].modpath))) then
      local found_lua_path = _121_[1].modpath
      local f
      do
        local _122_ = infer_lua_path_type(found_lua_path)
        if (_122_ == "cache") then
          f = handle_cache_lua_path
        elseif (_122_ == "colocate") then
          f = handle_colo_lua_path
        else
          f = nil
        end
      end
      local _124_, _125_ = f(modname0, found_lua_path)
      if (_124_ == REPEAT_SEARCH) then
        return find_module(modname0)
      else
        local _3floader = _124_
        return _3floader
      end
    elseif ((_G.type(_121_) == "table") and (_121_[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_128_ = require("hotpot.searcher")
      local mod_search = _let_128_["mod-search"]
      local function _129_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _129_
    end
    local _130_ = search_runtime_path(modname0)
    if ((_G.type(_130_) == "table") and (nil ~= _130_[1])) then
      local src_path = _130_[1]
      local function _131_(...)
        local _132_ = ...
        if (nil ~= _132_) then
          local index = _132_
          local function _133_(...)
            local _134_ = ...
            if (nil ~= _134_) then
              local index0 = _134_
              local function _135_(...)
                local _136_ = ...
                if (nil ~= _136_) then
                  local loader = _136_
                  local function _137_(...)
                    local _138_, _139_ = ...
                    if ((_138_ == false) and (nil ~= _139_)) then
                      local e = _139_
                      return e
                    else
                      local __84_auto = _138_
                      return ...
                    end
                  end
                  return _137_(loader)
                else
                  local __84_auto = _136_
                  return ...
                end
              end
              return _135_(record_loadfile(index0))
            else
              local __84_auto = _134_
              return ...
            end
          end
          local function _143_(...)
            if wants_colocation_3f(index["sigil-path"]) then
              return set_index_target_colocation(index)
            else
              return set_index_target_cache(index)
            end
          end
          return _133_(_143_(...))
        else
          local __84_auto = _132_
          return ...
        end
      end
      return _131_(make_module_record(modname0, src_path))
    else
      local _ = _130_
      return false
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_146_ = require("hotpot.searcher")
      local mod_search = _let_146_["mod-search"]
      local function _147_(modname1)
        return mod_search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _147_
    end
    local _148_ = search_package_path(modname0)
    if ((_G.type(_148_) == "table") and (nil ~= _148_[1])) then
      local modpath = _148_[1]
      local _let_149_ = require("hotpot.fennel")
      local dofile = _let_149_["dofile"]
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _150_()
        return dofile(modpath)
      end
      return _150_
    else
      local _ = _148_
      return false
    end
  end
  local function _152_(...)
    local _153_ = ...
    if (_153_ == false) then
      local function _154_(...)
        local _155_ = ...
        if (_155_ == false) then
          local function _156_(...)
            local _157_ = ...
            if (_157_ == false) then
              return nil
            else
              local _3floader = _157_
              return _3floader
            end
          end
          return _156_(search_by_package_path(modname))
        else
          local _3floader = _155_
          return _3floader
        end
      end
      return _154_(search_by_rtp_fnl(modname))
    else
      local _3floader = _153_
      return _3floader
    end
  end
  return _152_(search_by_existing_lua(modname))
end
local function make_searcher()
  local function searcher(modname, ...)
    local _161_ = ("hotpot." == string.sub(modname, 1, 7))
    if (_161_ == true) then
      return nil
    elseif (_161_ == false) then
      return (package.preload[modname] or find_module(modname))
    else
      return nil
    end
  end
  return searcher
end
local function make_record_loader(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/init.fnl:378")
  return record_loadfile(record)
end
return {["make-searcher"] = make_searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-record-loader"] = make_record_loader}