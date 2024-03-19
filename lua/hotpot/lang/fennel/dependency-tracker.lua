local function new(fnl_path, required_from_modname)
  local function plug_require_macros(ast, scope)
    do
      local fennel = require("hotpot.fennel")
      local _let_1_ = ast
      local second = _let_1_[2]
      local macro_modname = fennel.eval(fennel.view(second), {["module-name"] = required_from_modname}, required_from_modname, fnl_path)
      local dep_map = require("hotpot.dependency-map")
      assert(macro_modname, ("congratulations, you're doing something weird, " .. "probably with recursive relative macro requires, " .. "please open a bug with an example of your setup"))
      dep_map["fnl-path-depends-on-macro-module"](fnl_path, macro_modname)
    end
    return nil
  end
  return {versions = {"1.1.0", "1.1.1", "1.2.0", "1.2.1", "1.3.0", "1.3.1", "1.4.0", "1.4.1", "1.4.2"}, name = ("hotpot-macro-dep-tracking-for-" .. required_from_modname), ["require-macros"] = plug_require_macros}
end
return {new = new}