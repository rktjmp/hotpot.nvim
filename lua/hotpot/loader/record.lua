local fmt = string["format"]
local _local_1_ = require("hotpot.fs")
local file_exists_3f = _local_1_["file-exists?"]
local file_missing_3f = _local_1_["file-missing?"]
local read_file_21 = _local_1_["read-file!"]
local file_stat = _local_1_["file-stat"]
local rm_file = _local_1_["rm-file"]
local make_path = _local_1_["make-path"]
local join_path = _local_1_["join-path"]
local _local_2_ = require("hotpot.runtime")
local windows_3f = _local_2_["windows?"]
local cache_root_path = _local_2_["cache-root-path"]
local uri_encode
local and_3_ = vim.uri_encode
if and_3_ then
  local function _4_(_241)
    return vim.uri_encode(_241, "rfc2396")
  end
  and_3_ = _4_
end
local or_5_ = and_3_
if not or_5_ then
  local function _6_(str)
    local _let_7_ = require("bit")
    local tohex = _let_7_["tohex"]
    local percent_encode_char
    local function _8_(_241)
      return ("%" .. tohex(string.byte(_241), 2))
    end
    percent_encode_char = _8_
    local rfc2396_pattern = "([^A-Za-z0-9%-_.!~*'()])"
    return (string.gsub(str, rfc2396_pattern, percent_encode_char))
  end
  or_5_ = _6_
end
uri_encode = or_5_
local INDEX_ROOT_PATH = join_path(cache_root_path(), "index")
local INDEX_VERSION = 3
local RECORD_TYPE_MODULE = 1
local RECORD_TYPE_RUNTIME = 2
local function module_3f(r)
  local _10_
  do
    local t_9_ = r
    if (nil ~= t_9_) then
      t_9_ = t_9_.type
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
      t_12_ = t_12_.type
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
                        if ((_28_ == true) and ((_G.type(_29_) == "table") and (_29_.version == INDEX_VERSION) and (nil ~= _29_.data))) then
                          local data = _29_.data
                          return data
                        else
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
                                    else
                                      local _0 = _35_
                                      return nil
                                    end
                                  end
                                  return _34_(rm_file(index_path0))
                                else
                                  local _0 = _33_
                                  return nil
                                end
                              end
                              return _32_(file_exists_3f(index_path0))
                            else
                              local _0 = _31_
                              return nil
                            end
                          end
                          return _30_(path__3eindex_key(lua_path))
                        end
                      end
                      return _27_(pcall(vim.mpack.decode, bytes))
                    else
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
                                else
                                  local _0 = _45_
                                  return nil
                                end
                              end
                              return _44_(rm_file(index_path0))
                            else
                              local _0 = _43_
                              return nil
                            end
                          end
                          return _42_(file_exists_3f(index_path0))
                        else
                          local _0 = _41_
                          return nil
                        end
                      end
                      return _40_(path__3eindex_key(lua_path))
                    end
                  end
                  return _25_(fin:close())
                else
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
                            else
                              local _0 = _55_
                              return nil
                            end
                          end
                          return _54_(rm_file(index_path0))
                        else
                          local _0 = _53_
                          return nil
                        end
                      end
                      return _52_(file_exists_3f(index_path0))
                    else
                      local _0 = _51_
                      return nil
                    end
                  end
                  return _50_(path__3eindex_key(lua_path))
                end
              end
              return _23_(fin:read("a*"))
            else
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
                        else
                          local _0 = _65_
                          return nil
                        end
                      end
                      return _64_(rm_file(index_path0))
                    else
                      local _0 = _63_
                      return nil
                    end
                  end
                  return _62_(file_exists_3f(index_path0))
                else
                  local _0 = _61_
                  return nil
                end
              end
              return _60_(path__3eindex_key(lua_path))
            end
          end
          return _21_(io.open(index_path, "rb"))
        else
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
                    else
                      local _0 = _75_
                      return nil
                    end
                  end
                  return _74_(rm_file(index_path0))
                else
                  local _0 = _73_
                  return nil
                end
              end
              return _72_(file_exists_3f(index_path0))
            else
              local _0 = _71_
              return nil
            end
          end
          return _70_(path__3eindex_key(lua_path))
        end
      end
      return _19_(file_exists_3f(index_path))
    else
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
                else
                  local _0 = _85_
                  return nil
                end
              end
              return _84_(rm_file(index_path))
            else
              local _0 = _83_
              return nil
            end
          end
          return _82_(file_exists_3f(index_path))
        else
          local _0 = _81_
          return nil
        end
      end
      return _80_(path__3eindex_key(lua_path))
    end
  end
  return _17_(path__3eindex_key(lua_path))
