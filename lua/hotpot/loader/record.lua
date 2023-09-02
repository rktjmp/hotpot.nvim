local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = require("hotpot.fs")
local file_exists_3f = _local_2_["file-exists?"]
local file_missing_3f = _local_2_["file-missing?"]
local read_file_21 = _local_2_["read-file!"]
local file_stat = _local_2_["file-stat"]
local rm_file = _local_2_["rm-file"]
local make_path = _local_2_["make-path"]
local join_path = _local_2_["join-path"]
local uri_encode
local function _3_(_241)
  return vim.uri_encode(_241, "rfc2396")
end
local function _4_(str)
  local _let_5_ = require("bit")
  local tohex = _let_5_["tohex"]
  local percent_encode_char
  local function _6_(_241)
    return ("%" .. tohex(string.byte(_241), 2))
  end
  percent_encode_char = _6_
  local rfc2396_pattern = "([^A-Za-z0-9%-_.!~*'()])"
  local _7_ = string.gsub(str, rfc2396_pattern, percent_encode_char)
  return _7_
end
uri_encode = ((vim.uri_encode and _3_) or _4_)
local CACHE_ROOT = join_path(vim.fn.stdpath("cache"), "hotpot")
local INDEX_ROOT_PATH = join_path(CACHE_ROOT, "index")
local INDEX_VERSION = 2
local RECORD_TYPE_MODULE = 1
local RECORD_TYPE_FTPLUGIN = 2
local function module_3f(r)
  local _9_
  do
    local t_8_ = r
    if (nil ~= t_8_) then
      t_8_ = (t_8_).type
    else
    end
    _9_ = t_8_
  end
  return (RECORD_TYPE_MODULE == _9_)
end
local function ftplugin_3f(r)
  local _12_
  do
    local t_11_ = r
    if (nil ~= t_11_) then
      t_11_ = (t_11_).type
    else
    end
    _12_ = t_11_
  end
  return (RECORD_TYPE_FTPLUGIN == _12_)
end
local function path__3eindex_key(path)
  _G.assert((nil ~= path), "Missing argument path on fnl/hotpot/loader/record.fnl:46")
  local path0 = vim.fs.normalize(path)
  return join_path(INDEX_ROOT_PATH, (uri_encode(path0, "rfc2396") .. "-metadata.mpack"))
