local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = require("hotpot.fs")
local file_exists_3f = _local_2_["file-exists?"]
local file_missing_3f = _local_2_["file-missing?"]
local file_stat = _local_2_["file-stat"]
local rm_file = _local_2_["rm-file"]
local join_path = _local_2_["join-path"]
local REPEAT_SEARCH = "REPEAT_SEARCH"
local CACHE_ROOT = join_path(vim.fn.stdpath("cache"), "hotpot")
local function cache_path_for_compiled_artefact(...)
  return join_path(CACHE_ROOT, "compiled", ...)
end
local _local_3_ = require("hotpot.loader.record")
local fetch_index = _local_3_["fetch"]
local save_index = _local_3_["save"]
local drop_index = _local_3_["drop"]
local make_ftplugin_record = _local_3_["new-ftplugin"]
local lua_file_modified_3f = _local_3_["lua-file-modified?"]
local replace_index_files = _local_3_["set-record-files"]
local _local_4_ = require("hotpot.lang.fennel")
local make_module_record = _local_4_["make-module-record"]
local _local_5_ = require("hotpot.loader.record.module")
local set_index_target_cache = _local_5_["retarget-cache"]
local set_index_target_colocation = _local_5_["retarget-colocation"]
local _local_6_ = require("hotpot.loader.sigil")
local wants_colocation_3f = _local_6_["wants-colocation?"]
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
  local _let_9_ = record
  local lua_path = _let_9_["lua-path"]
  local files = _let_9_["files"]
  local function lua_missing_3f()
    return file_missing_3f(record["lua-path"])
  end
  local function files_changed_3f()
    local stale_3f = false
    for _, _10_ in ipairs(files) do
      local _each_11_ = _10_
      local path = _each_11_["path"]
      local historic_size = _each_11_["size"]
      local _each_12_ = _each_11_["mtime"]
      local hsec = _each_12_["sec"]
      local hnsec = _each_12_["nsec"]
      if stale_3f then break end
      local _let_13_ = file_stat(path)
      local current_size = _let_13_["size"]
      local _let_14_ = _let_13_["mtime"]
      local csec = _let_14_["sec"]
      local cnsec = _let_14_["nsec"]
      stale_3f = ((historic_size ~= current_size) or (hsec ~= csec) or (hnsec ~= cnsec))
    end
    return stale_3f
  end
  return (lua_missing_3f() or files_changed_3f() or false)
end
local function record_loadfile(record)
  local _let_15_ = require("hotpot.lang.fennel.compiler")
  local compile_record = _let_15_["compile-record"]
  local _let_16_ = require("hotpot.runtime")
  local config_for_context = _let_16_["config-for-context"]
  local _let_17_ = config_for_context((record["sigil-path"] or record["src-path"]))
  local compiler = _let_17_["compiler"]
  local _let_18_ = compiler
  local modules_options = _let_18_["modules"]
  local macros_options = _let_18_["macros"]
  local preprocessor = _let_18_["preprocessor"]
  if needs_compilation_3f(record) then
    local function _19_(...)
      local _20_, _21_ = ...
      if ((_20_ == true) and (nil ~= _21_)) then
        local deps = _21_
        local function _22_(...)
          local _23_, _24_ = ...
          if (nil ~= _23_) then
            local record0 = _23_
            local function _25_(...)
              local _26_, _27_ = ...
              if (nil ~= _26_) then
                local record1 = _26_
                local function _28_(...)
                  local _29_, _30_ = ...
                  if true then
                    local _ = _29_
                    local function _31_(...)
                      local _32_, _33_ = ...
                      if (_32_ == "TODO") then
                        return loadfile(record1["lua-path"])
                      elseif ((_32_ == false) and (nil ~= _33_)) then
                        local e = _33_
                        return e
                      elseif true then
                        local _0 = _32_
                        return nil
                      else
                        return nil
                      end
                    end
                    return _31_(needs_cleanup())
                  elseif ((_29_ == false) and (nil ~= _30_)) then
                    local e = _30_
                    return e
                  elseif true then
                    local _ = _29_
                    return nil
                  else
                    return nil
                  end
                end
                return _28_(bust_vim_loader_index(record1))
              elseif ((_26_ == false) and (nil ~= _27_)) then
                local e = _27_
                return e
              elseif true then
                local _ = _26_
                return nil
              else
                return nil
              end
            end
            return _25_(save_index(record0))
          elseif ((_23_ == false) and (nil ~= _24_)) then
            local e = _24_
            return e
          elseif true then
            local _ = _23_
            return nil
          else
            return nil
          end
        end
        return _22_(replace_index_files(record, deps))
      elseif ((_20_ == false) and (nil ~= _21_)) then
        local e = _21_
        return e
      elseif true then
        local _ = _20_
        return nil
      else
        return nil
      end
    end
    return _19_(compile_record(record, modules_options, macros_options, preprocessor))
  else
    return loadfile(record["lua-path"])
  end
