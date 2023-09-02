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
local normalise_path
do
  local _let_3_ = vim.fs
  local normalize = _let_3_["normalize"]
  local function _4_(_241)
    return normalize(_241, {expand_env = false})
  end
  normalise_path = _4_
end
local uri_encode
local function _5_(_241)
  return vim.uri_encode(_241, "rfc2396")
end
local function _6_(str)
  local _let_7_ = require("bit")
  local tohex = _let_7_["tohex"]
  local percent_encode_char
  local function _8_(_241)
    return ("%" .. tohex(string.byte(_241), 2))
  end
  percent_encode_char = _8_
  local rfc2396_pattern = "([^A-Za-z0-9%-_.!~*'()])"
  local _9_ = string.gsub(str, rfc2396_pattern, percent_encode_char)
  return _9_
end
uri_encode = ((vim.uri_encode and _5_) or _6_)
local CACHE_ROOT = normalise_path(join_path(vim.fn.stdpath("cache"), "hotpot"))
local INDEX_ROOT_PATH = normalise_path(join_path(CACHE_ROOT, "index"))
local INDEX_VERSION = 2
local RECORD_TYPE_MODULE = 1
local RECORD_TYPE_FTPLUGIN = 2
local function module_3f(r)
  local _11_
  do
    local t_10_ = r
    if (nil ~= t_10_) then
      t_10_ = (t_10_).type
    else
    end
    _11_ = t_10_
  end
  return (RECORD_TYPE_MODULE == _11_)
end
local function ftplugin_3f(r)
  local _14_
  do
    local t_13_ = r
    if (nil ~= t_13_) then
      t_13_ = (t_13_).type
    else
    end
    _14_ = t_13_
  end
  return (RECORD_TYPE_FTPLUGIN == _14_)
end
local function path__3eindex_key(path)
  _G.assert((nil ~= path), "Missing argument path on fnl/hotpot/loader/record.fnl:49")
  local path0 = normalise_path(path)
  return join_path(INDEX_ROOT_PATH, (uri_encode(path0, "rfc2396") .. "-metadata.mpack"))
