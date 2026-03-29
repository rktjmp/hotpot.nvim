local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local M, m = {}, {}
local function base_spec()
  local _2_
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
    _2_ = tbl_26_
  end
  return {schema = "hotpot/2", ["atomic?"] = true, ignore = {}, transform = nil, compiler = {allowedGlobals = _2_, ["error-pinpoint"] = false}, ["verbose?"] = false}
end
local function is_init_lua_special_case_3f(ctx, fnl_rel)
  if (nil == fnl_rel) then
    _G.error("Missing argument fnl-rel on fnl/hotpot/context.fnl:26", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:26", 2)
  else
  end
  local case_6_, case_7_, case_8_ = ctx.kind, ctx.target, fnl_rel
  if ((case_6_ == "config") and (case_7_ == "cache") and (case_8_ == "init.fnl")) then
    return true
  else
    local _ = case_6_
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
    _G.error("Missing argument path on fnl/hotpot/context.fnl:43", 2)
  else
  end
  assert(vim.uv.fs_stat(path), err_msg_unable_to_load(path, "does not exist"))
  local fennel = R.fennel
  local content
  do
    local case_11_ = vim.secure.read(path)
    if (nil ~= case_11_) then
      local content0 = case_11_
      content = content0
    elseif (case_11_ == nil) then
      content = error(string.format("Unable to continue with untrusted file: %s", path))
    else
      content = nil
    end
  end
  local _let_13_ = m["make-fennel-path-modifiers"]({path = {source = vim.fs.dirname(path)}}, fennel)
  local update_fennel_path = _let_13_["update-fennel-path"]
  local restore_fennel_path = _let_13_["restore-fennel-path"]
  local _ = update_fennel_path()
  local ok_3f, def = pcall(fennel.eval, content)
  local _0 = restore_fennel_path()
  assert(ok_3f, err_msg_unable_to_load(path, def))
  assert(("table" == type(def)), err_msg_unable_to_load(path, "must return table"))
  assert((def.schema == "hotpot/2"), err_msg_unable_to_load(path, "must define schema key as hotpot/2"))
  assert(((def.target == "cache") or (def.target == "colocate")), err_msg_unable_to_load(path, "must define target key as cache or colocate"))
  return def
end
local function user_spec__3econtext(user_spec, meta)
  if (nil == meta) then
    _G.error("Missing argument meta on fnl/hotpot/context.fnl:64", 2)
  else
  end
  if (nil == user_spec) then
    _G.error("Missing argument user-spec on fnl/hotpot/context.fnl:64", 2)
  else
  end
  local source = meta.source
  local kind = meta.kind
  local _let_16_ = R.const
  local HOTPOT_CONFIG_CACHE_ROOT = _let_16_.HOTPOT_CONFIG_CACHE_ROOT
  local path
  if ((_G.type(meta) == "table") and (meta.kind == "api")) then
    path = {}
  elseif ((_G.type(meta) == "table") and (meta.root == nil)) then
    path = error(err_msg_unable_to_load("unknown", "internal error: did not provide root directory to user-spec->context"))
  elseif ((_G.type(meta) == "table") and (meta.kind == "config") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(user_spec) == "table") and (user_spec.target == "cache")) then
      path = {source = root, dest = HOTPOT_CONFIG_CACHE_ROOT}
    elseif ((_G.type(user_spec) == "table") and (user_spec.target == "colocate")) then
      path = {source = root, dest = root}
    else
      path = nil
    end
  elseif ((_G.type(meta) == "table") and (meta.kind == "plugin") and (nil ~= meta.root)) then
    local root = meta.root
    if ((_G.type(user_spec) == "table") and (user_spec.target == "colocate")) then
      path = {source = root, dest = root}
    elseif ((_G.type(user_spec) == "table") and (user_spec.target == "cache")) then
      path = error(err_msg_unable_to_load(root, "non-config directories may only use target: :colocate"))
    else
      path = nil
    end
  else
    local _ = meta
    path = error(err_msg_unable_to_load("unknown", "internal error: spec meta missing kind"))
  end
  local ctx = base_spec()
  local user_compiler_options = user_spec.compiler
  local _
  user_spec.compiler = nil
  _ = nil
  local ctx0 = vim.tbl_extend("force", base_spec(), user_spec, {kind = kind, path = path, source = (source or "in-memory")})
  if user_compiler_options then
    ctx0.compiler = vim.tbl_extend("force", ctx0.compiler, user_compiler_options)
  else
  end
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _0, glob in ipairs(ctx0.ignore) do
      local val_28_ = vim.glob.to_lpeg(glob)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    ctx0.ignore = tbl_26_
  end
  if ctx0.transform then
    assert(("function" == type(ctx0.transform)), string.format("%s `transform` not a function", ctx0.source))
  else
  end
  return ctx0