end
local function query_user(prompt, ...)
  local function _41_(...)
    local l = {{}, {}}
    for _, _42_ in ipairs({...}) do
      local _each_43_ = _42_
      local option = _each_43_[1]
      local action = _each_43_[2]
      table.insert(l[1], option)
      table.insert(l[2], action)
      l = l
    end
    return l
  end
  local _let_40_ = _41_(...)
  local options = _let_40_[1]
  local actions = _let_40_[2]
  local action = nil
  local function on_choice(item, index)
    if (index == nil) then
      vim.notify("\nNo response, doing nothing and passing on to the next lua loader.\n", vim.log.levels.WARN)
      local function _44_()
        return nil
      end
      action = _44_
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
    local function _46_()
      return true
    end
    local function _47_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _46_}, {"No, keep the lua file and dont ask again.", _47_})
  end
  local function clean_cache_and_compile(lua_path_in_cache0, record)
    local function _48_(...)
      local _49_ = ...
      if (_49_ == true) then
        local function _50_(...)
          local _51_ = ...
          if (_51_ == true) then
            local function _52_(...)
              local _53_ = ...
              if (nil ~= _53_) then
                local record0 = _53_
                local function _54_(...)
                  local _55_ = ...
                  if (nil ~= _55_) then
                    local record1 = _55_
                    return record_loadfile(record1)
                  elseif true then
                    local __75_auto = _55_
                    return ...
                  else
                    return nil
                  end
                end
                return _54_(set_index_target_colocation(record0))
              elseif true then
                local __75_auto = _53_
                return ...
              else
                return nil
              end
            end
            return _52_(make_module_record(modname, record["src-path"]))
          elseif true then
            local __75_auto = _51_
            return ...
          else
            return nil
          end
        end
        return _50_(drop_index(record))
      elseif true then
        local __75_auto = _49_
        return ...
      else
        return nil
      end
    end
    return _48_(rm_file(lua_path_in_cache0))
  end
  local _60_ = fetch_index(lua_path_in_cache)
  if (nil ~= _60_) then
    local record = _60_
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
  elseif (_60_ == nil) then
    rm_file(lua_path_in_cache)
    return REPEAT_SEARCH
  else
    return nil
  end
end
local function _67_(...)
  local function handler_for_missing_fnl(modname, lua_path, record)
    if file_missing_3f(record["src-path"]) then
      if lua_file_modified_3f(record) then
        local function _68_()
          rm_file(lua_path)
          drop_index(record)
          local function _69_()
            return REPEAT_SEARCH
          end
          return _69_
        end
        local function _70_()
          drop_index(record)
          local function _71_()
            return loadfile(lua_path)
          end
          return _71_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but the original fennel source file has been removed.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file.", _68_}, {"No, keep the lua file, dont ask again.", _70_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _72_()
          return REPEAT_SEARCH
        end
        return _72_
      end
    else
      return nil
    end
  end
  local function handler_for_colocation_denied(modname, lua_path, record)
    if not wants_colocation_3f(record["sigil-path"]) then
      if lua_file_modified_3f(record) then
        local function _75_()
          rm_file(lua_path)
          drop_index(record)
          local function _76_()
            return REPEAT_SEARCH
          end
          return _76_
        end
        local function _77_()
          drop_index(record)
          local function _78_()
            return loadfile(lua_path)
          end
          return _78_
        end
        return query_user(fmt(("The file %s was built by Hotpot, but colocation permission have been denied.\n" .. "Changes have been made to the file by something else.\n" .. "Do you want to remove the lua file?"), lua_path), {"Yes, remove the lua file and try to recompile into cache.", _75_}, {"No, keep the lua file, dont ask again.", _77_})
      else
        rm_file(lua_path)
        drop_index(record)
        local function _79_()
          return REPEAT_SEARCH
        end
        return _79_
      end
    else
      return nil
    end
  end
  local function handler_for_changes_overwrite(modname, lua_path, record)
    if (needs_compilation_3f(record) and lua_file_modified_3f(record)) then
      local function _82_()
        local function _83_()
          return record_loadfile(record)
        end
        return _83_
      end
      local function _84_()
        local function _85_()
          return loadfile(lua_path)
        end
        return _85_
      end
      return query_user(fmt(("The file %s was built by Hotpot but changes have been made to the file by something else.\n" .. "Continuing will overwrite those changes\n" .. "Overwrite lua with new code?"), lua_path), {"Yes, recompile the fennel source.", _82_}, {"No, keep the lua file for now.", _84_})
    else
      return nil
    end
  end
  local function handler_for_known_colocation(modname, lua_path, record)
    local function _87_(...)
      local _88_ = ...
      if (_88_ == nil) then
        local function _89_(...)
          local _90_ = ...
          if (_90_ == nil) then
            local function _91_(...)
              local _92_ = ...
              if (_92_ == nil) then
                return record_loadfile(record)
              elseif (nil ~= _92_) then
                local func = _92_
                return func()
              else
                return nil
              end
            end
            return _91_(handler_for_changes_overwrite(modname, lua_path, record))
          elseif (nil ~= _90_) then
            local func = _90_
            return func()
          else
            return nil
          end
        end
        return _89_(handler_for_colocation_denied(modname, lua_path, record))
      elseif (nil ~= _88_) then
        local func = _88_
        return func()
      else
        return nil
      end
    end
    return _87_(handler_for_missing_fnl(modname, lua_path, record))
  end
  return {["handler-for-known-colocation"] = handler_for_known_colocation}
