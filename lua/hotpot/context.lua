local _local_1_ = require("hotpot.const")
local HOTPOT_CACHE_ROOT = _local_1_.HOTPOT_CACHE_ROOT
local NVIM_CONFIG_ROOT = _local_1_.NVIM_CONFIG_ROOT
local M, m = {}, {}
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
local function base_spec()
  return {schema = "hotpot/2", atomic = true, verbose = true, ignore = {}, compiler = {["error-pinpoint"] = false}}
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
    _G.error("Missing argument path on fnl/hotpot/context.fnl:44", 2)
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
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:55", 2)
  else
  end
  if (nil == spec) then
    _G.error("Missing argument spec on fnl/hotpot/context.fnl:55", 2)
  else
  end
  local source = meta.source
  local path
  if ((_G.type(meta) == "table") and (meta.kind == "api")) then
    path = {}
  elseif ((_G.type(meta) == "table") and (meta.root == nil)) then
    path = error(err_msg_unable_to_load("unknown", "internal error: did not provide root directory to spec->context"))
  elseif ((_G.type(meta) == "table") and (meta.kind == "config") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(spec) == "table") and (spec.target == "cache")) then
      path = {source = root, dest = HOTPOT_CACHE_ROOT}
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
  local ctx = vim.tbl_extend("force", base_spec(), spec, {path = path, source = (source or "in-memory")})
  local or_31_ = ctx.transform
  if not or_31_ then
    local function _32_(_241)
      return _241
    end
    or_31_ = _32_
  end
  ctx.transform = or_31_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, glob in ipairs(ctx.ignore) do
      local val_28_ = vim.glob.to_lpeg(glob)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    ctx.ignore = tbl_26_
  end
  assert(("function" == type(ctx.transform)), string.format("%s `transform` not a function", ctx._source))
  return ctx
end
local function create_context(_3fdirectory)
  if (nil ~= _3fdirectory) then
    local directory = _3fdirectory
    local root = vim.fs.normalize(directory)
    local path = vim.fs.joinpath(root, ".hotpot.fnl")
    local dot_hotpot_exists_3f = (nil ~= vim.uv.fs_stat(path))
    local root_is_config_root_3f = (root == NVIM_CONFIG_ROOT)
    local case_34_, case_35_ = dot_hotpot_exists_3f, root_is_config_root_3f
    if ((case_34_ == true) and (case_35_ == true)) then
      return spec__3econtext(load_spec_file(path), {root = root, kind = "config", source = path})
    elseif ((case_34_ == false) and (case_35_ == true)) then
      return spec__3econtext(default_config_spec(), {root = NVIM_CONFIG_ROOT, kind = "config"})
    elseif ((case_34_ == true) and (case_35_ == false)) then
      return spec__3econtext(load_spec_file(path), {root = root, kind = "plugin", source = path})
    elseif ((case_34_ == false) and (case_35_ == false)) then
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
    _G.error("Missing argument ignore on fnl/hotpot/context.fnl:110", 2)
  else
  end
  if (nil == extension_pattern) then
    _G.error("Missing argument extension-pattern on fnl/hotpot/context.fnl:110", 2)
  else
  end
  if (nil == root) then
    _G.error("Missing argument root on fnl/hotpot/context.fnl:110", 2)
  else
  end
  local function _41_(name, dir)
    local path = vim.fs.relpath(root, vim.fs.joinpath(dir, name), {})
    local and_42_ = (".hotpot.fnl" ~= name) and name:match(extension_pattern)
    if and_42_ then
      local ok_3f = true
      for _, rule in ipairs(ignore) do
        if not ok_3f then break end
        ok_3f = not rule:match(path)
      end
      and_42_ = ok_3f
    end
    return and_42_
  end
  return vim.fs.find(_41_, {limit = math.huge, type = "file", path = root})
end
m["find-source-files"] = function(ctx)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:125", 2)
  else
  end
  local _let_44_ = ctx.path
  local source = _let_44_.source
  local dest = _let_44_.dest
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
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:142", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:142", 2)
  else
  end
  local _let_48_ = ctx.path
  local dest = _let_48_.dest
  local ignore = ctx.ignore
  local known_lua_files
  do
    local tbl_21_ = {}
    for _, _49_ in ipairs(source_files.fnl) do
      local lua_abs = _49_["lua-abs"]
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
    _G.error("Missing argument files on fnl/hotpot/context.fnl:154", 2)
  else
  end
  local fnl = files.fnl
  local fnlm = files.fnlm
  local fnlm_mtime
  do
    local newest_mtime = -1
    for _, _54_ in ipairs(fnlm) do
      local fnl_abs = _54_["fnl-abs"]
      newest_mtime = math.max(newest_mtime, mtime(fnl_abs))
    end
    fnlm_mtime = newest_mtime
  end
  local needs_compiling
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _55_ in ipairs(fnl) do
      local fnl_abs = _55_["fnl-abs"]
      local lua_abs = _55_["lua-abs"]
      local file = _55_
      local val_28_
      do
        local lua_mtime
        do
          local case_56_, case_57_ = pcall(mtime, lua_abs)
          if ((case_56_ == true) and (nil ~= case_57_)) then
            local mtime0 = case_57_
            lua_mtime = mtime0
          elseif ((case_56_ == false) and true) then
            local _0 = case_57_
            lua_mtime = 0
          else
            lua_mtime = nil
          end
        end
        local fnl_mtime = mtime(fnl_abs)
        if ((lua_mtime < fnl_mtime) or (lua_mtime < fnlm_mtime)) then
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
  local case_61_, case_62_ = pcall(create_context, _3fdirectory)
  if ((case_61_ == true) and (nil ~= case_62_)) then
    local context = case_62_
    return context
  elseif ((case_61_ == false) and (nil ~= case_62_)) then
    local err = case_62_
    return nil, err
  else
    return nil
  end
