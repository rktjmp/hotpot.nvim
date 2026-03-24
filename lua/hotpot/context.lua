local function _1_(src, path)
  return src
end
do local _ = {schema = "hotpot/2", atomic = true, verbose = true, target = "cache", transform = _1_, ignore = {"some/lib/**/*.lua", "junk/*.fnl"}, compiler = {["extra-compiler-env"] = {vim = vim}, ["error-pinpoint"] = false}} end
local M = {}
local m = {}
local function mtime(path)
  local case_2_, case_3_ = vim.uv.fs_stat(path)
  if ((_G.type(case_2_) == "table") and ((_G.type(case_2_.mtime) == "table") and (nil ~= case_2_.mtime.sec))) then
    local sec = case_2_.mtime.sec
    return sec
  elseif ((case_2_ == nil) and (nil ~= case_3_)) then
    local err = case_3_
    return error(err)
  else
    return nil
  end
end
local function missing_3f(path)
  local case_5_ = vim.uv.fs_stat(path)
  if (case_5_ == nil) then
    return true
  else
    local _ = case_5_
    return false
  end
end
local function read_file_21(path)
  local fh = assert(io.open(path, "r"), ("fs.read-file! io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _8_()
    return fh:read("*a")
  end
  local _10_
  do
    local t_9_ = _G
    if (nil ~= t_9_) then
      t_9_ = t_9_.package
    else
    end
    if (nil ~= t_9_) then
      t_9_ = t_9_.loaded
    else
    end
    if (nil ~= t_9_) then
      t_9_ = t_9_.fennel
    else
    end
    _10_ = t_9_
  end
  local or_14_ = _10_ or _G.debug
  if not or_14_ then
    local function _15_()
      return ""
    end
    or_14_ = {traceback = _15_}
  end
  return close_handlers_13_(_G.xpcall(_8_, or_14_.traceback))
end
local function write_file_21(path, lines)
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _17_()
    return fh:write(lines)
  end
  local _19_
  do
    local t_18_ = _G
    if (nil ~= t_18_) then
      t_18_ = t_18_.package
    else
    end
    if (nil ~= t_18_) then
      t_18_ = t_18_.loaded
    else
    end
    if (nil ~= t_18_) then
      t_18_ = t_18_.fennel
    else
    end
    _19_ = t_18_
  end
  local or_23_ = _19_ or _G.debug
  if not or_23_ then
    local function _24_()
      return ""
    end
    or_23_ = {traceback = _24_}
  end
  return close_handlers_13_(_G.xpcall(_17_, or_23_.traceback))
end
local _2aconfig_root_path_2a = vim.fs.normalize(vim.fn.stdpath("config"))
local function base_spec()
  return {schema = "hotpot/2", atomic = true, verbose = true, ignore = {}, compiler = {["extra-compiler-env"] = {vim = vim}, ["error-pinpoint"] = false}}
end
local function default_config_spec()
  return vim.tbl_extend("force", base_spec(), {target = "cache"})
end
local function default_api_spec()
  return base_spec()
end
local function err_msg_unable_to_load(path, m0)
  return string.format("Unable to load %s: %s", path, m0)
end
local function load_spec_file(path)
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/context.fnl:65", 2)
  else
  end
  assert(vim.uv.fs_stat(path), err_msg_unable_to_load(path, "does not exist"))
  local fennel = require("hotpot.aot.fennel")()
  local def = fennel.dofile(path)
  assert(("table" == type(def)), err_msg_unable_to_load(path, "must return table"))
  assert((def.schema == "hotpot/2"), err_msg_unable_to_load(path, "must define schema key as hotpot/2"))
  assert(((def.target == "cache") or (def.target == "colocate")), err_msg_unable_to_load(path, "must define target key as cache or colocate"))
  return def
end
local function spec__3econtext(spec, meta)
  if (nil == meta) then
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:76", 2)
  else
  end
  if (nil == spec) then
    _G.error("Missing argument spec on fnl/hotpot/context.fnl:76", 2)
  else
  end
  local path
  if ((_G.type(meta) == "table") and (meta.kind == "api")) then
    path = {}
  elseif ((_G.type(meta) == "table") and (meta.root == nil)) then
    path = error(err_msg_unable_to_load("unknown", "internal error: did not provide root directory to spec->context"))
  elseif ((_G.type(meta) == "table") and (meta.kind == "config") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(spec) == "table") and (spec.target == "cache")) then
      path = {source = root, dest = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "site/hotpot/start"))}
    elseif ((_G.type(spec) == "table") and (spec.target == "colocate")) then
      path = {source = root, dest = root}
    else
      path = nil
    end
  elseif ((_G.type(meta) == "table") and (meta.kind == "plugin") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(spec) == "table") and (spec.target == "colocate")) then
      path = {source = root, dest = root}
    elseif ((_G.type(spec) == "table") and (spec.target == "cache")) then
      path = error(err_msg_unable_to_load(root, "non-config directories may only use target: :colocate"))
    else
      path = nil
    end
  else
    local _ = meta
    path = error(err_msg_unable_to_load("unknown", "internal error: spec meta missing kind"))
  end
  local ctx = vim.tbl_extend("force", base_spec(), spec, {path = path})
  return ctx