end
local _local_66_ = _67_(...)
local handler_for_known_colocation = _local_66_["handler-for-known-colocation"]
local function _97_(...)
  local function has_overwrite_permission_3f(lua_path, src_path)
    local function _98_()
      return true
    end
    local function _99_()
      return false
    end
    return query_user(fmt(("Should Hotpot overwrite the file %s with the contents of %s?\n" .. "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n"), lua_path, src_path), {"Yes, replace the lua file.", _98_}, {"No, keep the lua file for now.", _99_})
  end
  local function handler_for_unknown_colocation(modname, lua_path)
    local _let_100_ = make_module_record(modname, lua_path, {["unsafely?"] = true})
    local sigil_path = _let_100_["sigil-path"]
    local src_path = _let_100_["src-path"]
    if (file_exists_3f(src_path) and wants_colocation_3f(sigil_path) and has_overwrite_permission_3f(lua_path, src_path)) then
      local function _101_(...)
        local _102_ = ...
        if (nil ~= _102_) then
          local record = _102_
          local function _103_(...)
            local _104_ = ...
            if (nil ~= _104_) then
              local record0 = _104_
              local function _105_(...)
                local _106_ = ...
                if (nil ~= _106_) then
                  local loader = _106_
                  local function _107_(...)
                    local _108_, _109_ = ...
                    if ((_108_ == false) and (nil ~= _109_)) then
                      local e = _109_
                      return e
                    elseif true then
                      local __75_auto = _108_
                      return ...
                    else
                      return nil
                    end
                  end
                  return _107_(loader)
                elseif true then
                  local __75_auto = _106_
                  return ...
                else
                  return nil
                end
              end
              return _105_(record_loadfile(record0))
            elseif true then
              local __75_auto = _104_
              return ...
            else
              return nil
            end
          end
          return _103_(set_index_target_colocation(record))
        elseif true then
          local __75_auto = _102_
          return ...
        else
          return nil
        end
      end
      return _101_(make_module_record(modname, src_path))
    else
      return loadfile(lua_path)
    end
  end
  return {["handler-for-unknown-colocation"] = handler_for_unknown_colocation}
end
local _local_96_ = _97_(...)
local handler_for_unknown_colocation = _local_96_["handler-for-unknown-colocation"]
local function handle_colo_lua_path(modname, lua_path)
  local _115_ = fetch_index(lua_path)
  if (nil ~= _115_) then
    local record = _115_
    return handler_for_known_colocation(modname, lua_path, record)
  elseif (_115_ == nil) then
    return handler_for_unknown_colocation(modname, lua_path)
  else
    return nil
  end