end
m["find-files"] = function(root, extension_pattern, ignore)
  if (nil == ignore) then
    _G.error("Missing argument ignore on fnl/hotpot/context.fnl:116", 2)
  else
  end
  if (nil == extension_pattern) then
    _G.error("Missing argument extension-pattern on fnl/hotpot/context.fnl:116", 2)
  else
  end
  if (nil == root) then
    _G.error("Missing argument root on fnl/hotpot/context.fnl:116", 2)
  else
  end
  local function _26_(name, dir)
    local path = vim.fs.relpath(root, vim.fs.joinpath(dir, name), {})
    local and_27_ = (".hotpot.fnl" ~= name) and name:match(extension_pattern)
    if and_27_ then
      local ok_3f = true
      for _, rule in ipairs(ignore) do
        if not ok_3f then break end
        ok_3f = not rule:match(path)
      end
      and_27_ = ok_3f
    end
    return and_27_
  end
  return vim.fs.find(_26_, {limit = math.huge, type = "file", path = root})
end
m["find-source-files"] = function(ctx)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:131", 2)
  else
  end
  local _let_29_ = ctx.path
  local source = _let_29_.source
  local dest = _let_29_.dest
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
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:156", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:156", 2)
  else
  end
  local _let_34_ = ctx.path
  local dest = _let_34_.dest
  local ignore = ctx.ignore
  local known_lua_files
  do
    local tbl_21_ = {}
    for _, _35_ in ipairs(source_files.fnl) do
      local lua_abs = _35_["lua-abs"]
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
    _G.error("Missing argument files on fnl/hotpot/context.fnl:168", 2)
  else
  end
  local fnl = files.fnl
  local fnlm = files.fnlm
  local _let_40_ = R.util
  local file_mtime = _let_40_["file-mtime"]
  local fnlm_mtime
  do
    local newest_mtime
    local function _41_()
      return false
    end
    newest_mtime = {sec = 0, nsec = 0, ["after?"] = _41_}
    for _, _42_ in ipairs(fnlm) do
      local fnl_abs = _42_["fnl-abs"]
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
    for _, _44_ in ipairs(fnl) do
      local fnl_abs = _44_["fnl-abs"]
      local lua_abs = _44_["lua-abs"]
      local file = _44_
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
    _G.error("Missing argument path on fnl/hotpot/context.fnl:189", 2)
  else
  end
  if (nil == source) then
    _G.error("Missing argument source on fnl/hotpot/context.fnl:189", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:189", 2)
  else
  end
  local case_50_ = ctx.transform
  if (nil ~= case_50_) then
    local transform = case_50_
    local new_src = transform(source, path)
    assert(("string" == type(new_src)), string.format("%s `transform` did not return string", ctx.source))
    return new_src
  else
    local _ = case_50_
    return source
  end
end
local init_lua_choice = nil
m["sync-plan-compile"] = function(ctx, source_files, force_3f)
  if (nil == force_3f) then
    _G.error("Missing argument force? on fnl/hotpot/context.fnl:198", 2)
  else
  end
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:198", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:198", 2)
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
    for i, _56_ in ipairs(fnl_source_files) do
      local fnl_rel = _56_["fnl-rel"]
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
      local ui_select_sync = R.ui["ui-select-sync"]
      local yes_once = "Yes (ask again later)"
      local no_once = "No (ask again later)"
      local yes_always = "Yes (always for this session)"
      local no_always = "No (always for this session)"
      local prompt = string.format("Will any existing `%s/init.lua` with output from `init.fnl, is this ok?", ctx.path.source)
      local callback
      local function _58_(choice)
        local case_59_, case_60_ = choice
        if (case_59_ == yes_once) then
          init_lua_choice = "yes-once"
          return nil
        elseif (case_59_ == no_once) then
          init_lua_choice = "no-once"
          return nil
        elseif (case_59_ == yes_always) then
          init_lua_choice = "yes-always"
          return nil
        elseif (case_59_ == no_always) then
          init_lua_choice = "no-always"
          return nil
        else
          local _ = case_59_
          init_lua_choice = "no-once"
          return nil
        end
      end
      callback = _58_
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
m["sync-compile"] = function(ctx, fnl_files, _3fextra_options)
  if (nil == fnl_files) then
    _G.error("Missing argument fnl-files on fnl/hotpot/context.fnl:235", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:235", 2)
  else
  end
  for key, _ in pairs(R.fennel["macro-loaded"]) do
    R.fennel["macro-loaded"][key] = nil
  end
  local results = {ok = {}, errors = {}}
  for _, _67_ in ipairs(fnl_files) do
    local fnl_abs = _67_["fnl-abs"]
    local fnl_rel = _67_["fnl-rel"]
    local lua_abs = _67_["lua-abs"]
    local lua_rel = _67_["lua-rel"]
    local fnl_source = R.util["file-read"](fnl_abs)
    local fnl_source0 = m["apply-transform"](ctx, fnl_source, fnl_rel)
    local extra_options = vim.tbl_extend("force", (_3fextra_options or {}), {filename = fnl_rel})
    local time_start = vim.uv.hrtime()
    local ok_3f, result = pcall(M["compile-string"], ctx, fnl_source0, extra_options)
    local time_stop = vim.uv.hrtime()
    local duration_ms = ((time_stop - time_start) / 1000000)
    local case_68_, case_69_ = ok_3f, result
    if ((case_68_ == true) and (nil ~= case_69_)) then
      local lua_source = case_69_
      table.insert(results.ok, {["fnl-abs"] = fnl_abs, ["fnl-rel"] = fnl_rel, ["lua-abs"] = lua_abs, ["lua-rel"] = lua_rel, ["duration-ms"] = duration_ms, source = lua_source})
      results = results
    elseif ((case_68_ == false) and (nil ~= case_69_)) then
      local err = case_69_
      table.insert(results.errors, {["fnl-abs"] = fnl_abs, ["fnl-rel"] = fnl_rel, ["lua-abs"] = lua_abs, ["lua-rel"] = lua_rel, ["duration-ms"] = duration_ms, error = err})
      results = results
    else
      results = nil
    end
  end
  return results
end
m["sync-write"] = function(ctx, output_files)
  if (nil == output_files) then
    _G.error("Missing argument output-files on fnl/hotpot/context.fnl:286", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:286", 2)
  else
  end
  for _, _73_ in ipairs(output_files) do
    local lua_abs = _73_["lua-abs"]
    local source = _73_.source
    vim.fn.mkdir(vim.fs.dirname(lua_abs), "p")
    R.util["file-write"](lua_abs, source)
  end
  return nil
end
m["sync-plan-clean"] = function(ctx, source_files)
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:291", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:291", 2)
  else
  end
  return m["find-orphaned-files"](ctx, source_files)
end
m["sync-clean"] = function(ctx, orphan_files)
  if (nil == orphan_files) then
    _G.error("Missing argument orphan-files on fnl/hotpot/context.fnl:294", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:294", 2)
  else
  end
  for _, orphan in ipairs(orphan_files) do
    vim.uv.fs_unlink(orphan)
  end
  return nil
end
m["sync-plan-confirm"] = function(ctx, source_files, orphan_files)
  if (nil == orphan_files) then
    _G.error("Missing argument orphan-files on fnl/hotpot/context.fnl:298", 2)
  else
  end
  if (nil == source_files) then
    _G.error("Missing argument source-files on fnl/hotpot/context.fnl:298", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:298", 2)
  else
  end
  if (5 < #orphan_files) then
    local ui_select_sync = R.ui["ui-select-sync"]
    local confirmations = {["clean?"] = false, ["compile?"] = false}
    local prompt = string.format("\n%s\nFound %d orphaned files, delete all?", table.concat(orphan_files, "\n"), #orphan_files)
    local confirm = "Ok: Compile as normal and remove orphaned files"
    local compile_only = "Safe: Compile as normal but do not remove orphan files"
    local cancel = "Cancel: Do not compile, do not remove orphans"
    local function _81_(choice)
      local case_82_, case_83_ = choice
      if (case_82_ == confirm) then
        confirmations["compile?"] = true
        confirmations["clean?"] = true
        return nil
      elseif (case_82_ == compile_only) then
        confirmations["compile?"] = true
        confirmations["clean?"] = false
        return nil
      elseif (case_82_ == cancel) then
        confirmations["compile?"] = false
        confirmations["clean?"] = false
        return nil
      else
        return nil
      end
    end
    ui_select_sync({confirm, compile_only, cancel}, {prompt = prompt}, _81_)
    return confirmations
  else
    return {["compile?"] = true, ["clean?"] = true}
  end
end
m["make-fennel-path-modifiers"] = function(ctx, fennel)
  if (nil == fennel) then
    _G.error("Missing argument fennel on fnl/hotpot/context.fnl:328", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:328", 2)
  else
  end
  if ("api" == ctx.kind) then
    local function _88_()
      return nil
    end
    local function _89_()
      return nil
    end
    return {["update-fennel-path"] = _88_, ["restore-fennel-path"] = _89_}
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
    local function _91_()
      fennel.path = new_paths.path
      fennel["macro-path"] = new_paths["macro-path"]
      return nil
    end
    local function _92_()
      fennel.path = old_paths.path
      fennel["macro-path"] = old_paths["macro-path"]
      return nil
    end
    return {["update-fennel-path"] = _91_, ["restore-fennel-path"] = _92_}
  end
end
M.new = function(_3fdirectory)
  if (nil ~= _3fdirectory) then
    local directory = _3fdirectory
    local _let_94_ = R.const
    local NVIM_CONFIG_ROOT = _let_94_.NVIM_CONFIG_ROOT
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
    local case_96_, case_97_ = dot_hotpot_exists_3f, is_config_root_3f
    if ((case_96_ == true) and (case_97_ == true)) then
      return user_spec__3econtext(load_spec_file(dot_hotpot_path), {root = NVIM_CONFIG_ROOT, kind = "config", source = dot_hotpot_path})
    elseif ((case_96_ == false) and (case_97_ == true)) then
      return user_spec__3econtext(default_config_spec(), {root = NVIM_CONFIG_ROOT, kind = "config"})
    elseif ((case_96_ == true) and (case_97_ == false)) then
      return user_spec__3econtext(load_spec_file(dot_hotpot_path), {root = real_directory, kind = "plugin", source = dot_hotpot_path})
    elseif ((case_96_ == false) and (case_97_ == false)) then
      return error(err_msg_unable_to_load(dot_hotpot_path, "does not exist"))
    else
      return nil
    end
  elseif (_3fdirectory == nil) then
    return user_spec__3econtext(default_api_spec(), {kind = "api"})
  else
    return nil
  end
end
M.nearest = function(starting_path)
  if (nil == starting_path) then
    _G.error("Missing argument starting-path on fnl/hotpot/context.fnl:434", 2)
  else
  end
  local case_101_ = vim.uv.fs_realpath(starting_path)
  if (nil ~= case_101_) then
    local real_path = case_101_
    local case_102_ = vim.fs.relpath(R.const.NVIM_CONFIG_ROOT, starting_path)
    if (nil ~= case_102_) then
      local path_inside_config = case_102_
      return R.const.NVIM_CONFIG_ROOT
    elseif (case_102_ == nil) then
      local case_103_ = vim.fs.root(starting_path, ".hotpot.fnl")
      if (case_103_ == nil) then
        return nil, string.format("Unable to find nearest context to %s, no .hotpot.fnl in tree", starting_path)
      elseif (nil ~= case_103_) then
        local root = case_103_
        return root
      else
        return nil
      end
    else
      return nil
    end
  elseif (case_101_ == nil) then
    return nil, string.format("Unable to find nearest context to %s, does not exist", starting_path)
  else
    return nil
  end
end
M["compile-string"] = function(ctx, fnl_source, options)
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/context.fnl:454", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:454", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:454", 2)
  else
  end
  assert(options.filename, "tried to compile without filename")
  local fennel = R.fennel
  local compiler_options = vim.tbl_extend("force", ctx.compiler, options, {filename = options.filename, ["error-pinpoint"] = false})
  local _let_110_ = m["make-fennel-path-modifiers"](ctx, fennel)
  local update_fennel_path = _let_110_["update-fennel-path"]
  local restore_fennel_path = _let_110_["restore-fennel-path"]
  local _ = update_fennel_path()
  local ok_3f, val = pcall(fennel["compile-string"], fnl_source, compiler_options)
  local _0 = restore_fennel_path()
  local case_111_, case_112_ = ok_3f, val
  if ((case_111_ == true) and (nil ~= case_112_)) then
    local src = case_112_
    return src
  elseif ((case_111_ == false) and (nil ~= case_112_)) then
    local err = case_112_
    return error(err)
  else
    return nil
  end
end
M["eval-string"] = function(ctx, fnl_source, options)
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/context.fnl:473", 2)
  else
  end
  if (nil == fnl_source) then
    _G.error("Missing argument fnl-source on fnl/hotpot/context.fnl:473", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:473", 2)
  else
  end
  local fennel = R.fennel
  local _let_117_ = R.util
  local pack = _let_117_.pack
  local compiler_options = vim.tbl_extend("force", ctx.compiler, options, {filename = options.filename, ["error-pinpoint"] = false})
  local _let_118_ = m["make-fennel-path-modifiers"](ctx, fennel)
  local update_fennel_path = _let_118_["update-fennel-path"]
  local restore_fennel_path = _let_118_["restore-fennel-path"]
  local _ = update_fennel_path()
  local returns = pack(pcall(fennel.eval, fnl_source, compiler_options))
  local _0 = restore_fennel_path()
  local case_119_ = returns[1]
  if (case_119_ == true) then
    return unpack(returns, 2, returns.n)
  elseif (case_119_ == false) then
    return error(returns[2])
  else
    return nil
  end
end
M.sync = function(ctx, _3foptions)
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/context.fnl:491", 2)
  else
  end
  local function option_if_set(key)
    local case_122_
    do
      local t_123_ = _3foptions
      if (nil ~= t_123_) then
        t_123_ = t_123_[key]
      else
      end
      case_122_ = t_123_
    end
    if (case_122_ == nil) then
      return ctx[key]
    elseif (nil ~= case_122_) then
      local val = case_122_
      return val
    else
      return nil
    end
  end
  local force_3f = (option_if_set("force?") or false)
  local atomic_3f = option_if_set("atomic?")
  local verbose_3f = option_if_set("verbose?")
  local extra_compiler_options
  local _127_
  do
    local t_126_ = _3foptions
    if (nil ~= t_126_) then
      t_126_ = t_126_.compiler
    else
    end
    _127_ = t_126_
  end
  extra_compiler_options = (_127_ or {})
  local report = {format = {}, summary = {}, success = {}, errors = {}, clean = {}}
  local source_files = m["find-source-files"](ctx)
  local stale_files = m["sync-plan-compile"](ctx, source_files, force_3f)
  local clean_files = m["sync-plan-clean"](ctx, source_files)
  local time_start = vim.uv.hrtime()
  local _let_129_ = m["sync-compile"](ctx, stale_files, extra_compiler_options)
  local compile_oks = _let_129_.ok
  local compile_errors = _let_129_.errors
  local time_stop = vim.uv.hrtime()
  local duration_ms = ((time_stop - time_start) / 1000000)
  local has_errors_3f = (0 < #compile_errors)
  local atomic_ok_3f = (not has_errors_3f or not atomic_3f)
  local success_messages
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, _130_ in ipairs(compile_oks) do
      local fnl_abs = _130_["fnl-abs"]
      local lua_abs = _130_["lua-abs"]
      local duration_ms0 = _130_["duration-ms"]
      local val_28_ = {string.format("\226\152\145  %s (%.2fms)\n-> %s\n", fnl_abs, duration_ms0, lua_abs), "DiagnosticOk"}
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
    for _, _132_ in ipairs(compile_errors) do
      local fnl_abs = _132_["fnl-abs"]
      local lua_abs = _132_["lua-abs"]
      local error = _132_.error
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
  do
    local summary = {}
    if verbose_3f then
      table.insert(summary, {string.format("\nDuration: %.2fms", duration_ms), "DiagnosticInfo"})
    else
    end
    if has_errors_3f then
      table.insert(summary, {"\nSome files had compilation errors! ", "DiagnosticWarn"})
      if atomic_3f then
        table.insert(summary, {"`atomic? = true`, no changes were written to disk!\n", "DiagnosticWarn"})
      else
      end
    else
    end
    summary_messages = summary
  end
  local report0 = {}
  if atomic_ok_3f then
    local _let_138_ = m["sync-plan-confirm"](ctx, stale_files, clean_files)
    local compile_3f = _let_138_["compile?"]
    local clean_3f = _let_138_["clean?"]
    if compile_3f then
      m["sync-write"](ctx, compile_oks)
      if verbose_3f then
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
  local _145_
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
    _145_ = tbl_26_
  end
  return {sources = source_files, compiled = _145_, errors = compile_errors, cleaned = clean_files}
end
return M