end
M.nearest = function(starting_path)
  if (nil == starting_path) then
    _G.error("Missing argument starting-path on fnl/hotpot/context.fnl:188", 2)
  else
  end
  local case_65_ = vim.fs.relpath(NVIM_CONFIG_ROOT, starting_path)
  if (nil ~= case_65_) then
    local path_inside_config = case_65_
    return NVIM_CONFIG_ROOT
  elseif (case_65_ == nil) then
    return vim.fs.root(starting_path, ".hotpot.fnl")
  else
    return nil
  end
end
M["compile-string"] = function(ctx, fnl_source, meta)
  if (nil == meta) then
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:194", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:194", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:194", 2)
  else
  end
  local fennel = require("hotpot.aot.fennel")()
  local compiler_options = vim.tbl_extend("force", ctx.compiler, {filename = meta.filename})
  local fnl_source0 = m["apply-transform"](ctx, fnl_source, meta.filename)
  local old_paths = {path = fennel.path, ["macro-path"] = fennel["macro-path"]}
  local _let_70_ = ctx.path
  local source = _let_70_.source
  local _
  do
    fennel.path = table.concat({(source .. "/fnl/?.fnl"), (source .. "/fnl/?/init.fnl"), old_paths.path}, ";")
    fennel["macro-path"] = table.concat({(source .. "/fnl/?.fnlm"), (source .. "/fnl/?/init.fnlm"), (source .. "/fnl/?.fnl"), (source .. "/fnl/?/init-macros.fnl"), (source .. "/fnl/?/init.fnl"), old_paths["macro-path"]}, ";")
    _ = nil
  end
  local _0 = vim.print(fennel["macro-path"])
  local ok_3f, val = pcall(fennel["compile-string"], fnl_source0, compiler_options)
  local _1
  do
    fennel.path = old_paths.path
    fennel["macro-path"] = old_paths["macro-path"]
    _1 = nil
  end
  local case_71_, case_72_ = ok_3f, val
  if ((case_71_ == true) and (nil ~= case_72_)) then
    local src = case_72_
    return src
  elseif ((case_71_ == false) and (nil ~= case_72_)) then
    local err = case_72_
    return error(err)
  else
    return nil
  end
end
m["apply-transform"] = function(ctx, source, path)
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/context.fnl:234", 2)
  else
  end
  if (nil == source) then
    _G.error("Missing argument source on fnl/hotpot/context.fnl:234", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:234", 2)
  else
  end
  local transform = ctx.transform
  local new_src = transform(source, path)
  assert(("string" == type(new_src)), string.format("%s `transform` did not return string", ctx._source))
  return new_src
end
M.sync = function(ctx, _3foptions)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:241", 2)
  else
  end
  local options = (_3foptions or {force = false})
  local source_files = m["find-source-files"](ctx)
  local stale_files
  if options.force then
    stale_files = source_files
  else
    stale_files = m["filter-stale-source-files"](source_files)
  end
  local results
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _79_ in ipairs(stale_files) do
      local fnl_abs = _79_["fnl-abs"]
      local fnl_rel = _79_["fnl-rel"]
      local lua_abs = _79_["lua-abs"]
      local val_28_
      do
        local fnl_source = read_file_21(fnl_abs)
        local case_80_, case_81_ = pcall(M["compile-string"], ctx, fnl_source, {filename = fnl_rel})
        if ((case_80_ == true) and (nil ~= case_81_)) then
          local lua_source = case_81_
          val_28_ = {["lua-abs"] = lua_abs, source = lua_source}
        elseif ((case_80_ == false) and (nil ~= case_81_)) then
          local err = case_81_
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
  vim.print(results)
  do
    local case_86_ = #all_ok_3f
    if (case_86_ == 0) then
      for _, _87_ in ipairs(results) do
        local lua_abs = _87_["lua-abs"]
        local source = _87_.source
        vim.fn.mkdir(vim.fs.dirname(lua_abs), "p")
        write_file_21(lua_abs, source)
      end
      local orphans = m["find-orphaned-files"](ctx, source_files)
      for _, orphan in ipairs(orphans) do
        vim.uv.fs_unlink(orphan)
      end
    elseif (nil ~= case_86_) then
      local n = case_86_
      vim.notify("Errors")
    else
    end
  end
  return nil
end
return M