end
local function find_module(modname)
  local function infer_lua_path_type(path)
    local cache_affix = fmt("^%s", vim.pesc(cache_path_for_compiled_artefact()))
    local _117_ = path:find(cache_affix)
    if (_117_ == 1) then
      return "cache"
    elseif true then
      local _ = _117_
      return "colocate"
    else
      return nil
    end
  end
  local function search_by_existing_lua(modname0)
    local _119_ = vim.loader.find(modname0)
    if ((_G.type(_119_) == "table") and ((_G.type((_119_)[1]) == "table") and (nil ~= ((_119_)[1]).modpath))) then
      local found_lua_path = ((_119_)[1]).modpath
      local f
      do
        local _120_ = infer_lua_path_type(found_lua_path)
        if (_120_ == "cache") then
          f = handle_cache_lua_path
        elseif (_120_ == "colocate") then
          f = handle_colo_lua_path
        else
          f = nil
        end
      end
      local _122_, _123_ = f(modname0, found_lua_path)
      if (_122_ == REPEAT_SEARCH) then
        return find_module(modname0)
      elseif true then
        local _3floader = _122_
        return _3floader
      else
        return nil
      end
    elseif ((_G.type(_119_) == "table") and ((_119_)[1] == nil)) then
      return false
    else
      return nil
    end
  end
  local function search_by_rtp_fnl(modname0)
    local search_runtime_path
    do
      local _let_126_ = require("hotpot.searcher")
      local search = _let_126_["search"]
      local function _127_(modname1)
        return search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["package-path?"] = false})
      end
      search_runtime_path = _127_
    end
    local _128_ = search_runtime_path(modname0)
    if ((_G.type(_128_) == "table") and (nil ~= (_128_)[1])) then
      local src_path = (_128_)[1]
      local function _129_(...)
        local _130_ = ...
        if (nil ~= _130_) then
          local index = _130_
          local function _131_(...)
            local _132_ = ...
            if (nil ~= _132_) then
              local index0 = _132_
              local function _133_(...)
                local _134_ = ...
                if (nil ~= _134_) then
                  local loader = _134_
                  local function _135_(...)
                    local _136_, _137_ = ...
                    if ((_136_ == false) and (nil ~= _137_)) then
                      local e = _137_
                      return e
                    elseif true then
                      local __75_auto = _136_
                      return ...
                    else
                      return nil
                    end
                  end
                  return _135_(loader)
                elseif true then
                  local __75_auto = _134_
                  return ...
                else
                  return nil
                end
              end
              return _133_(record_loadfile(index0))
            elseif true then
              local __75_auto = _132_
              return ...
            else
              return nil
            end
          end
          local function _141_(...)
            if wants_colocation_3f(index["sigil-path"]) then
              return set_index_target_colocation(index)
            else
              return set_index_target_cache(index)
            end
          end
          return _131_(_141_(...))
        elseif true then
          local __75_auto = _130_
          return ...
        else
          return nil
        end
      end
      return _129_(make_module_record(modname0, src_path))
    elseif (_128_ == nil) then
      return false
    else
      return nil
    end
  end
  local function search_by_package_path(modname0)
    local search_package_path
    do
      local _let_144_ = require("hotpot.searcher")
      local search = _let_144_["search"]
      local function _145_(modname1)
        return search({prefix = "fnl", extension = "fnl", modnames = {(modname1 .. ".init"), modname1}, ["runtime-path?"] = false})
      end
      search_package_path = _145_
    end
    local _146_ = search_package_path(modname0)
    if ((_G.type(_146_) == "table") and (nil ~= (_146_)[1])) then
      local modpath = (_146_)[1]
      local _let_147_ = require("hotpot.fennel")
      local dofile = _let_147_["dofile"]
      vim.notify(fmt(("Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n" .. "Hotpot will evaluate this file instead of compling it."), modname0, modpath), vim.log.levels.NOTICE)
      local function _148_()
        return dofile(modpath)
      end
      return _148_
    elseif (_146_ == nil) then
      return false
    else
      return nil
    end
  end
  local function _150_(...)
    local _151_ = ...
    if (_151_ == false) then
      local function _152_(...)
        local _153_ = ...
        if (_153_ == false) then
          local function _154_(...)
            local _155_ = ...
            if (_155_ == false) then
              return nil
            elseif true then
              local _3floader = _155_
              return _3floader
            else
              return nil
            end
          end
          return _154_(search_by_package_path(modname))
        elseif true then
          local _3floader = _153_
          return _3floader
        else
          return nil
        end
      end
      return _152_(search_by_rtp_fnl(modname))
    elseif true then
      local _3floader = _151_
      return _3floader
    else
      return nil
    end
  end
  return _150_(search_by_existing_lua(modname))
end
local function make_searcher()
  local function searcher(modname, ...)
    local _159_ = ("hotpot." == string.sub(modname, 1, 7))
    if (_159_ == true) then
      return nil
    elseif (_159_ == false) then
      return (package.preload[modname] or find_module(modname))
    else
      return nil
    end
  end
  return searcher
end
local function make_module_record_loader(module_record_maker, modname, src_path)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/init.fnl:364")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/init.fnl:364")
  _G.assert((nil ~= module_record_maker), "Missing argument module-record-maker on fnl/hotpot/loader/init.fnl:364")
  local index = module_record_maker(modname, src_path)
  local loader = record_loadfile(index)
  return loader
end
local function make_ftplugin_record_loader(ftplugin_record_maker, modname, src_path)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/init.fnl:369")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/init.fnl:369")
  _G.assert((nil ~= ftplugin_record_maker), "Missing argument ftplugin-record-maker on fnl/hotpot/loader/init.fnl:369")
  local index = ftplugin_record_maker(modname, src_path)
  local loader = record_loadfile(index)
  return loader
end
return {["make-searcher"] = make_searcher, ["compiled-cache-path"] = cache_path_for_compiled_artefact(), ["cache-path-for-compiled-artefact"] = cache_path_for_compiled_artefact, ["make-module-record-loader"] = make_module_record_loader, ["make-ftplugin-record-loader"] = make_ftplugin_record_loader}