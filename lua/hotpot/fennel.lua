local fennel = require("hotpot.vendor.fennel")
local path = fennel.path
local macro_path = fennel["macro-path"]
fennel.path = table.concat({"./fnl/?.fnl", "./fnl/?/init.fnl", fennel.path}, ";")
fennel["macro-path"] = table.concat({"./fnl/?.fnlm", "./fnl/?/init.fnlm", "./fnl/?.fnl", "./fnl/?/init-macros.fnl", "./fnl/?/init.fnl", fennel["macro-path"]}, ";")
return fennel