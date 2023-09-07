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
local _local_3_ = require("hotpot.runtime")
local windows_3f = _local_3_["windows?"]
local cache_root_path = _local_3_["cache-root-path"]
local uri_encode
local function _4_(_241)
  return vim.uri_encode(_241, "rfc2396")
end
local function _5_(str)
  local _let_6_ = require("bit")
  local tohex = _let_6_["tohex"]
  local percent_encode_char
  local function _7_(_241)
    return ("%" .. tohex(string.byte(_241), 2))
  end
  percent_encode_char = _7_
  local rfc2396_pattern = "([^A-Za-z0-9%-_.!~*'()])"
  local _8_ = string.gsub(str, rfc2396_pattern, percent_encode_char)
  return _8_
end
uri_encode = ((vim.uri_encode and _4_) or _5_)
local INDEX_ROOT_PATH = join_path(cache_root_path(), "index")
local INDEX_VERSION = 2
local RECORD_TYPE_MODULE = 1
local RECORD_TYPE_RUNTIME = 2
local function module_3f(r)
  local _10_
  do
    local t_9_ = r
    if (nil ~= t_9_) then
      t_9_ = (t_9_).type
    else
    end
    _10_ = t_9_
  end
  return (RECORD_TYPE_MODULE == _10_)
end
local function runtime_3f(r)
  local _13_
  do
    local t_12_ = r
    if (nil ~= t_12_) then
      t_12_ = (t_12_).type
    else
    end
    _13_ = t_12_
  end
  return (RECORD_TYPE_RUNTIME == _13_)
