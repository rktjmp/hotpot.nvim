local _local_1_ = require("hotpot.const")
local HOTPOT_CONFIG_CACHE_ROOT = _local_1_.HOTPOT_CONFIG_CACHE_ROOT
local NVIM_CONFIG_ROOT = _local_1_.NVIM_CONFIG_ROOT
local R
local function _2_(t, key)
  local mod = require(("hotpot." .. key))
  t[key] = mod
  return mod
end
R = setmetatable({}, {index = _2_})
local M, m = {}, {}
local function file_mtime(path)
  local case_3_, case_4_ = vim.uv.fs_stat(path)
  if ((_G.type(case_3_) == "table") and ((_G.type(case_3_.mtime) == "table") and (nil ~= case_3_.mtime.sec) and (nil ~= case_3_.mtime.nsec))) then
    local sec = case_3_.mtime.sec
    local nsec = case_3_.mtime.nsec
    local function _5_(this, other)
      return ((sec == other.sec) and (nsec == other.nsec))
    end
    local function _6_(this, other)
      return ((other.sec < sec) or ((other.sec == sec) and (other.nsec < nsec)))
    end
    local function _7_(this, other)
      return ((sec < other.sec) or ((sec == other.sec) and (nsec < other.nsec)))
    end
    return {["equal?"] = _5_, ["after?"] = _6_, ["before?"] = _7_, path = path, sec = sec, nsec = nsec}
  elseif ((case_3_ == nil) and (nil ~= case_4_)) then
    local err = case_4_
    return nil
  else
    return nil
  end