end
local function load(lua_path)
  local function _14_(...)
    local _15_ = ...
    if (nil ~= _15_) then
      local index_path = _15_
      local function _16_(...)
        local _17_ = ...
        if (_17_ == true) then
          local function _18_(...)
            local _19_ = ...
            if (nil ~= _19_) then
              local fin = _19_
              local function _20_(...)
                local _21_ = ...
                if (nil ~= _21_) then
                  local bytes = _21_
                  local function _22_(...)
                    local _23_ = ...
                    if (_23_ == true) then
                      local function _24_(...)
                        local _25_, _26_ = ...
                        if ((_25_ == true) and ((_G.type(_26_) == "table") and ((_26_).version == INDEX_VERSION) and (nil ~= (_26_).data))) then
                          local data = (_26_).data
                          return data
                        elseif true then
                          local _ = _25_
                          local function _27_(...)
                            local _28_ = ...
                            if (nil ~= _28_) then
                              local index_path0 = _28_
                              local function _29_(...)
                                local _30_ = ...
                                if (_30_ == true) then
                                  local function _31_(...)
                                    local _32_ = ...
                                    if (_32_ == true) then
                                      return nil
                                    elseif true then
                                      local _0 = _32_
                                      return nil
                                    else
                                      return nil
                                    end
                                  end
                                  return _31_(rm_file(index_path0))
                                elseif true then
                                  local _0 = _30_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _29_(file_exists_3f(index_path0))
                            elseif true then
                              local _0 = _28_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _27_(path__3eindex_key(lua_path))
                        else
                          return nil
                        end
                      end
                      return _24_(pcall(vim.mpack.decode, bytes))
                    elseif true then
                      local _ = _23_
                      local function _37_(...)
                        local _38_ = ...
                        if (nil ~= _38_) then
                          local index_path0 = _38_
                          local function _39_(...)
                            local _40_ = ...
                            if (_40_ == true) then
                              local function _41_(...)
                                local _42_ = ...
                                if (_42_ == true) then
                                  return nil
                                elseif true then
                                  local _0 = _42_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _41_(rm_file(index_path0))
                            elseif true then
                              local _0 = _40_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _39_(file_exists_3f(index_path0))
                        elseif true then
                          local _0 = _38_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _37_(path__3eindex_key(lua_path))
                    else
                      return nil
                    end
                  end
                  return _22_(fin:close())
                elseif true then
                  local _ = _21_
                  local function _47_(...)
                    local _48_ = ...
                    if (nil ~= _48_) then
                      local index_path0 = _48_
                      local function _49_(...)
                        local _50_ = ...
                        if (_50_ == true) then
                          local function _51_(...)
                            local _52_ = ...
                            if (_52_ == true) then
                              return nil
                            elseif true then
                              local _0 = _52_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _51_(rm_file(index_path0))
                        elseif true then
                          local _0 = _50_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _49_(file_exists_3f(index_path0))
                    elseif true then
                      local _0 = _48_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _47_(path__3eindex_key(lua_path))
                else
                  return nil
                end
              end
              return _20_(fin:read("a*"))
            elseif true then
              local _ = _19_
              local function _57_(...)
                local _58_ = ...
                if (nil ~= _58_) then
                  local index_path0 = _58_
                  local function _59_(...)
                    local _60_ = ...
                    if (_60_ == true) then
                      local function _61_(...)
                        local _62_ = ...
                        if (_62_ == true) then
                          return nil
                        elseif true then
                          local _0 = _62_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _61_(rm_file(index_path0))
                    elseif true then
                      local _0 = _60_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _59_(file_exists_3f(index_path0))
                elseif true then
                  local _0 = _58_
                  return nil
                else
                  return nil
                end
              end
              return _57_(path__3eindex_key(lua_path))
            else
              return nil
            end
          end
          return _18_(io.open(index_path, "rb"))
        elseif true then
          local _ = _17_
          local function _67_(...)
            local _68_ = ...
            if (nil ~= _68_) then
              local index_path0 = _68_
              local function _69_(...)
                local _70_ = ...
                if (_70_ == true) then
                  local function _71_(...)
                    local _72_ = ...
                    if (_72_ == true) then
                      return nil
                    elseif true then
                      local _0 = _72_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _71_(rm_file(index_path0))
                elseif true then
                  local _0 = _70_
                  return nil
                else
                  return nil
                end
              end
              return _69_(file_exists_3f(index_path0))
            elseif true then
              local _0 = _68_
              return nil
            else
              return nil
            end
          end
          return _67_(path__3eindex_key(lua_path))
        else
          return nil
        end
      end
      return _16_(file_exists_3f(index_path))
    elseif true then
      local _ = _15_
      local function _77_(...)
        local _78_ = ...
        if (nil ~= _78_) then
          local index_path = _78_
          local function _79_(...)
            local _80_ = ...
            if (_80_ == true) then
              local function _81_(...)
                local _82_ = ...
                if (_82_ == true) then
                  return nil
                elseif true then
                  local _0 = _82_
                  return nil
                else
                  return nil
                end
              end
              return _81_(rm_file(index_path))
            elseif true then
              local _0 = _80_
              return nil
            else
              return nil
            end
          end
          return _79_(file_exists_3f(index_path))
        elseif true then
          local _0 = _78_
          return nil
        else
          return nil
        end
      end
      return _77_(path__3eindex_key(lua_path))
    else
      return nil
    end
  end
  return _14_(path__3eindex_key(lua_path))
end
local function fetch(lua_path)
  local _87_, _88_ = load(lua_path)
  if (nil ~= _87_) then
    local record = _87_
    local function _89_()
      local record0 = record
      return module_3f(record0)
    end
    if ((nil ~= record) and _89_()) then
      local record0 = record
      return record0
    else
      local function _90_()
        local record0 = record
        return ftplugin_3f(record0)
      end
      if ((nil ~= record) and _90_()) then
        local record0 = record
        return record0
      elseif true then
        local _ = record
        return nil, fmt("Could not load record, unknown type. Record: %s", vim.inspect(record))
      else
        return nil
      end
    end
  elseif ((_87_ == false) and (nil ~= _88_)) then
    local e = _88_
    return nil
  elseif true then
    local _ = _87_
    return nil
  else
    return nil
  end
