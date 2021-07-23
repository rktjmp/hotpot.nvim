






 local uv = vim.loop








 local plugin_dir = string.gsub(uv.fs_realpath((vim.api.nvim_get_runtime_file("lua/hotpot.lua", false))[1]), "/lua/hotpot.lua$", "")

 local fnl_dir = (plugin_dir .. "/fnl")


 local cache_dir = (vim.fn.stdpath("cache") .. "/hotpot/")



 local canary = (cache_dir .. fnl_dir .. "/hotpot.hotterpot.lua")




 if vim.loop.fs_access(canary, "R") then



 local old_package_path = package.path

 package.path = (cache_dir .. fnl_dir .. "/?.lua;" .. package.path)
 local hotpot = require("hotpot.hotterpot")
 package.path = old_package_path
 return hotpot else




 local fennel = require("hotpot.fennel")


 local saved_fennel_path = fennel.path
 fennel.path = (fnl_dir .. "/?.fnl;" .. fennel.path)







 table.insert(package.loaders, fennel.makeSearcher({compilerEnv = {}}))


 local hotpot = require("hotpot.hotterpot")
 hotpot.setup()




 table.remove(package.loaders)
 for name, _ in pairs(package.loaded) do
 if string.match(name, "^hotpot") then


 package.loaded[("_" .. name)] = package.loaded[name]
 package.loaded[name] = nil elseif string.match(name, "^fennel") then


 package.loaded[name] = nil end end
 fennel.path = saved_fennel_path





 require("hotpot.hotterpot")












 return hotpot end