end
local function fetch(lua_path)
  local _90_, _91_ = load(lua_path)
  if (nil ~= _90_) then
    local record = _90_
    local and_92_ = (nil ~= record)
    if and_92_ then
      local record0 = record
      and_92_ = module_3f(record0)
    end
    if and_92_ then
      local record0 = record
      return record0
    else
      local and_94_ = (nil ~= record)
      if and_94_ then
        local record0 = record
        and_94_ = runtime_3f(record0)
      end
      if and_94_ then
        local record0 = record
        return record0
      else
        local _ = record
        return nil, fmt("Could not load record, unknown type. Record: %s", vim.inspect(record))
      end
    end
  elseif ((_90_ == false) and (nil ~= _91_)) then
    local e = _91_
    return nil
  else
    local _ = _90_
    return nil
  end
end
local function save(record)
  local function _98_(...)
    local _99_, _100_ = ...
    if (_99_ == true) then
      local function _101_(...)
        local _102_, _103_ = ...
        if ((_G.type(_102_) == "table") and (nil ~= _102_["lua-path"])) then
          local lua_path = _102_["lua-path"]
          local function _104_(...)
            local _105_, _106_ = ...
            if ((_G.type(_105_) == "table") and (nil ~= _105_.mtime) and (nil ~= _105_.size)) then
              local mtime = _105_.mtime
              local size = _105_.size
              local function _107_(...)
                local _108_, _109_ = ...
                if (nil ~= _108_) then
                  local record0 = _108_
                  local function _110_(...)
                    local _111_, _112_ = ...
                    if (_111_ == true) then
                      local function _113_(...)
                        local _114_, _115_ = ...
                        if ((_114_ == true) and (nil ~= _115_)) then
                          local mpacked = _115_
                          local function _116_(...)
                            local _117_, _118_ = ...
                            if (nil ~= _117_) then
                              local index_path = _117_
                              local function _119_(...)
                                local _120_, _121_ = ...
                                if (nil ~= _120_) then
                                  local fout = _120_
                                  local function _122_(...)
                                    local _123_, _124_ = ...
                                    if (_123_ == true) then
                                      local function _125_(...)
                                        local _126_, _127_ = ...
                                        if (_126_ == true) then
                                          return record0
                                        elseif ((_126_ == false) and (nil ~= _127_)) then
                                          local e = _127_
                                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                        elseif ((_126_ == nil) and (nil ~= _127_)) then
                                          local e = _127_
                                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                        else
                                          local _3fe = _126_
                                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                        end
                                      end
                                      return _125_(fout:close())
                                    elseif ((_123_ == false) and (nil ~= _124_)) then
                                      local e = _124_
                                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                    elseif ((_123_ == nil) and (nil ~= _124_)) then
                                      local e = _124_
                                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                    else
                                      local _3fe = _123_
                                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                    end
                                  end
                                  return _122_(fout:write(mpacked))
                                elseif ((_120_ == false) and (nil ~= _121_)) then
                                  local e = _121_
                                  return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                elseif ((_120_ == nil) and (nil ~= _121_)) then
                                  local e = _121_
                                  return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                                else
                                  local _3fe = _120_
                                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                                end
                              end
                              return _119_(io.open(index_path, "wb"))
                            elseif ((_117_ == false) and (nil ~= _118_)) then
                              local e = _118_
                              return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                            elseif ((_117_ == nil) and (nil ~= _118_)) then
                              local e = _118_
                              return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                            else
                              local _3fe = _117_
                              return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                            end
                          end
                          return _116_(path__3eindex_key(lua_path))
                        elseif ((_114_ == false) and (nil ~= _115_)) then
                          local e = _115_
                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                        elseif ((_114_ == nil) and (nil ~= _115_)) then
                          local e = _115_
                          return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                        else
                          local _3fe = _114_
                          return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                        end
                      end
                      return _113_(pcall(vim.mpack.encode, {version = INDEX_VERSION, data = record0}))
                    elseif ((_111_ == false) and (nil ~= _112_)) then
                      local e = _112_
                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                    elseif ((_111_ == nil) and (nil ~= _112_)) then
                      local e = _112_
                      return error(string.format("Could not save record for %s\nReason: %s", record0["lua-path"], e))
                    else
                      local _3fe = _111_
                      return error(string.format("unknown error when saving record %s %s", vim.inspect(record0), vim.inspect(_3fe)))
                    end
                  end
                  return _110_(make_path(INDEX_ROOT_PATH))
                elseif ((_108_ == false) and (nil ~= _109_)) then
                  local e = _109_
                  return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
                elseif ((_108_ == nil) and (nil ~= _109_)) then
                  local e = _109_
                  return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
                else
                  local _3fe = _108_
                  return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
                end
              end
              local function _135_(...)
                record["lua-path-mtime-at-save"] = mtime
                record["lua-path-size-at-save"] = size
                return record
              end
              return _107_(_135_(...))
            elseif ((_105_ == false) and (nil ~= _106_)) then
              local e = _106_
              return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
            elseif ((_105_ == nil) and (nil ~= _106_)) then
              local e = _106_
              return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
            else
              local _3fe = _105_
              return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
            end
          end
          return _104_(file_stat(lua_path))
        elseif ((_102_ == false) and (nil ~= _103_)) then
          local e = _103_
          return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
        elseif ((_102_ == nil) and (nil ~= _103_)) then
          local e = _103_
          return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
        else
          local _3fe = _102_
          return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
        end
      end
      return _101_(record)
    elseif ((_99_ == false) and (nil ~= _100_)) then
      local e = _100_
      return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
    elseif ((_99_ == nil) and (nil ~= _100_)) then
      local e = _100_
      return error(string.format("Could not save record for %s\nReason: %s", record["lua-path"], e))
    else
      local _3fe = _99_
      return error(string.format("unknown error when saving record %s %s", vim.inspect(record), vim.inspect(_3fe)))
    end
  end
  return _98_((module_3f(record) or runtime_3f(record)))