end
local function save(record)
  local function _93_(...)
    local _94_, _95_ = ...
    if (_94_ == true) then
      local function _96_(...)
        local _97_, _98_ = ...
        if ((_G.type(_97_) == "table") and (nil ~= (_97_)["lua-path"])) then
          local lua_path = (_97_)["lua-path"]
          local function _99_(...)
            local _100_, _101_ = ...
            if ((_G.type(_100_) == "table") and (nil ~= (_100_).mtime) and (nil ~= (_100_).size)) then
              local mtime = (_100_).mtime
              local size = (_100_).size
              local function _102_(...)
                local _103_, _104_ = ...
                if (nil ~= _103_) then
                  local record0 = _103_
                  local function _105_(...)
                    local _106_, _107_ = ...
                    if (_106_ == true) then
                      local function _108_(...)
                        local _109_, _110_ = ...
                        if ((_109_ == true) and (nil ~= _110_)) then
                          local mpacked = _110_
                          local function _111_(...)
                            local _112_, _113_ = ...
                            if (nil ~= _112_) then
                              local index_path = _112_
                              local function _114_(...)
                                local _115_, _116_ = ...
                                if (nil ~= _115_) then
                                  local fout = _115_
                                  local function _117_(...)
                                    local _118_, _119_ = ...
                                    if (_118_ == true) then
                                      local function _120_(...)
                                        local _121_, _122_ = ...
                                        if (_121_ == true) then
                                          return record0
                                        elseif ((_121_ == false) and (nil ~= _122_)) then
                                          local e = _122_
                                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                        elseif ((_121_ == nil) and (nil ~= _122_)) then
                                          local e = _122_
                                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                        elseif (nil ~= _121_) then
                                          local e = _121_
                                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                        else
                                          return nil
                                        end
                                      end
                                      return _120_(fout:close())
                                    elseif ((_118_ == false) and (nil ~= _119_)) then
                                      local e = _119_
                                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                    elseif ((_118_ == nil) and (nil ~= _119_)) then
                                      local e = _119_
                                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                    elseif (nil ~= _118_) then
                                      local e = _118_
                                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                    else
                                      return nil
                                    end
                                  end
                                  return _117_(fout:write(mpacked))
                                elseif ((_115_ == false) and (nil ~= _116_)) then
                                  local e = _116_
                                  return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                elseif ((_115_ == nil) and (nil ~= _116_)) then
                                  local e = _116_
                                  return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                elseif (nil ~= _115_) then
                                  local e = _115_
                                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                else
                                  return nil
                                end
                              end
                              return _114_(io.open(index_path, "wb"))
                            elseif ((_112_ == false) and (nil ~= _113_)) then
                              local e = _113_
                              return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                            elseif ((_112_ == nil) and (nil ~= _113_)) then
                              local e = _113_
                              return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                            elseif (nil ~= _112_) then
                              local e = _112_
                              return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                            else
                              return nil
                            end
                          end
                          return _111_(path__3eindex_key(lua_path))
                        elseif ((_109_ == false) and (nil ~= _110_)) then
                          local e = _110_
                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                        elseif ((_109_ == nil) and (nil ~= _110_)) then
                          local e = _110_
                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                        elseif (nil ~= _109_) then
                          local e = _109_
                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                        else
                          return nil
                        end
                      end
                      return _108_(pcall(vim.mpack.encode, {version = INDEX_VERSION, data = record0}))
                    elseif ((_106_ == false) and (nil ~= _107_)) then
                      local e = _107_
                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                    elseif ((_106_ == nil) and (nil ~= _107_)) then
                      local e = _107_
                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                    elseif (nil ~= _106_) then
                      local e = _106_
                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                    else
                      return nil
                    end
                  end
                  return _105_(make_path(INDEX_ROOT_PATH))
                elseif ((_103_ == false) and (nil ~= _104_)) then
                  local e = _104_
                  return error(string.format("could not save record %s\n %s", record["lua-path"], e))
                elseif ((_103_ == nil) and (nil ~= _104_)) then
                  local e = _104_
                  return error(string.format("could not save record %s\n %s", record["lua-path"], e))
                elseif (nil ~= _103_) then
                  local e = _103_
                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
                else
                  return nil
                end
              end
              local function _130_(...)
                record["lua-path-mtime-at-save"] = mtime
                record["lua-path-size-at-save"] = size
                return record
              end
              return _102_(_130_(...))
            elseif ((_100_ == false) and (nil ~= _101_)) then
              local e = _101_
              return error(string.format("could not save record %s\n %s", record["lua-path"], e))
            elseif ((_100_ == nil) and (nil ~= _101_)) then
              local e = _101_
              return error(string.format("could not save record %s\n %s", record["lua-path"], e))
            elseif (nil ~= _100_) then
              local e = _100_
              return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
            else
              return nil
            end
          end
          return _99_(file_stat(lua_path))
        elseif ((_97_ == false) and (nil ~= _98_)) then
          local e = _98_
          return error(string.format("could not save record %s\n %s", record["lua-path"], e))
        elseif ((_97_ == nil) and (nil ~= _98_)) then
          local e = _98_
          return error(string.format("could not save record %s\n %s", record["lua-path"], e))
        elseif (nil ~= _97_) then
          local e = _97_
          return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
        else
          return nil
        end
      end
      return _96_(record)
    elseif ((_94_ == false) and (nil ~= _95_)) then
      local e = _95_
      return error(string.format("could not save record %s\n %s", record["lua-path"], e))
    elseif ((_94_ == nil) and (nil ~= _95_)) then
      local e = _95_
      return error(string.format("could not save record %s\n %s", record["lua-path"], e))
    elseif (nil ~= _94_) then
      local e = _94_
      return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
    else
      return nil
    end
  end
  return _93_((module_3f(record) or ftplugin_3f(record)))