end
local function load(lua_path)
  local function _16_(...)
    local _17_ = ...
    if (nil ~= _17_) then
      local index_path = _17_
      local function _18_(...)
        local _19_ = ...
        if (_19_ == true) then
          local function _20_(...)
            local _21_ = ...
            if (nil ~= _21_) then
              local fin = _21_
              local function _22_(...)
                local _23_ = ...
                if (nil ~= _23_) then
                  local bytes = _23_
                  local function _24_(...)
                    local _25_ = ...
                    if (_25_ == true) then
                      local function _26_(...)
                        local _27_, _28_ = ...
                        if ((_27_ == true) and ((_G.type(_28_) == "table") and ((_28_).version == INDEX_VERSION) and (nil ~= (_28_).data))) then
                          local data = (_28_).data
                          return data
                        elseif true then
                          local _ = _27_
                          local function _29_(...)
                            local _30_ = ...
                            if (nil ~= _30_) then
                              local index_path0 = _30_
                              local function _31_(...)
                                local _32_ = ...
                                if (_32_ == true) then
                                  local function _33_(...)
                                    local _34_ = ...
                                    if (_34_ == true) then
                                      return nil
                                    elseif true then
                                      local _0 = _34_
                                      return nil
                                    else
                                      return nil
                                    end
                                  end
                                  return _33_(rm_file(index_path0))
                                elseif true then
                                  local _0 = _32_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _31_(file_exists_3f(index_path0))
                            elseif true then
                              local _0 = _30_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _29_(path__3eindex_key(lua_path))
                        else
                          return nil
                        end
                      end
                      return _26_(pcall(vim.mpack.decode, bytes))
                    elseif true then
                      local _ = _25_
                      local function _39_(...)
                        local _40_ = ...
                        if (nil ~= _40_) then
                          local index_path0 = _40_
                          local function _41_(...)
                            local _42_ = ...
                            if (_42_ == true) then
                              local function _43_(...)
                                local _44_ = ...
                                if (_44_ == true) then
                                  return nil
                                elseif true then
                                  local _0 = _44_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _43_(rm_file(index_path0))
                            elseif true then
                              local _0 = _42_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _41_(file_exists_3f(index_path0))
                        elseif true then
                          local _0 = _40_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _39_(path__3eindex_key(lua_path))
                    else
                      return nil
                    end
                  end
                  return _24_(fin:close())
                elseif true then
                  local _ = _23_
                  local function _49_(...)
                    local _50_ = ...
                    if (nil ~= _50_) then
                      local index_path0 = _50_
                      local function _51_(...)
                        local _52_ = ...
                        if (_52_ == true) then
                          local function _53_(...)
                            local _54_ = ...
                            if (_54_ == true) then
                              return nil
                            elseif true then
                              local _0 = _54_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _53_(rm_file(index_path0))
                        elseif true then
                          local _0 = _52_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _51_(file_exists_3f(index_path0))
                    elseif true then
                      local _0 = _50_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _49_(path__3eindex_key(lua_path))
                else
                  return nil
                end
              end
              return _22_(fin:read("a*"))
            elseif true then
              local _ = _21_
              local function _59_(...)
                local _60_ = ...
                if (nil ~= _60_) then
                  local index_path0 = _60_
                  local function _61_(...)
                    local _62_ = ...
                    if (_62_ == true) then
                      local function _63_(...)
                        local _64_ = ...
                        if (_64_ == true) then
                          return nil
                        elseif true then
                          local _0 = _64_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _63_(rm_file(index_path0))
                    elseif true then
                      local _0 = _62_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _61_(file_exists_3f(index_path0))
                elseif true then
                  local _0 = _60_
                  return nil
                else
                  return nil
                end
              end
              return _59_(path__3eindex_key(lua_path))
            else
              return nil
            end
          end
          return _20_(io.open(index_path, "rb"))
        elseif true then
          local _ = _19_
          local function _69_(...)
            local _70_ = ...
            if (nil ~= _70_) then
              local index_path0 = _70_
              local function _71_(...)
                local _72_ = ...
                if (_72_ == true) then
                  local function _73_(...)
                    local _74_ = ...
                    if (_74_ == true) then
                      return nil
                    elseif true then
                      local _0 = _74_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _73_(rm_file(index_path0))
                elseif true then
                  local _0 = _72_
                  return nil
                else
                  return nil
                end
              end
              return _71_(file_exists_3f(index_path0))
            elseif true then
              local _0 = _70_
              return nil
            else
              return nil
            end
          end
          return _69_(path__3eindex_key(lua_path))
        else
          return nil
        end
      end
      return _18_(file_exists_3f(index_path))
    elseif true then
      local _ = _17_
      local function _79_(...)
        local _80_ = ...
        if (nil ~= _80_) then
          local index_path = _80_
          local function _81_(...)
            local _82_ = ...
            if (_82_ == true) then
              local function _83_(...)
                local _84_ = ...
                if (_84_ == true) then
                  return nil
                elseif true then
                  local _0 = _84_
                  return nil
                else
                  return nil
                end
              end
              return _83_(rm_file(index_path))
            elseif true then
              local _0 = _82_
              return nil
            else
              return nil
            end
          end
          return _81_(file_exists_3f(index_path))
        elseif true then
          local _0 = _80_
          return nil
        else
          return nil
        end
      end
      return _79_(path__3eindex_key(lua_path))
    else
      return nil
    end
  end
  return _16_(path__3eindex_key(lua_path))
end
local function fetch(lua_path)
  local _89_, _90_ = load(lua_path)
  if (nil ~= _89_) then
    local record = _89_
    local function _91_()
      local record0 = record
      return module_3f(record0)
    end
    if ((nil ~= record) and _91_()) then
      local record0 = record
      return record0
    else
      local function _92_()
        local record0 = record
        return ftplugin_3f(record0)
      end
      if ((nil ~= record) and _92_()) then
        local record0 = record
        return record0
      elseif true then
        local _ = record
        return nil, fmt("Could not load record, unknown type. Record: %s", vim.inspect(record))
      else
        return nil
      end
    end
  elseif ((_89_ == false) and (nil ~= _90_)) then
    local e = _90_
    return nil
  elseif true then
    local _ = _89_
    return nil
  else
    return nil
  end