end
local function create_context(_3fdirectory)
  if (nil ~= _3fdirectory) then
    local directory = _3fdirectory
    local root = vim.fs.normalize(directory)
    local path = vim.fs.joinpath(root, ".hotpot.fnl")
    local case_31_, case_32_ = (nil ~= vim.uv.fs_stat(path)), (root == _2aconfig_root_path_2a)
    if ((case_31_ == true) and (case_32_ == true)) then
      return spec__3econtext(load_spec_file(path), {root = root, kind = "config"})
    elseif ((case_31_ == false) and (case_32_ == true)) then
      return spec__3econtext(default_config_spec(), {root = _2aconfig_root_path_2a, kind = "config"})
    elseif ((case_31_ == true) and (case_32_ == false)) then
      return spec__3econtext(load_spec_file(path), {root = root, kind = "plugin"})
    elseif ((case_31_ == false) and (case_32_ == false)) then
      return error(err_msg_unable_to_load(path, "does not exist"))
    else
      return nil
    end
  elseif (_3fdirectory == nil) then
    return spec__3econtext(default_api_spec(), {kind = "api"})
  else
    return nil
  end
end
m["find-files"] = function(root, extension_pattern, ignore)
  if (nil == ignore) then
    _G.error("Missing argument ignore on fnl/hotpot/context.fnl:123", 2)
  else
  end
  if (nil == extension_pattern) then
    _G.error("Missing argument extension-pattern on fnl/hotpot/context.fnl:123", 2)
  else
  end
  if (nil == root) then
    _G.error("Missing argument root on fnl/hotpot/context.fnl:123", 2)
  else
  end
  local function _38_(name, path)
    local and_39_ = name:match(extension_pattern)
    if and_39_ then
      local ok_3f = true
      for _, rule in ipairs(ignore) do
        if not ok_3f then break end
        ok_3f = not rule:match(path)
      end
      and_39_ = ok_3f
    end
    return and_39_
  end
  return vim.fs.find(_38_, {limit = math.huge, type = "file", path = root})
end
m["find-source-files"] = function(ctx)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:130", 2)
  else
  end
  local _let_41_ = ctx.path
  local source = _let_41_.source
  local dest = _let_41_.dest
  local ignore = ctx.ignore
  local files = m["find-files"](source, "%.fnlm?$", ignore)
  local list = {fnl = {}, fnlm = {}}
  for _, fnl_abs in ipairs(files) do
    local ext = fnl_abs:match("%.(fnlm?)$")
    local fnl_rel = vim.fs.relpath(source, fnl_abs, {})
    local lua_rel, lua_abs
    if (ext == "fnl") then
      local lua_rel0 = string.gsub(string.gsub(fnl_rel, "^fnl/", "lua/"), "%.fnl$", ".lua")
      local lua_abs0 = vim.fs.joinpath(dest, lua_rel0)
      lua_rel, lua_abs = lua_rel0, lua_abs0
    else
      lua_rel, lua_abs = nil
    end
    table.insert(list[ext], {["fnl-rel"] = fnl_rel, ["fnl-abs"] = fnl_abs, ["lua-rel"] = lua_rel, ["lua-abs"] = lua_abs})
    list = list
  end
  return list
end
m["find-orphaned-files"] = function(ctx, source_files)
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:147", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:147", 2)
  else
  end
  local _let_45_ = ctx.path
  local dest = _let_45_.dest
  local ignore = ctx.ignore
  local known_lua_files
  do
    local tbl_21_ = {}
    for _, _46_ in ipairs(source_files.fnl) do
      local lua_abs = _46_["lua-abs"]
      local k_22_, v_23_ = lua_abs, true
      if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
        tbl_21_[k_22_] = v_23_
      else
      end
    end
    known_lua_files = tbl_21_
  end
  local existing_lua_files = m["find-files"](dest, "%.lua$", ignore)
  local orphans
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, path in ipairs(existing_lua_files) do
      local val_28_
      if not known_lua_files[path] then
        val_28_ = path
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    orphans = tbl_26_
  end
  return orphans
