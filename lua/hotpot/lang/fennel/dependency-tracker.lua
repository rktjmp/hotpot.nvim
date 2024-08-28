local macro_mods_paths = {}
local fnl_file_macro_mods = {}
local function set_macro_modname_path(mod, path)
  local existing_path = macro_mods_paths[mod]
  local fmt = string.format
  assert(((existing_path == path) or (existing_path == nil)), fmt("already have mod-path for %s, current: %s, new: %s", mod, existing_path, path))
  macro_mods_paths[mod] = path
  return nil
end
local function fnl_path_depends_on_macro_module(fnl_path, macro_module)
  local list = (fnl_file_macro_mods[fnl_path] or {})
  if macro_module then
    table.insert(list, macro_module)
    fnl_file_macro_mods[fnl_path] = list
    return nil
  else
    return error(("tried to insert nil macro dependencies for " .. fnl_path .. ", please report this issue"))
  end
end
local function deps_for_fnl_path(fnl_path)
  local _2_ = fnl_file_macro_mods[fnl_path]
  if (nil ~= _2_) then
    local deps = _2_
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, mod in ipairs(deps) do
      local val_23_auto = macro_mods_paths[mod]
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    return tbl_21_auto
  else
    return nil
  end
end
local function new(fnl_path, required_from_modname)
  local function plug_require_macros(ast, scope)
    do
      local fennel = require("hotpot.fennel")
      local second = ast[2]
      local macro_modname = fennel.eval(fennel.view(second), {["module-name"] = required_from_modname}, required_from_modname, fnl_path)
      assert(macro_modname, ("congratulations, you're doing something weird, " .. "probably with recursive relative macro requires, " .. "please open a bug with an example of your setup"))
      fnl_path_depends_on_macro_module(fnl_path, macro_modname)
    end
    return nil
  end
  return {versions = {"1.1.0", "1.1.1", "1.2.0", "1.2.1", "1.3.0", "1.3.1", "1.4.0", "1.4.1", "1.4.2", "1.5.0", "1.5.1"}, name = ("hotpot-macro-dep-tracking-for-" .. required_from_modname), ["require-macros"] = plug_require_macros}
end
return {["deps-for-fnl-path"] = deps_for_fnl_path, ["set-macro-modname-path"] = set_macro_modname_path, new = new}