end
local function drop(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:102")
  local function _134_(...)
    local _135_, _136_ = ...
    if (nil ~= _135_) then
      local index_key = _135_
      local function _137_(...)
        local _138_, _139_ = ...
        if (_138_ == true) then
          return true
        elseif ((_138_ == false) and (nil ~= _139_)) then
          local e = _139_
          return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
        else
          return nil
        end
      end
      return _137_(rm_file(index_key))
    elseif ((_135_ == false) and (nil ~= _136_)) then
      local e = _136_
      return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
    else
      return nil
    end
  end
  return _134_(path__3eindex_key(record["lua-path"]))
end
local function new(type, modname, src_path, _3fopts)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record.fnl:111")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record.fnl:111")
  _G.assert((nil ~= type), "Missing argument type on fnl/hotpot/loader/record.fnl:111")
  local module
  do
    local _142_, _143_ = type
    if (_142_ == RECORD_TYPE_MODULE) then
      module = "hotpot.loader.record.module"
    elseif (_142_ == RECORD_TYPE_FTPLUGIN) then
      module = "hotpot.loader.record.ftplugin"
    elseif true then
      local _ = _142_
      module = error(string.format("Could not create record, unknown type: %s at %s", type, src_path))
    else
      module = nil
    end
  end
  local _let_145_ = require(module)
  local new_type = _let_145_["new"]
  local src_path0 = vim.fs.normalize(src_path)
  local modname0 = string.gsub(modname, "%.%.+", ".")
  local record = new_type(modname0, src_path0, _3fopts)
  return vim.tbl_extend("force", record, {type = type, ["lua-path-mtime-at-save"] = 0, ["lua-path-size-at-save"] = 0, files = {{path = src_path0, mtime = {sec = 0, nsec = 0}, size = 0}}})
end
local function set_record_files(record, files)
  _G.assert((nil ~= files), "Missing argument files on fnl/hotpot/loader/record.fnl:129")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:129")
  local files0
  do
    table.insert(files, 1, record["src-path"])
    files0 = files
  end
  local file_stats
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for _, path in ipairs(files0) do
      local val_19_auto
      do
        local _let_146_ = file_stat(path)
        local mtime = _let_146_["mtime"]
        local size = _let_146_["size"]
        val_19_auto = {path = path, mtime = mtime, size = size}
      end
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    file_stats = tbl_17_auto
  end
  record["files"] = file_stats
  return record
end
local function lua_file_modified_3f(record)
  local _let_148_ = record
  local lua_path = _let_148_["lua-path"]
  local _let_149_ = file_stat(lua_path)
  local _let_150_ = _let_149_["mtime"]
  local sec = _let_150_["sec"]
  local nsec = _let_150_["nsec"]
  local size = _let_149_["size"]
  return not ((size == record["lua-path-size-at-save"]) and (sec == record["lua-path-mtime-at-save"].sec) and (nsec == record["lua-path-mtime-at-save"].nsec))
end
local function _151_(...)
  return new(RECORD_TYPE_MODULE, ...)
end
local function _152_(...)
  return new(RECORD_TYPE_FTPLUGIN, ...)
end
return {save = save, fetch = fetch, drop = drop, ["new-module"] = _151_, ["new-ftplugin"] = _152_, ["set-record-files"] = set_record_files, ["lua-file-modified?"] = lua_file_modified_3f}