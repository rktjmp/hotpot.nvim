 local _local_0_ = require("hotpot.fs") local read_file = _local_0_["read-file"]
 local _local_1_ = require("hotpot.searcher.locate") local locate_module = _local_1_["locate-module"]


 local cache = require("hotpot.cache")

 print("macro.included")

 local function create_loader(modname, path)
 print("create-loader", modname, path)
 cache.set(modname, path)
 local fennel do print("!!! requiring fennel") fennel = require("hotpot.fennel") end
 local code = read_file(path) local function _0_(...) return fennel.eval(code, {env = "_COMPILER"}, ...) end
 return _0_, path end


 local function searcher(modname)
 print(modname, "as macro")
 local _0_ = locate_module(modname) if (nil ~= _0_) then local fnl_path = _0_


 return create_loader(modname, fnl_path) end end

 return searcher