end
local function save(record)
  local function _95_(...)
    local _96_, _97_ = ...
    if (_96_ == true) then
      local function _98_(...)
        local _99_, _100_ = ...
        if ((_G.type(_99_) == "table") and (nil ~= (_99_)["lua-path"])) then
          local lua_path = (_99_)["lua-path"]
          local function _101_(...)
            local _102_, _103_ = ...
            if ((_G.type(_102_) == "table") and (nil ~= (_102_).mtime) and (nil ~= (_102_).size)) then
              local mtime = (_102_).mtime
              local size = (_102_).size
              local function _104_(...)
                local _105_, _106_ = ...
                if (nil ~= _105_) then
                  local record0 = _105_
                  local function _107_(...)
                    local _108_, _109_ = ...
                    if (_108_ == true) then
                      local function _110_(...)
                        local _111_, _112_ = ...
                        if ((_111_ == true) and (nil ~= _112_)) then
                          local mpacked = _112_
                          local function _113_(...)
                            local _114_, _115_ = ...
                            if (nil ~= _114_) then
                              local index_path = _114_
                              local function _116_(...)
                                local _117_, _118_ = ...
                                if (nil ~= _117_) then
                                  local fout = _117_
                                  local function _119_(...)
                                    local _120_, _121_ = ...
                                    if (_120_ == true) then
                                      local function _122_(...)
                                        local _123_, _124_ = ...
                                        if (_123_ == true) then
                                          return record0
                                        elseif ((_123_ == false) and (nil ~= _124_)) then
                                          local e = _124_
                                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                        elseif ((_123_ == nil) and (nil ~= _124_)) then
                                          local e = _124_
                                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                        elseif (nil ~= _123_) then
                                          local e = _123_
                                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                        else
                                          return nil
                                        end
                                      end
                                      return _122_(fout:close())
                                    elseif ((_120_ == false) and (nil ~= _121_)) then
                                      local e = _121_
                                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                    elseif ((_120_ == nil) and (nil ~= _121_)) then
                                      local e = _121_
                                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                    elseif (nil ~= _120_) then
                                      local e = _120_
                                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                    else
                                      return nil
                                    end
                                  end
                                  return _119_(fout:write(mpacked))
                                elseif ((_117_ == false) and (nil ~= _118_)) then
                                  local e = _118_
                                  return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                elseif ((_117_ == nil) and (nil ~= _118_)) then
                                  local e = _118_
                                  return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                                elseif (nil ~= _117_) then
                                  local e = _117_
                                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                                else
                                  return nil
                                end
                              end
                              return _116_(io.open(index_path, "wb"))
                            elseif ((_114_ == false) and (nil ~= _115_)) then
                              local e = _115_
                              return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                            elseif ((_114_ == nil) and (nil ~= _115_)) then
                              local e = _115_
                              return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                            elseif (nil ~= _114_) then
                              local e = _114_
                              return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                            else
                              return nil
                            end
                          end
                          return _113_(path__3eindex_key(lua_path))
                        elseif ((_111_ == false) and (nil ~= _112_)) then
                          local e = _112_
                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                        elseif ((_111_ == nil) and (nil ~= _112_)) then
                          local e = _112_
                          return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                        elseif (nil ~= _111_) then
                          local e = _111_
                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                        else
                          return nil
                        end
                      end
                      return _110_(pcall(vim.mpack.encode, {version = INDEX_VERSION, data = record0}))
                    elseif ((_108_ == false) and (nil ~= _109_)) then
                      local e = _109_
                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                    elseif ((_108_ == nil) and (nil ~= _109_)) then
                      local e = _109_
                      return error(string.format("could not save record %s\n %s", record0["lua-path"], e))
                    elseif (nil ~= _108_) then
                      local e = _108_
                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(e)))
                    else
                      return nil
                    end
                  end
                  return _107_(make_path(INDEX_ROOT_PATH))
                elseif ((_105_ == false) and (nil ~= _106_)) then
                  local e = _106_
                  return error(string.format("could not save record %s\n %s", record["lua-path"], e))
                elseif ((_105_ == nil) and (nil ~= _106_)) then
                  local e = _106_
                  return error(string.format("could not save record %s\n %s", record["lua-path"], e))
                elseif (nil ~= _105_) then
                  local e = _105_
                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
                else
                  return nil
                end
              end
              local function _132_(...)
                record["lua-path-mtime-at-save"] = mtime
                record["lua-path-size-at-save"] = size
                return record
              end
              return _104_(_132_(...))
            elseif ((_102_ == false) and (nil ~= _103_)) then
              local e = _103_
              return error(string.format("could not save record %s\n %s", record["lua-path"], e))
            elseif ((_102_ == nil) and (nil ~= _103_)) then
              local e = _103_
              return error(string.format("could not save record %s\n %s", record["lua-path"], e))
            elseif (nil ~= _102_) then
              local e = _102_
              return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
            else
              return nil
            end
          end
          return _101_(file_stat(lua_path))
        elseif ((_99_ == false) and (nil ~= _100_)) then
          local e = _100_
          return error(string.format("could not save record %s\n %s", record["lua-path"], e))
        elseif ((_99_ == nil) and (nil ~= _100_)) then
          local e = _100_
          return error(string.format("could not save record %s\n %s", record["lua-path"], e))
        elseif (nil ~= _99_) then
          local e = _99_
          return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
        else
          return nil
        end
      end
      return _98_(record)
    elseif ((_96_ == false) and (nil ~= _97_)) then
      local e = _97_
      return error(string.format("could not save record %s\n %s", record["lua-path"], e))
    elseif ((_96_ == nil) and (nil ~= _97_)) then
      local e = _97_
      return error(string.format("could not save record %s\n %s", record["lua-path"], e))
    elseif (nil ~= _96_) then
      local e = _96_
      return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(e)))
    else
      return nil
    end
  end
  return _95_((module_3f(record) or ftplugin_3f(record)))
