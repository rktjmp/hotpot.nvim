local function generate_ftplugin_fnl_loaders(filetype, ftplugin_modname)
  local _let_1_ = require("hotpot.loader")
  local make_ftplugin_record_loader = _let_1_["make-ftplugin-record-loader"]
  local _let_2_ = require("hotpot.lang.fennel")
  local make_ftplugin_record = _let_2_["make-ftplugin-record"]
  local _let_3_ = require("hotpot.searcher")
  local search = _let_3_["search"]
  local find_all
  local function _4_()
    return search({prefix = "ftplugin", extension = "fnl", modnames = {filetype}, ["all?"] = true, ["package-path?"] = false})
  end
  find_all = _4_
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, path in ipairs((find_all() or {})) do
    local val_19_auto
    do
      local _5_ = make_ftplugin_record_loader(make_ftplugin_record, ftplugin_modname, path)
      local function _6_()
        local loader = _5_
        return ("function" == type(loader))
      end
      if ((nil ~= _5_) and _6_()) then
        local loader = _5_
        val_19_auto = {loader = loader, modname = ftplugin_modname, modpath = path}
      else
        local function _7_()
          local msg = _5_
          return ("string" == type(msg))
        end
        if ((nil ~= _5_) and _7_()) then
          local msg = _5_
          val_19_auto = vim.notify(msg, vim.log.levels.ERROR)
        else
          val_19_auto = nil
        end
      end
    end
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function find_ft_plugins(filetype)
  local _let_10_ = require("hotpot.fs")
  local file_exists_3f = _let_10_["file-exists?"]
  local rm_file = _let_10_["rm-file"]
  local _let_11_ = require("hotpot.loader.record")
  local fetch = _let_11_["fetch"]
  local drop = _let_11_["drop"]
  local ftplugin_modname = ("hotpot-ftplugin." .. filetype)
  local loaders = generate_ftplugin_fnl_loaders(filetype, ftplugin_modname)
  for _, _12_ in ipairs(loaders) do
    local _each_13_ = _12_
    local loader = _each_13_["loader"]
    local modname = _each_13_["modname"]
    local modpath = _each_13_["modpath"]
    local _14_, _15_ = pcall(loader, modname, modpath)
    if ((_14_ == true) and true) then
      local _0 = _15_
    elseif ((_14_ == false) and (nil ~= _15_)) then
      local e = _15_
      vim.notify(e, vim.log.levels.ERROR)
    else
    end
  end
  for _, _17_ in ipairs(vim.loader.find(ftplugin_modname, {all = true})) do
    local _each_18_ = _17_
    local modpath = _each_18_["modpath"]
    local _19_ = fetch(modpath)
    if (nil ~= _19_) then
      local record = _19_
      if not file_exists_3f(record["src-path"]) then
        rm_file(modpath)
        drop(record)
      else
      end
    else
    end
  end
  return nil
end
local enabled_3f = false
local function enable()
  local _let_22_ = vim.api
  local nvim_create_autocmd = _let_22_["nvim_create_autocmd"]
  local nvim_create_augroup = _let_22_["nvim_create_augroup"]
  local au_group = nvim_create_augroup("hotpot-ftplugin", {})
  local cb
  local function _23_()
    find_ft_plugins(vim.fn.expand("<amatch>"))
    return nil
  end
  cb = _23_
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