end
local function path__3eindex_key(path)
  _G.assert((nil ~= path), "Missing argument path on fnl/hotpot/loader/record.fnl:38")
  local normalize_path = vim.fs.normalize(path)
  local uri_path = (uri_encode(normalize_path, "rfc2396") .. "-metadata.mpack")
  local uri_index_path = join_path(INDEX_ROOT_PATH, uri_path)
  if (not windows_3f or (windows_3f and (#uri_index_path < 259))) then
    return uri_index_path
  else
    local sha_path = vim.fn.sha256(normalize_path)
    local sha_index_path = (join_path(INDEX_ROOT_PATH, sha_path) .. "-metadata.mpack")
    if (#sha_index_path < 259) then
      return sha_index_path
    else
      return false, string.format(("The generated index-path for %s was over windows " .. "maximum allowed path length. You may encounter " .. "issues with building new versions of this file. " .. "Consider trying `:h hotpot-dot-hotpot` with build = true."), path)
    end
  end
end
local function load(lua_path)
  local function _17_(...)
    local _18_ = ...
    if (nil ~= _18_) then
      local index_path = _18_
      local function _19_(...)
        local _20_ = ...
        if (_20_ == true) then
          local function _21_(...)
            local _22_ = ...
            if (nil ~= _22_) then
              local fin = _22_
              local function _23_(...)
                local _24_ = ...
                if (nil ~= _24_) then
                  local bytes = _24_
                  local function _25_(...)
                    local _26_ = ...
                    if (_26_ == true) then
                      local function _27_(...)
                        local _28_, _29_ = ...
                        if ((_28_ == true) and ((_G.type(_29_) == "table") and ((_29_).version == INDEX_VERSION) and (nil ~= (_29_).data))) then
                          local data = (_29_).data
                          return data
                        elseif true then
                          local _ = _28_
                          local function _30_(...)
                            local _31_ = ...
                            if (nil ~= _31_) then
                              local index_path0 = _31_
                              local function _32_(...)
                                local _33_ = ...
                                if (_33_ == true) then
                                  local function _34_(...)
                                    local _35_ = ...
                                    if (_35_ == true) then
                                      return nil
                                    elseif true then
                                      local _0 = _35_
                                      return nil
                                    else
                                      return nil
                                    end
                                  end
                                  return _34_(rm_file(index_path0))
                                elseif true then
                                  local _0 = _33_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _32_(file_exists_3f(index_path0))
                            elseif true then
                              local _0 = _31_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _30_(path__3eindex_key(lua_path))
                        else
                          return nil
                        end
                      end
                      return _27_(pcall(vim.mpack.decode, bytes))
                    elseif true then
                      local _ = _26_
                      local function _40_(...)
                        local _41_ = ...
                        if (nil ~= _41_) then
                          local index_path0 = _41_
                          local function _42_(...)
                            local _43_ = ...
                            if (_43_ == true) then
                              local function _44_(...)
                                local _45_ = ...
                                if (_45_ == true) then
                                  return nil
                                elseif true then
                                  local _0 = _45_
                                  return nil
                                else
                                  return nil
                                end
                              end
                              return _44_(rm_file(index_path0))
                            elseif true then
                              local _0 = _43_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _42_(file_exists_3f(index_path0))
                        elseif true then
                          local _0 = _41_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _40_(path__3eindex_key(lua_path))
                    else
                      return nil
                    end
                  end
                  return _25_(fin:close())
                elseif true then
                  local _ = _24_
                  local function _50_(...)
                    local _51_ = ...
                    if (nil ~= _51_) then
                      local index_path0 = _51_
                      local function _52_(...)
                        local _53_ = ...
                        if (_53_ == true) then
                          local function _54_(...)
                            local _55_ = ...
                            if (_55_ == true) then
                              return nil
                            elseif true then
                              local _0 = _55_
                              return nil
                            else
                              return nil
                            end
                          end
                          return _54_(rm_file(index_path0))
                        elseif true then
                          local _0 = _53_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _52_(file_exists_3f(index_path0))
                    elseif true then
                      local _0 = _51_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _50_(path__3eindex_key(lua_path))
                else
                  return nil
                end
              end
              return _23_(fin:read("a*"))
            elseif true then
              local _ = _22_
              local function _60_(...)
                local _61_ = ...
                if (nil ~= _61_) then
                  local index_path0 = _61_
                  local function _62_(...)
                    local _63_ = ...
                    if (_63_ == true) then
                      local function _64_(...)
                        local _65_ = ...
                        if (_65_ == true) then
                          return nil
                        elseif true then
                          local _0 = _65_
                          return nil
                        else
                          return nil
                        end
                      end
                      return _64_(rm_file(index_path0))
                    elseif true then
                      local _0 = _63_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _62_(file_exists_3f(index_path0))
                elseif true then
                  local _0 = _61_
                  return nil
                else
                  return nil
                end
              end
              return _60_(path__3eindex_key(lua_path))
            else
              return nil
            end
          end
          return _21_(io.open(index_path, "rb"))
        elseif true then
          local _ = _20_
          local function _70_(...)
            local _71_ = ...
            if (nil ~= _71_) then
              local index_path0 = _71_
              local function _72_(...)
                local _73_ = ...
                if (_73_ == true) then
                  local function _74_(...)
                    local _75_ = ...
                    if (_75_ == true) then
                      return nil
                    elseif true then
                      local _0 = _75_
                      return nil
                    else
                      return nil
                    end
                  end
                  return _74_(rm_file(index_path0))
                elseif true then
                  local _0 = _73_
                  return nil
                else
                  return nil
                end
              end
              return _72_(file_exists_3f(index_path0))
            elseif true then
              local _0 = _71_
              return nil
            else
              return nil
            end
          end
          return _70_(path__3eindex_key(lua_path))
        else
          return nil
        end
      end
      return _19_(file_exists_3f(index_path))
    elseif true then
      local _ = _18_
      local function _80_(...)
        local _81_ = ...
        if (nil ~= _81_) then
          local index_path = _81_
          local function _82_(...)
            local _83_ = ...
            if (_83_ == true) then
              local function _84_(...)
                local _85_ = ...
                if (_85_ == true) then
                  return nil
                elseif true then
                  local _0 = _85_
                  return nil
                else
                  return nil
                end
              end
              return _84_(rm_file(index_path))
            elseif true then
              local _0 = _83_
              return nil
            else
              return nil
            end
          end
          return _82_(file_exists_3f(index_path))
        elseif true then
          local _0 = _81_
          return nil
        else
          return nil
        end
      end
      return _80_(path__3eindex_key(lua_path))
    else
      return nil
    end
  end
  return _17_(path__3eindex_key(lua_path))
end
local function fetch(lua_path)
  local _90_, _91_ = load(lua_path)
  if (nil ~= _90_) then
    local record = _90_
    local function _92_()
      local record0 = record
      return module_3f(record0)
    end
    if ((nil ~= record) and _92_()) then
      local record0 = record
      return record0
    else
      local function _93_()
        local record0 = record
        return runtime_3f(record0)
      end
      if ((nil ~= record) and _93_()) then
        local record0 = record
        return record0
      elseif true then
        local _ = record
        return nil, fmt("Could not load record, unknown type. Record: %s", vim.inspect(record))
      else
        return nil
      end
    end
  elseif ((_90_ == false) and (nil ~= _91_)) then
    local e = _91_
    return nil
  elseif true then
    local _ = _90_
    return nil
  else
    return nil
  end
end
local function save(record)
  local function _96_(...)
    local _97_, _98_ = ...
    if (_97_ == true) then
      local function _99_(...)
        local _100_, _101_ = ...
        if ((_G.type(_100_) == "table") and (nil ~= (_100_)["lua-path"])) then
          local lua_path = (_100_)["lua-path"]
          local function _102_(...)
            local _103_, _104_ = ...
            if ((_G.type(_103_) == "table") and (nil ~= (_103_).mtime) and (nil ~= (_103_).size)) then
              local mtime = (_103_).mtime
              local size = (_103_).size
              local function _105_(...)
                local _106_, _107_ = ...
                if (nil ~= _106_) then
                  local record0 = _106_
                  local function _108_(...)
                    local _109_, _110_ = ...
                    if (_109_ == true) then
                      local function _111_(...)
                        local _112_, _113_ = ...
                        if ((_112_ == true) and (nil ~= _113_)) then
                          local mpacked = _113_
                          local function _114_(...)
                            local _115_, _116_ = ...
                            if (nil ~= _115_) then
                              local index_path = _115_
                              local function _117_(...)
                                local _118_, _119_ = ...
                                if (nil ~= _118_) then
                                  local fout = _118_
                                  local function _120_(...)
                                    local _121_, _122_ = ...
                                    if (_121_ == true) then
                                      local function _123_(...)
                                        local _124_, _125_ = ...
                                        if (_124_ == true) then
                                          return record0
                                        elseif ((_124_ == false) and (nil ~= _125_)) then
                                          local e = _125_
                                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                        elseif ((_124_ == nil) and (nil ~= _125_)) then
                                          local e = _125_
                                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                        elseif true then
                                          local _3fe = _124_
                                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                        else
                                          return nil
                                        end
                                      end
                                      return _123_(fout:close())
                                    elseif ((_121_ == false) and (nil ~= _122_)) then
                                      local e = _122_
                                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                    elseif ((_121_ == nil) and (nil ~= _122_)) then
                                      local e = _122_
                                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                    elseif true then
                                      local _3fe = _121_
                                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                    else
                                      return nil
                                    end
                                  end
                                  return _120_(fout:write(mpacked))
                                elseif ((_118_ == false) and (nil ~= _119_)) then
                                  local e = _119_
                                  return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                elseif ((_118_ == nil) and (nil ~= _119_)) then
                                  local e = _119_
                                  return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                elseif true then
                                  local _3fe = _118_
                                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                else
                                  return nil
                                end
                              end
                              return _117_(io.open(index_path, "wb"))
                            elseif ((_115_ == false) and (nil ~= _116_)) then
                              local e = _116_
                              return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                            elseif ((_115_ == nil) and (nil ~= _116_)) then
                              local e = _116_
                              return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                            elseif true then
                              local _3fe = _115_
                              return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                            else
                              return nil
                            end
                          end
                          return _114_(path__3eindex_key(lua_path))
                        elseif ((_112_ == false) and (nil ~= _113_)) then
                          local e = _113_
                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                        elseif ((_112_ == nil) and (nil ~= _113_)) then
                          local e = _113_
                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                        elseif true then
                          local _3fe = _112_
                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                        else
                          return nil
                        end
                      end
                      return _111_(pcall(vim.mpack.encode, {version = INDEX_VERSION, data = record0}))
                    elseif ((_109_ == false) and (nil ~= _110_)) then
                      local e = _110_
                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                    elseif ((_109_ == nil) and (nil ~= _110_)) then
                      local e = _110_
                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                    elseif true then
                      local _3fe = _109_
                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                    else
                      return nil
                    end
                  end
                  return _108_(make_path(INDEX_ROOT_PATH))
                elseif ((_106_ == false) and (nil ~= _107_)) then
                  local e = _107_
                  return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
                elseif ((_106_ == nil) and (nil ~= _107_)) then
                  local e = _107_
                  return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
                elseif true then
                  local _3fe = _106_
                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
                else
                  return nil
                end
              end
              local function _133_(...)
                record["lua-path-mtime-at-save"] = mtime
                record["lua-path-size-at-save"] = size
                return record
              end
              return _105_(_133_(...))
            elseif ((_103_ == false) and (nil ~= _104_)) then
              local e = _104_
              return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
            elseif ((_103_ == nil) and (nil ~= _104_)) then
              local e = _104_
              return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
            elseif true then
              local _3fe = _103_
              return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
            else
              return nil
            end
          end
          return _102_(file_stat(lua_path))
        elseif ((_100_ == false) and (nil ~= _101_)) then
          local e = _101_
          return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
        elseif ((_100_ == nil) and (nil ~= _101_)) then
          local e = _101_
          return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
        elseif true then
          local _3fe = _100_
          return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
        else
          return nil
        end
      end
      return _99_(record)
    elseif ((_97_ == false) and (nil ~= _98_)) then
      local e = _98_
      return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
    elseif ((_97_ == nil) and (nil ~= _98_)) then
      local e = _98_
      return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
    elseif true then
      local _3fe = _97_
      return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
    else
      return nil
    end
  end
  return _96_((module_3f(record) or runtime_3f(record)))
end
local function drop(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:108")
  local function _137_(...)
    local _138_, _139_ = ...
    if (nil ~= _138_) then
      local index_key = _138_
      local function _140_(...)
        local _141_, _142_ = ...
        if (_141_ == true) then
          return true
        elseif ((_141_ == false) and (nil ~= _142_)) then
          local e = _142_
          return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
        else
          return nil
        end
      end
      return _140_(rm_file(index_key))
    elseif ((_138_ == false) and (nil ~= _139_)) then
      local e = _139_
      return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
    else
      return nil
    end
  end
  return _137_(path__3eindex_key(record["lua-path"]))
end
local function new(type, modname, src_path, _3fopts)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record.fnl:117")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record.fnl:117")
  _G.assert((nil ~= type), "Missing argument type on fnl/hotpot/loader/record.fnl:117")
  local module
  do
    local _145_, _146_ = type
    if (_145_ == RECORD_TYPE_MODULE) then
      module = "hotpot.loader.record.module"
    elseif (_145_ == RECORD_TYPE_RUNTIME) then
      module = "hotpot.loader.record.runtime"
    elseif true then
      local _ = _145_
      module = error(string.format("Could not create record, unknown type: %s at %s", type, src_path))
    else
      module = nil
    end
  end
  local _let_148_ = require(module)
  local new_type = _let_148_["new"]
  local src_path0 = vim.fs.normalize(src_path)
  local modname0 = string.gsub(modname, "%.%.+", ".")
  local record = new_type(modname0, src_path0, _3fopts)
  return vim.tbl_extend("force", record, {type = type, ["lua-path-mtime-at-save"] = 0, ["lua-path-size-at-save"] = 0, files = {{path = src_path0, mtime = {sec = 0, nsec = 0}, size = 0}}})
end
local function set_record_files(record, files)
  _G.assert((nil ~= files), "Missing argument files on fnl/hotpot/loader/record.fnl:135")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:135")
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
        local _let_149_ = file_stat(path)
        local mtime = _let_149_["mtime"]
        local size = _let_149_["size"]
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
  local _let_151_ = record
  local lua_path = _let_151_["lua-path"]
  local _let_152_ = file_stat(lua_path)
  local _let_153_ = _let_152_["mtime"]
  local sec = _let_153_["sec"]
  local nsec = _let_153_["nsec"]
  local size = _let_152_["size"]
  return not ((size == record["lua-path-size-at-save"]) and (sec == record["lua-path-mtime-at-save"].sec) and (nsec == record["lua-path-mtime-at-save"].nsec))
end
local function _154_(...)
  return new(RECORD_TYPE_MODULE, ...)
end
local function _155_(...)
  return new(RECORD_TYPE_RUNTIME, ...)
end
return {save = save, fetch = fetch, drop = drop, ["new-module"] = _154_, ["new-runtime"] = _155_, ["set-record-files"] = set_record_files, ["lua-file-modified?"] = lua_file_modified_3f}