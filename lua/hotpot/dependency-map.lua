local macro_mods_paths = {}
local fnl_file_macro_mods = {}
local function set_macro_modname_path(mod, path)
  local existing_path = macro_mods_paths[mod]
  local fmt = string.format
  assert(((existing_path == path) or (existing_path == nil)), fmt("already have mod-path for %s, current: %s, new: %s", mod, existing_path, path))
  do end (macro_mods_paths)[mod] = path
  return nil
end
local function fnl_path_depends_on_macro_module(fnl_path, macro_module)
  local list = (fnl_file_macro_mods[fnl_path] or {})
  if macro_module then
    table.insert(list, macro_module)
    do end (fnl_file_macro_mods)[fnl_path] = list
    return nil
  else
    return error(("tried to insert nil macro dependencies for " .. fnl_path .. ", please report this issue"))
  end
end
local function deps_for_fnl_path(fnl_path)
  local _2_ = fnl_file_macro_mods[fnl_path]
  if (nil ~= _2_) then
    local deps = _2_
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for _, mod in ipairs(deps) do
      local val_19_auto = macro_mods_paths[mod]
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    return tbl_17_auto
  else
    return nil
  end
end
return {["fnl-path-depends-on-macro-module"] = fnl_path_depends_on_macro_module, ["deps-for-fnl-path"] = deps_for_fnl_path, ["set-macro-modname-path"] = set_macro_modname_path}