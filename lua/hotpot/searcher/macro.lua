 local _local_0_ = require("hotpot.fs") local read_file = _local_0_["read-file"]
 local _local_1_ = require("hotpot.searcher.locate") local locate_module = _local_1_["locate-module"]


 local function create_loader(path) local fennel = require("hotpot.fennel")

 local code = read_file(path) local function _0_(...) return fennel.eval(code, {env = "_COMPILER"}, ...) end
 return _0_, path end


 local function searcher(modname)
 local _0_ = locate_module(modname) if (nil ~= _0_) then local fnl_path = _0_
 return create_loader(fnl_path) end end

 return searcher
