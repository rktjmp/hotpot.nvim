local _local_1_ = require("hotpot.common")
local set_lazy_proxy = _local_1_["set-lazy-proxy"]
local lookup = {eval = "hotpot.api.eval", compile = "hotpot.api.compile", cache = "hotpot.api.cache", make = "hotpot.api.make", fennel = "hotpot.api.fennel"}
return set_lazy_proxy({}, lookup)