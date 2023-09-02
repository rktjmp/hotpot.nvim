local function find_ft_plugins(filetype)
  local _let_1_ = require("hotpot.loader")
  local make_ftplugin_record_loader = _let_1_["make-ftplugin-record-loader"]
  local _let_2_ = require("hotpot.lang.fennel")
  local make_ftplugin_record = _let_2_["make-ftplugin-record"]
  local _let_3_ = require("hotpot.fs")
  local file_exists_3f = _let_3_["file-exists?"]
  local rm_file = _let_3_["rm-file"]
  local _let_4_ = require("hotpot.loader.record")
  local fetch = _let_4_["fetch"]
  local drop = _let_4_["drop"]
  local _let_5_ = require("hotpot.searcher")
  local search = _let_5_["search"]
  local modname = ("hotpot-ftplugin." .. filetype)
  local make_loader
  local function _6_(_241, _242)
    return make_ftplugin_record_loader(make_ftplugin_record, _241, _242)
  end
  make_loader = _6_
  local find_all
  local function _7_()
    return search({prefix = "ftplugin", extension = "fnl", modnames = {filetype}, ["all?"] = true, ["package-path?"] = false})
  end
  find_all = _7_
  for _, path in ipairs((find_all() or {})) do
    local _8_ = make_loader(modname, path)
    local function _9_()
      local loader = _8_
      return ("function" == type(loader))
    end
    if ((nil ~= _8_) and _9_()) then
      local loader = _8_
    else
      local function _10_()
        local msg = _8_
        return ("string" == type(msg))
      end
      if ((nil ~= _8_) and _10_()) then
        local msg = _8_
        vim.notify(msg, vim.log.levels.ERROR)
      else
      end
    end
  end
  for _, _12_ in ipairs(vim.loader.find(modname, {all = true})) do
    local _each_13_ = _12_
    local modpath = _each_13_["modpath"]
    local record = fetch(modname)
    local loadit
    local function _14_()
      local function _15_(...)
        local _16_, _17_ = ...
        if ((_16_ == true) and (nil ~= _17_)) then
          local loader = _17_
          local function _18_(...)
            local _19_, _20_ = ...
            if ((_19_ == true) and true) then
              local _0 = _20_
              return nil
            elseif ((_19_ == false) and (nil ~= _20_)) then
              local e = _20_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          return _18_(pcall(loader, modname, modpath))
        elseif ((_16_ == false) and (nil ~= _17_)) then
          local e = _17_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _15_(pcall(loadfile, modpath))
    end
    loadit = _14_
    local _23_ = fetch(modpath)
    if (nil ~= _23_) then
      local record0 = _23_
      if file_exists_3f(record0["src-path"]) then
        loadit()
      else
        rm_file(modpath)
        drop(record0)
      end
    elseif (_23_ == nil) then
      loadit()
    else
    end
  end
  return nil
end
local enabled_3f = false
local function enable()
  local _let_26_ = vim.api
  local nvim_create_autocmd = _let_26_["nvim_create_autocmd"]
  local nvim_create_augroup = _let_26_["nvim_create_augroup"]
  local au_group = nvim_create_augroup("hotpot-ftplugin", {})
  local cb
  local function _27_()
    find_ft_plugins(vim.fn.expand("<amatch>"))
    return nil
  end
  cb = _27_
  if not enabled_3f then
    enabled_3f = true
    return nvim_create_autocmd("FileType", {callback = cb, group = au_group})
  else
    return nil
  end
end
local function disable()
  if enabled_3f then
    return vim.api.nvim_del_autocmd_by_name("hotpot-ftplugin")
  else
    return nil
  end
end
return {enable = enable, disable = disable}