end
local function drop(record)
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:108")
  local function _139_(...)
    local _140_, _141_ = ...
    if (nil ~= _140_) then
      local index_key = _140_
      local function _142_(...)
        local _143_, _144_ = ...
        if (_143_ == true) then
          return true
        elseif ((_143_ == false) and (nil ~= _144_)) then
          local e = _144_
          return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
        else
          return nil
        end
      end
      return _142_(rm_file(index_key))
    elseif ((_140_ == false) and (nil ~= _141_)) then
      local e = _141_
      return error(fmt("Could not drop index at %s\n%s", record["lua-path"], e))
    else
      return nil
    end
  end
  return _139_(path__3eindex_key(record["lua-path"]))
end
local function new(type, modname, src_path, _3fopts)
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record.fnl:117")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record.fnl:117")
  _G.assert((nil ~= type), "Missing argument type on fnl/hotpot/loader/record.fnl:117")
  local module
  do
    local _147_, _148_ = type
    if (_147_ == RECORD_TYPE_MODULE) then
      module = "hotpot.loader.record.module"
    elseif (_147_ == RECORD_TYPE_RUNTIME) then
      module = "hotpot.loader.record.runtime"
    else
      local _ = _147_
      module = error(string.format("Could not create record, unknown type: %s at %s", type, src_path))
    end
  end
  local _let_150_ = require(module)
  local new_type = _let_150_["new"]
  local src_path0 = vim.fs.normalize(src_path)
  local modname0 = string.gsub(modname, "%.%.+", ".")
  local record = new_type(modname0, src_path0, _3fopts)
  return vim.tbl_extend("force", record, {type = type, ["lua-path-mtime-at-save"] = 0, ["lua-path-size-at-save"] = 0, files = {{path = src_path0, mtime = {sec = 0, nsec = 0}, size = 0}}})
end
local function set_files(record, files)
  _G.assert((nil ~= files), "Missing argument files on fnl/hotpot/loader/record.fnl:135")
  _G.assert((nil ~= record), "Missing argument record on fnl/hotpot/loader/record.fnl:135")
  local files0
  do
    table.insert(files, 1, record["src-path"])
    files0 = files
  end
  local file_stats
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, path in ipairs(files0) do
      local val_23_auto
      do
        local _let_151_ = file_stat(path)
        local mtime = _let_151_["mtime"]
        local size = _let_151_["size"]
        val_23_auto = {path = path, mtime = mtime, size = size}
      end
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    file_stats = tbl_21_auto
  end
  record["files"] = file_stats
  return record
end
local function _153_(...)
  return new(RECORD_TYPE_MODULE, ...)
end
local function _154_(...)
  return new(RECORD_TYPE_RUNTIME, ...)
end
return {save = save, fetch = fetch, drop = drop, ["new-module"] = _153_, ["new-runtime"] = _154_, ["set-files"] = set_files}