end
m["filter-stale-source-files"] = function(files)
  if (nil == files) then
    _G.error("Missing argument files on fnl/hotpot/context.fnl:159", 2)
  else
  end
  local fnl = files.fnl
  local fnlm = files.fnlm
  local fnlm_mtime
  do
    local newest_mtime = -1
    for _, _51_ in ipairs(fnlm) do
      local fnl_abs = _51_["fnl-abs"]
      newest_mtime = math.max(newest_mtime, mtime(fnl_abs))
    end
    fnlm_mtime = newest_mtime
  end
  local needs_compiling
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _52_ in ipairs(fnl) do
      local fnl_abs = _52_["fnl-abs"]
      local lua_abs = _52_["lua-abs"]
      local file = _52_
      local val_28_
      do
        local lua_mtime
        do
          local case_53_, case_54_ = pcall(mtime, lua_abs)
          if ((case_53_ == true) and (nil ~= case_54_)) then
            local mtime0 = case_54_
            lua_mtime = mtime0
          elseif ((case_53_ == false) and true) then
            local _0 = case_54_
            lua_mtime = 0
          else
            lua_mtime = nil
          end
        end
        local fnl_mtime = mtime(fnl_abs)
        if ((lua_mtime < fnl_mtime) or (fnl_mtime < fnlm_mtime)) then
          val_28_ = file
        else
          val_28_ = nil
        end
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    needs_compiling = tbl_26_
  end
  return needs_compiling
end
M.new = function(_3fdirectory)
  local case_58_, case_59_ = pcall(create_context, _3fdirectory)
  if ((case_58_ == true) and (nil ~= case_59_)) then
    local context = case_59_
    return context
  elseif ((case_58_ == false) and (nil ~= case_59_)) then
    local err = case_59_
    return nil, err
  else
    return nil
  end
end
M.nearest = function(starting_path)
  if (nil == starting_path) then
    _G.error("Missing argument starting-path on fnl/hotpot/context.fnl:190", 2)
  else
  end
  local case_62_ = vim.fs.relpath(_2aconfig_root_path_2a, starting_path)
  if (nil ~= case_62_) then
    local path_inside_config = case_62_
    return _2aconfig_root_path_2a
  elseif (case_62_ == nil) then
    return vim.fs.root(starting_path, ".hotpot.fnl")
  else
    return nil
  end
end
M["compile-string"] = function(ctx, fnl_source, meta)
  if (nil == meta) then
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:196", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:196", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:196", 2)
  else
  end
  local fennel = require("hotpot.aot.fennel")()
  local compiler_options = vim.tbl_extend("force", ctx.compiler, {filename = meta.filename})
  local fnl_source0
  if ((_G.type(ctx) == "table") and (nil ~= ctx.transform)) then
    local transform = ctx.transform
    fnl_source0 = transform(fnl_source, meta.filename)
  else
    local _ = ctx
    fnl_source0 = fnl_source
  end
  local case_68_, case_69_ = pcall(fennel["compile-string"], fnl_source0, compiler_options)
  if ((case_68_ == true) and (nil ~= case_69_)) then
    local src = case_69_
    return src
  elseif ((case_68_ == false) and (nil ~= case_69_)) then
    local err = case_69_
    return nil, err
  else
    return nil
  end
end
M.sync = function(ctx)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:212", 2)
  else
  end
  local source_files = m["find-source-files"](ctx)
  local stale_files = m["filter-stale-source-files"](source_files)
  local results
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _72_ in ipairs(stale_files) do
      local fnl_abs = _72_["fnl-abs"]
      local fnl_rel = _72_["fnl-rel"]
      local lua_abs = _72_["lua-abs"]
      local val_28_
      do
        local fnl_source = read_file_21(fnl_abs)
        local case_73_, case_74_ = M["compile-string"](ctx, fnl_source, {filename = fnl_rel})
        if (nil ~= case_73_) then
          local lua_source = case_73_
          val_28_ = {["lua-abs"] = lua_abs, source = lua_source}
        elseif ((case_73_ == nil) and (nil ~= case_74_)) then
          local err = case_74_
          val_28_ = {["fnl-abs"] = fnl_abs, error = err}
        else
          val_28_ = nil
        end
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    results = tbl_26_
  end
  local all_ok_3f
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, result in ipairs(results) do
      local val_28_
      if ((_G.type(result) == "table") and (nil ~= result["fnl-abs"]) and (nil ~= result.error)) then
        local fnl_abs = result["fnl-abs"]
        local error = result.error
        local bad = result
        val_28_ = bad
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    all_ok_3f = tbl_26_
  end
  do
    local case_79_ = #all_ok_3f
    if (case_79_ == 0) then
      for _, _80_ in ipairs(results) do
        local lua_abs = _80_["lua-abs"]
        local source = _80_.source
        vim.fn.mkdir(vim.fs.dirname(lua_abs), "p")
        write_file_21(lua_abs, source)
      end
    elseif (nil ~= case_79_) then
      local n = case_79_
      vim.notify("Errors")
    else
    end
  end
  return nil
end
return M