end
local function drop(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:105")
  local function _136_(...)
    local _137_, _138_ = ...
    if (nil ~= _137_) then
      local index_key = _137_
      local function _139_(...)
        local _140_, _141_ = ...
        if (_140_ == true) then
          return true
        elseif ((_140_ == false) and (nil ~= _141_)) then
          local e = _141_
          return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
        else
          return nil
        end
      end
      return _139_(rm_file(index_key))
    elseif ((_137_ == false) and (nil ~= _138_)) then
      local e = _138_
      return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
    else
      return nil
    end
  end
  return _136_(path__3eindex_key(record["lua-path"]))
end
local function new(type, modname, src_path, _3fopts)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record.fnl:114")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record.fnl:114")
  _G.assert((nil ~= type), "Missing argument type on fnl/hotpot/loader/record.fnl:114")
  local module
  do
    local _144_, _145_ = type
    if (_144_ == RECORD_TYPE_MODULE) then
      module = "hotpot.loader.record.module"
    elseif (_144_ == RECORD_TYPE_FTPLUGIN) then
      module = "hotpot.loader.record.ftplugin"
    elseif true then
      local _ = _144_
      module = error(string.format("Could not create record, unknown type: %s at %s", type, src_path))
    else
      module = nil
    end
  end
  local _let_147_ = require(module)
  local new_type = _let_147_["new"]
  local src_path0 = normalise_path(src_path)
  local modname0 = string.gsub(modname, "%.%.+", ".")
  local record = new_type(modname0, src_path0, _3fopts)
  return vim.tbl_extend("force", record, {type = type, ["lua-path-mtime-at-save"] = 0, ["lua-path-size-at-save"] = 0, files = {{path = src_path0, mtime = {sec = 0, nsec = 0}, size = 0}}})
end
local function set_record_files(record, files)
  _G.assert((nil ~= files), "Missing argument files on fnl/hotpot/loader/record.fnl:132")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:132")
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
        local _let_148_ = file_stat(path)
        local mtime = _let_148_["mtime"]
        local size = _let_148_["size"]
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
  local _let_150_ = record
  local lua_path = _let_150_["lua-path"]
  local _let_151_ = file_stat(lua_path)
  local _let_152_ = _let_151_["mtime"]
  local sec = _let_152_["sec"]
  local nsec = _let_152_["nsec"]
  local size = _let_151_["size"]
  return not ((size == record["lua-path-size-at-save"]) and (sec == record["lua-path-mtime-at-save"].sec) and (nsec == record["lua-path-mtime-at-save"].nsec))
end
local function _153_(...)
  return new(RECORD_TYPE_MODULE, ...)
end
local function _154_(...)
  return new(RECORD_TYPE_FTPLUGIN, ...)
end
return {save = save, fetch = fetch, drop = drop, ["new-module"] = _153_, ["new-ftplugin"] = _154_, ["set-record-files"] = set_record_files, ["lua-file-modified?"] = lua_file_modified_3f}