end
local function read_file(path)
  local fh = assert(io.open(path, "r"), ("fs.read-file! io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _10_()
    return fh:read("*a")
  end
  local _12_
  do
    local t_11_ = _G
    if (nil ~= t_11_) then
      t_11_ = t_11_.package
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.loaded
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_.fennel
    else
    end
    _12_ = t_11_
  end
  local or_16_ = _12_ or _G.debug
  if not or_16_ then
    local function _17_()
      return ""
    end
    or_16_ = {traceback = _17_}
  end
  return close_handlers_13_(_G.xpcall(_10_, or_16_.traceback))
end
local function write_file(path, lines)
  assert(("string" == type(lines)), "write file expects string")
  local fh = assert(io.open(path, "w"), ("fs.write-file io.open failed:" .. path))
  local function close_handlers_13_(ok_14_, ...)
    fh:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _19_()
    return fh:write(lines)
  end
  local _21_
  do
    local t_20_ = _G
    if (nil ~= t_20_) then
      t_20_ = t_20_.package
    else
    end
    if (nil ~= t_20_) then
      t_20_ = t_20_.loaded
    else
    end
    if (nil ~= t_20_) then
      t_20_ = t_20_.fennel
    else
    end
    _21_ = t_20_
  end
  local or_25_ = _21_ or _G.debug
  if not or_25_ then
    local function _26_()
      return ""
    end
    or_25_ = {traceback = _26_}
  end
  return close_handlers_13_(_G.xpcall(_19_, or_25_.traceback))
end
local function base_spec()
  local _27_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for k, _ in pairs(_G) do
      local val_28_ = k
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _27_ = tbl_26_
  end
  return {schema = "hotpot/2", ["atomic?"] = true, ["verbose?"] = true, ignore = {}, compiler = {allowedGlobals = _27_, ["error-pinpoint"] = false}}
end
local function is_init_lua_special_case_3f(ctx, fnl_rel)
  if (nil == fnl_rel) then
    _G.error("Missing argument fnl-rel on fnl/hotpot/context.fnl:43", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:43", 2)
  else
  end
  local case_31_, case_32_, case_33_ = ctx.kind, ctx.target, fnl_rel
  if ((case_31_ == "config") and (case_32_ == "cache") and (case_33_ == "init.fnl")) then
    return true
  else
    local _ = case_31_
    return false
  end
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
    _G.error("Missing argument path on fnl/hotpot/context.fnl:58", 2)
  else
  end
  assert(vim.uv.fs_stat(path), err_msg_unable_to_load(path, "does not exist"))
  local fennel = require("hotpot.fennel")
  local content
  do
    local case_36_ = vim.secure.read(path)
    if (nil ~= case_36_) then
      local content0 = case_36_
      content = content0
    elseif (case_36_ == nil) then
      content = error(string.format("Unable to continue with untrusted file: %s", path))
    else
      content = nil
    end
  end
  local _let_38_ = m["make-fennel-path-modifiers"]({path = {source = vim.fs.dirname(path)}}, fennel)
  local update_fennel_path = _let_38_["update-fennel-path"]
  local restore_fennel_path = _let_38_["restore-fennel-path"]
  local _ = update_fennel_path()
  local ok_3f, def = pcall(fennel.eval, content)
  local _0 = restore_fennel_path()
  assert(ok_3f, err_msg_unable_to_load(path, def))
  assert(("table" == type(def)), err_msg_unable_to_load(path, "must return table"))
  assert((def.schema == "hotpot/2"), err_msg_unable_to_load(path, "must define schema key as hotpot/2"))
  assert(((def.target == "cache") or (def.target == "colocate")), err_msg_unable_to_load(path, "must define target key as cache or colocate"))
  return def
end
local function spec__3econtext(spec, meta)
  if (nil == meta) then
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:79", 2)
  else
  end
  if (nil == spec) then
    _G.error("Missing argument spec on fnl/hotpot/context.fnl:79", 2)
  else
  end
  local source = meta.source
  local kind = meta.kind
  local path
  if ((_G.type(meta) == "table") and (meta.kind == "api")) then
    path = {}
  elseif ((_G.type(meta) == "table") and (meta.root == nil)) then
    path = error(err_msg_unable_to_load("unknown", "internal error: did not provide root directory to spec->context"))
  elseif ((_G.type(meta) == "table") and (meta.kind == "config") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(spec) == "table") and (spec.target == "cache")) then
      path = {source = root, dest = HOTPOT_CONFIG_CACHE_ROOT}
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
  local ctx = vim.tbl_extend("force", base_spec(), spec, {kind = kind, path = path, source = (source or "in-memory")})
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
  if ctx.transform then
    assert(("function" == type(ctx.transform)), string.format("%s `transform` not a function", ctx.source))
  else
  end
  return ctx
end
m["find-files"] = function(root, extension_pattern, ignore)
  if (nil == ignore) then
    _G.error("Missing argument ignore on fnl/hotpot/context.fnl:113", 2)
  else
  end
  if (nil == extension_pattern) then
    _G.error("Missing argument extension-pattern on fnl/hotpot/context.fnl:113", 2)
  else
  end
  if (nil == root) then
    _G.error("Missing argument root on fnl/hotpot/context.fnl:113", 2)
  else
  end
  local function _49_(name, dir)
    local path = vim.fs.relpath(root, vim.fs.joinpath(dir, name), {})
    local and_50_ = (".hotpot.fnl" ~= name) and name:match(extension_pattern)
    if and_50_ then
      local ok_3f = true
      for _, rule in ipairs(ignore) do
        if not ok_3f then break end
        ok_3f = not rule:match(path)
      end
      and_50_ = ok_3f
    end
    return and_50_
  end
  return vim.fs.find(_49_, {limit = math.huge, type = "file", path = root})
end
m["find-source-files"] = function(ctx)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:128", 2)
  else
  end
  local _let_52_ = ctx.path
  local source = _let_52_.source
  local dest = _let_52_.dest
  local ignore = ctx.ignore
  local files = m["find-files"](source, "%.fnlm?$", ignore)
  local list = {fnl = {}, fnlm = {}}
  for _, fnl_abs in ipairs(files) do
    local ext = fnl_abs:match("%.(fnlm?)$")
    local fnl_rel = vim.fs.relpath(source, fnl_abs, {})
    local lua_rel, lua_abs
    if ("fnl" == ext) then
      if is_init_lua_special_case_3f(ctx, fnl_rel) then
        local lua_rel0 = string.gsub(fnl_rel, "%.fnl$", ".lua")
        local lua_abs0 = vim.fs.joinpath(source, lua_rel0)
        lua_rel, lua_abs = lua_rel0, lua_abs0
      else
        local lua_rel0 = string.gsub(string.gsub(fnl_rel, "^fnl/", "lua/"), "%.fnl$", ".lua")
        local lua_abs0 = vim.fs.joinpath(dest, lua_rel0)
        lua_rel, lua_abs = lua_rel0, lua_abs0
      end
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
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:153", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:153", 2)
  else
  end
  local _let_57_ = ctx.path
  local dest = _let_57_.dest
  local ignore = ctx.ignore
  local known_lua_files
  do
    local tbl_21_ = {}
    for _, _58_ in ipairs(source_files.fnl) do
      local lua_abs = _58_["lua-abs"]
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
    _G.error("Missing argument files on fnl/hotpot/context.fnl:165", 2)
  else
  end
  local fnl = files.fnl
  local fnlm = files.fnlm
  local fnlm_mtime
  do
    local newest_mtime
    local function _63_()
      return false
    end
    newest_mtime = {sec = 0, nsec = 0, ["after?"] = _63_}
    for _, _64_ in ipairs(fnlm) do
      local fnl_abs = _64_["fnl-abs"]
      local this_mtime = file_mtime(fnl_abs)
      if this_mtime["after?"](this_mtime, newest_mtime) then
        newest_mtime = this_mtime
      else
        newest_mtime = newest_mtime
      end
    end
    fnlm_mtime = newest_mtime
  end
  local needs_compiling
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _66_ in ipairs(fnl) do
      local fnl_abs = _66_["fnl-abs"]
      local lua_abs = _66_["lua-abs"]
      local file = _66_
      local val_28_
      do
        local lua_mtime = file_mtime(lua_abs)
        local fnl_mtime = file_mtime(fnl_abs)
        if (not lua_mtime or fnl_mtime["after?"](fnl_mtime, lua_mtime) or fnlm_mtime["after?"](fnlm_mtime, lua_mtime)) then
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
m["apply-transform"] = function(ctx, source, path)
  if (nil == path) then
    _G.error("Missing argument path on fnl/hotpot/context.fnl:185", 2)
  else
  end
  if (nil == source) then
    _G.error("Missing argument source on fnl/hotpot/context.fnl:185", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:185", 2)
  else
  end
  local case_72_ = ctx.transform
  if (nil ~= case_72_) then
    local transform = case_72_
    local new_src = transform(source, path)
    assert(("string" == type(new_src)), string.format("%s `transform` did not return string", ctx.source))
    return new_src
  else
    local _ = case_72_
    return source
  end
end
local init_lua_choice = nil
m["sync-plan-compile"] = function(ctx, source_files, force_3f)
  if (nil == force_3f) then
    _G.error("Missing argument force? on fnl/hotpot/context.fnl:194", 2)
  else
  end
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:194", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:194", 2)
  else
  end
  local fnl_source_files
  if force_3f then
    fnl_source_files = source_files.fnl
  else
    fnl_source_files = m["filter-stale-source-files"](source_files)
  end
  local init_lua_index
  do
    local found = nil
    for i, _78_ in ipairs(fnl_source_files) do
      local fnl_rel = _78_["fnl-rel"]
      if found then break end
      if is_init_lua_special_case_3f(ctx, fnl_rel) then
        found = i
      else
        found = nil
      end
    end
    init_lua_index = found
  end
  if init_lua_index then
    if not init_lua_choice then
      local _let_80_ = require("hotpot.ui")
      local ui_select_sync = _let_80_["ui-select-sync"]
      local yes_once = "Yes (ask again later)"
      local no_once = "No (ask again later)"
      local yes_always = "Yes (always for this session)"
      local no_always = "No (always for this session)"
      local prompt = string.format("Will any existing `%s/init.lua` with output from `init.fnl, is this ok?", ctx.path.source)
      local callback
      local function _81_(choice)
        local case_82_, case_83_ = choice
        if (case_82_ == yes_once) then
          init_lua_choice = "yes-once"
          return nil
        elseif (case_82_ == no_once) then
          init_lua_choice = "no-once"
          return nil
        elseif (case_82_ == yes_always) then
          init_lua_choice = "yes-always"
          return nil
        elseif (case_82_ == no_always) then
          init_lua_choice = "no-always"
          return nil
        else
          local _ = case_82_
          init_lua_choice = "no-once"
          return nil
        end
      end
      callback = _81_
      ui_select_sync({yes_once, no_once, yes_always, no_always}, {prompt = prompt}, callback)
    else
    end
    if (init_lua_choice == "yes-once") then
      init_lua_choice = nil
    elseif (init_lua_choice == "yes-always") then
    elseif (init_lua_choice == "no-once") then
      table.remove(fnl_source_files, init_lua_index)
      init_lua_choice = nil
    elseif (init_lua_choice == "no-always") then
      table.remove(fnl_source_files, init_lua_index)
    else
    end
  else
  end
  return fnl_source_files
end
m["sync-compile"] = function(ctx, fnl_files)
  if (nil == fnl_files) then
    _G.error("Missing argument fnl-files on fnl/hotpot/context.fnl:231", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:231", 2)
  else
  end
  local results = {ok = {}, errors = {}}
  for _, _90_ in ipairs(fnl_files) do
    local fnl_abs = _90_["fnl-abs"]
    local fnl_rel = _90_["fnl-rel"]
    local lua_abs = _90_["lua-abs"]
    local fnl_source = read_file(fnl_abs)
    local fnl_source0 = m["apply-transform"](ctx, fnl_source, fnl_rel)
    local case_91_, case_92_ = pcall(M["compile-string"], ctx, fnl_source0, {filename = fnl_rel})
    if ((case_91_ == true) and (nil ~= case_92_)) then
      local lua_source = case_92_
      table.insert(results.ok, {["fnl-abs"] = fnl_abs, ["lua-abs"] = lua_abs, source = lua_source})
      results = results
    elseif ((case_91_ == false) and (nil ~= case_92_)) then
      local err = case_92_
      table.insert(results.errors, {["fnl-abs"] = fnl_abs, ["lua-abs"] = lua_abs, error = err})
      results = results
    else
      results = nil
    end
  end
  return results
end
m["sync-write"] = function(ctx, output_files)
  if (nil == output_files) then
    _G.error("Missing argument output-files on fnl/hotpot/context.fnl:244", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:244", 2)
  else
  end
  for _, _96_ in ipairs(output_files) do
    local lua_abs = _96_["lua-abs"]
    local source = _96_.source
    vim.fn.mkdir(vim.fs.dirname(lua_abs), "p")
    write_file(lua_abs, source)
  end
  return nil
end
m["sync-plan-clean"] = function(ctx, source_files)
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:249", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:249", 2)
  else
  end
  return m["find-orphaned-files"](ctx, source_files)
end
m["sync-clean"] = function(ctx, orphan_files)
  if (nil == orphan_files) then
    _G.error("Missing argument orphan-files on fnl/hotpot/context.fnl:252", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:252", 2)
  else
  end
  for _, orphan in ipairs(orphan_files) do
    vim.uv.fs_unlink(orphan)
  end
  return nil
end
m["sync-plan-confirm"] = function(ctx, source_files, orphan_files)
  if (nil == orphan_files) then
    _G.error("Missing argument orphan-files on fnl/hotpot/context.fnl:256", 2)
  else
  end
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:256", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:256", 2)
  else
  end
  if (5 < #orphan_files) then
    local _let_104_ = require("hotpot.ui")
    local ui_select_sync = _let_104_["ui-select-sync"]
    local confirmations = {["clean?"] = false, ["compile?"] = false}
    local prompt = string.format("\n%s\nFound %d orphaned files, delete all?", table.concat(orphan_files, "\n"), #orphan_files)
    local confirm = "Ok: Compile as normal and remove orphaned files"
    local compile_only = "Safe: Compile as normal but do not remove orphan files"
    local cancel = "Cancel: Do not compile, do not remove orphans"
    local function _105_(choice)
      local case_106_, case_107_ = choice
      if (case_106_ == confirm) then
        confirmations["compile?"] = true
        confirmations["clean?"] = true
        return nil
      elseif (case_106_ == compile_only) then
        confirmations["compile?"] = true
        confirmations["clean?"] = false
        return nil
      elseif (case_106_ == cancel) then
        confirmations["compile?"] = false
        confirmations["clean?"] = false
        return nil
      else
        return nil
      end
    end
    ui_select_sync({confirm, compile_only, cancel}, {prompt = prompt}, _105_)
    return confirmations
  else
    return {["compile?"] = true, ["clean?"] = true}
  end
end
m["make-fennel-path-modifiers"] = function(ctx, fennel)
  if (nil == fennel) then
    _G.error("Missing argument fennel on fnl/hotpot/context.fnl:286", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:286", 2)
  else
  end
  if ("api" == ctx.kind) then
    local function _112_()
      return nil
    end
    local function _113_()
      return nil
    end
    return {["update-fennel-path"] = _112_, ["restore-fennel-path"] = _113_}
  else
    local directory_prefix = ctx.path.source
    local _
    if not directory_prefix then
      _ = error(vim.inspect(ctx))
    else
      _ = nil
    end
    local old_paths = {path = fennel.path, ["macro-path"] = fennel["macro-path"]}
    local new_paths = {path = table.concat({(directory_prefix .. "/fnl/?.fnl"), (directory_prefix .. "/fnl/?/init.fnl"), (directory_prefix .. "/?.fnl"), (directory_prefix .. "/?/init.fnl"), old_paths.path}, ";"), ["macro-path"] = table.concat({(directory_prefix .. "/fnl/?.fnlm"), (directory_prefix .. "/fnl/?/init.fnlm"), (directory_prefix .. "/fnl/?.fnl"), (directory_prefix .. "/fnl/?/init-macros.fnl"), (directory_prefix .. "/fnl/?/init.fnl"), (directory_prefix .. "/?.fnlm"), (directory_prefix .. "/?/init.fnlm"), (directory_prefix .. "/?.fnl"), (directory_prefix .. "/?/init-macros.fnl"), (directory_prefix .. "/?/init.fnl"), old_paths["macro-path"]}, ";")}
    local function _115_()
      fennel.path = new_paths.path
      fennel["macro-path"] = new_paths["macro-path"]
      return nil
    end
    local function _116_()
      fennel.path = old_paths.path
      fennel["macro-path"] = old_paths["macro-path"]
      return nil
    end
    return {["update-fennel-path"] = _115_, ["restore-fennel-path"] = _116_}
  end
end
M.new = function(_3fdirectory)
  if (nil ~= _3fdirectory) then
    local directory = _3fdirectory
    local dot_hotpot_path = vim.fs.normalize(vim.fs.joinpath(directory, ".hotpot.fnl"))
    local dot_hotpot_exists_3f = (nil ~= vim.uv.fs_realpath(dot_hotpot_path))
    local real_directory = vim.uv.fs_realpath(vim.fs.normalize(directory))
    local is_config_root_3f
    if (nil ~= real_directory) then
      local any = real_directory
      is_config_root_3f = (real_directory == NVIM_CONFIG_ROOT)
    elseif (real_directory == nil) then
      is_config_root_3f = (directory == NVIM_CONFIG_ROOT)
    else
      is_config_root_3f = nil
    end
    local case_119_, case_120_ = dot_hotpot_exists_3f, is_config_root_3f
    if ((case_119_ == true) and (case_120_ == true)) then
      return spec__3econtext(load_spec_file(dot_hotpot_path), {root = NVIM_CONFIG_ROOT, kind = "config", source = dot_hotpot_path})
    elseif ((case_119_ == false) and (case_120_ == true)) then
      return spec__3econtext(default_config_spec(), {root = NVIM_CONFIG_ROOT, kind = "config"})
    elseif ((case_119_ == true) and (case_120_ == false)) then
      return spec__3econtext(load_spec_file(dot_hotpot_path), {root = real_directory, kind = "plugin", source = dot_hotpot_path})
    elseif ((case_119_ == false) and (case_120_ == false)) then
      return error(err_msg_unable_to_load(dot_hotpot_path, "does not exist"))
    else
      return nil
    end
  elseif (_3fdirectory == nil) then
    return spec__3econtext(default_api_spec(), {kind = "api"})
  else
    return nil
  end
end
M.nearest = function(starting_path)
  if (nil == starting_path) then
    _G.error("Missing argument starting-path on fnl/hotpot/context.fnl:391", 2)
  else
  end
  local case_124_ = vim.uv.fs_realpath(starting_path)
  if (nil ~= case_124_) then
    local real_path = case_124_
    local case_125_ = vim.fs.relpath(NVIM_CONFIG_ROOT, starting_path)
    if (nil ~= case_125_) then
      local path_inside_config = case_125_
      return NVIM_CONFIG_ROOT
    elseif (case_125_ == nil) then
      return vim.fs.root(starting_path, ".hotpot.fnl")
    else
      return nil
    end
  elseif (case_124_ == nil) then
    return error(string.format("Unable to find nearest context to %s, does not exist", starting_path))
  else
    return nil
  end
end
M["compile-string"] = function(ctx, fnl_source, options)
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/context.fnl:407", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:407", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:407", 2)
  else
  end
  local fennel = require("hotpot.fennel")
  local compiler_options = vim.tbl_extend("force", ctx.compiler, options, {filename = options.filename, ["error-pinpoint"] = false})
  local _let_131_ = m["make-fennel-path-modifiers"](ctx, fennel)
  local update_fennel_path = _let_131_["update-fennel-path"]
  local restore_fennel_path = _let_131_["restore-fennel-path"]
  local _ = update_fennel_path()
  local ok_3f, val = pcall(fennel["compile-string"], fnl_source, compiler_options)
  local _0 = restore_fennel_path()
  local case_132_, case_133_ = ok_3f, val
  if ((case_132_ == true) and (nil ~= case_133_)) then
    local src = case_133_
    return src
  elseif ((case_132_ == false) and (nil ~= case_133_)) then
    local err = case_133_
    return error(err)
  else
    return nil
  end
end
M["eval-string"] = function(ctx, fnl_source, options)
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/context.fnl:425", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:425", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:425", 2)
  else
  end
  local fennel = require("hotpot.fennel")
  local _let_138_ = require("hotpot.util")
  local pack = _let_138_.pack
  local compiler_options = vim.tbl_extend("force", ctx.compiler, options, {filename = options.filename, ["error-pinpoint"] = false})
  local _let_139_ = m["make-fennel-path-modifiers"](ctx, fennel)
  local update_fennel_path = _let_139_["update-fennel-path"]
  local restore_fennel_path = _let_139_["restore-fennel-path"]
  local _ = update_fennel_path()
  local returns = pack(pcall(fennel.eval, fnl_source, compiler_options))
  local _0 = restore_fennel_path()
  local case_140_ = returns[1]
  if (case_140_ == true) then
    return unpack(returns, 2, returns.n)
  elseif (case_140_ == false) then
    return error(returns[2])
  else
    return nil
  end
end
M.sync = function(ctx, _3foptions)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:444", 2)
  else
  end
  local options = (_3foptions or {["force?"] = false})
  local report = {format = {}, summary = {}, success = {}, errors = {}, clean = {}}
  local source_files = m["find-source-files"](ctx)
  local stale_files = m["sync-plan-compile"](ctx, source_files, options["force?"])
  local clean_files = m["sync-plan-clean"](ctx, source_files)
  local _let_143_ = m["sync-compile"](ctx, stale_files)
  local compile_oks = _let_143_.ok
  local compile_errors = _let_143_.errors
  local has_errors_3f = (0 < #compile_errors)
  local atomic_ok_3f = (not has_errors_3f or not ctx["atomic?"])
  local success_messages
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _144_ in ipairs(compile_oks) do
      local fnl_abs = _144_["fnl-abs"]
      local lua_abs = _144_["lua-abs"]
      local val_28_ = {string.format("\226\152\145  %s\n-> %s\n", fnl_abs, lua_abs), "DiagnosticOk"}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    success_messages = tbl_26_
  end
  local error_messages
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _146_ in ipairs(compile_errors) do
      local fnl_abs = _146_["fnl-abs"]
      local lua_abs = _146_["lua-abs"]
      local error = _146_.error
      local val_28_ = {string.format("\226\152\146  %s\n-> %s\n%s\n", fnl_abs, lua_abs, error), "DiagnosticWarn"}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    error_messages = tbl_26_
  end
  local clean_messages
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, lua_abs in ipairs(clean_files) do
      local val_28_ = {string.format("rm %s\n", lua_abs), "DiagnosticInfo"}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    clean_messages = tbl_26_
  end
  local summary_messages
  if has_errors_3f then
    local summary = {{"\nSome files had compilation errors! ", "DiagnosticWarn"}, {"`atomic? = true`, no changes were written to disk!\n", "DiagnosticWarn"}}
    if not ctx["atomic?"] then
      table.remove(summary)
    else
    end
    summary_messages = summary
  else
    summary_messages = {}
  end
  local report0 = {}
  if atomic_ok_3f then
    local _let_151_ = m["sync-plan-confirm"](ctx, stale_files, clean_files)
    local compile_3f = _let_151_["compile?"]
    local clean_3f = _let_151_["clean?"]
    if compile_3f then
      m["sync-write"](ctx, compile_oks)
      if ctx["verbose?"] then
        vim.list_extend(report0, success_messages)
      else
      end
      vim.list_extend(report0, error_messages)
    else
    end
    if clean_3f then
      m["sync-clean"](ctx, clean_files)
      vim.list_extend(report0, clean_messages)
    else
    end
    if compile_3f then
      vim.list_extend(report0, summary_messages)
    else
    end
  else
    vim.list_extend(report0, error_messages)
    vim.list_extend(report0, summary_messages)
  end
  if (0 < #report0) then
    vim.api.nvim_echo(report0, true, {})
  else
  end
  local _158_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, v in ipairs(compile_oks) do
      local val_28_
      do
        v["source"] = nil
        val_28_ = v
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _158_ = tbl_26_
  end
  return {sources = source_files, compiled = _158_, errors = compile_errors, cleaned = clean_files}
end
return M