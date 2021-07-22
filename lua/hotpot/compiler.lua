 local has_injected_macro_searcher = false


 local function compile_string(string, options) local fennel = require("hotpot.fennel") if not has_injected_macro_searcher then





 table.insert(fennel["macro-searchers"], require("hotpot.searcher.macro")) has_injected_macro_searcher = true end


 local function compile()
 return fennel["compile-string"](string, (options or {})) end
 return xpcall(compile, fennel.traceback) end

 return {["compile-string"] = compile_string}
