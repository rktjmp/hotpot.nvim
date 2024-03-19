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
    local tbl_19_auto = {}
    local i_20_auto = 0
    for _, mod in ipairs(deps) do
      local val_21_auto = macro_mods_paths[mod]
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    return tbl_19_auto
  else
    return nil
  end
end
local function new(fnl_path, required_from_modname)
  local function plug_require_macros(ast, scope)
    do
      local fennel = require("hotpot.fennel")
      local _let_5_ = ast
      local second = _let_5_[2]
      local macro_modname = fennel.eval(fennel.view(second), {["module-name"] = required_from_modname}, required_from_modname, fnl_path)
      assert(macro_modname, ("congratulations, you're doing something weird, " .. "probably with recursive relative macro requires, " .. "please open a bug with an example of your setup"))
      fnl_path_depends_on_macro_module(fnl_path, macro_modname)
    end
    return nil
  end
  return {versions = {"1.1.0", "1.1.1", "1.2.0", "1.2.1", "1.3.0", "1.3.1", "1.4.0", "1.4.1", "1.4.2"}, name = ("hotpot-macro-dep-tracking-for-" .. required_from_modname), ["require-macros"] = plug_require_macros}
end
return {["deps-for-fnl-path"] = deps_for_fnl_path, ["set-macro-modname-path"] = set_macro_modname_path, new = new}