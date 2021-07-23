
 local macro_searcher = require("hotpot.searcher.macro") local has_injected_macro_searcher = false


 local function compile_string(string, options)



 local fennel do print("!!! requiring fennel") fennel = require("hotpot.fennel") end if not has_injected_macro_searcher then

 table.insert(fennel["macro-searchers"], macro_searcher) has_injected_macro_searcher = true end


 local function compile()
 return fennel["compile-string"](string, (options or {})) end
 return xpcall(compile, fennel.traceback) end

 return {["compile-string"] = compile_string}
