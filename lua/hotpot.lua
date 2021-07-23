local plugin_dir = vim.loop.fs_realpath(vim.api.nvim_get_runtime_file("lua/hotpot.lua", false)[1])
plugin_dir = string.gsub(plugin_dir, "/lua/hotpot.lua$", "")

local plugin_fnl_dir = plugin_dir .. "/fnl"
local cache_dir = vim.fn.stdpath("cache") .. "/hotpot/"
local canary = cache_dir .. plugin_fnl_dir .. "/hotpot2.lua"
print("canary file: " .. canary)

-- if the canary exists, we already have a hotspot runtime waiting, we
-- just have to load it, then it will handle any future requests
if vim.loop.fs_access(canary, "R") then
  -- inject our cache dir into the start of lua's module search path
  -- then require ourselves, then clean up as normally we will use vims
  -- runtimepath
  local save = package.path
  package.path = cache_dir .. plugin_fnl_dir .. "/?.lua;" .. package.path
  -- we can now just load hotpot like normal
  local hotpot = require("hotpot2")
  -- restore path because the hotpot searcher will takeover now
  package.path = save
  -- and we're done
  return hotpot
else
  -- no cache exists, so we have to build one. We can do this by loading hotpot
  -- directly via fennel, then asking hotpot to find itself, which will
  -- generate the cache.
  local fennel = require("hotpot.fennel")
  print(fennel.version)
  fennel.path = plugin_fnl_dir .. "/?.fnl;" .. fennel.path
--  fennel.dofile(plugin_fnl_dir .. "/hotpot2.fnl", {
--    compilerEnv = {},
--    env = {
--      require = function(mod)
--        print(mod)
--      end,
--      vim = vim
--    }
--  })

  -- insert searcher at head so it skips this file in favour of the fnl file
  table.insert(package.loaders, fennel.makeSearcher({compilerEnv = {}})) -- inserts at the end
  print(vim.inspect(package.loaders))
  local hotpot = require("hotpot2")
  hotpot.setup()
  -- remove fennel searcher since we have our own,
  -- which has been inserted at the front
  table.remove(package.loaders) -- removes from end

  -- transplant hotpot to _hotpot, so we can require("hotpot") to
  -- properly compile ourselves out
  for name, _ in pairs(package.loaded) do
    if string.match(name, "^hotpot") then
      package.loaded["_" .. name] = package.loaded[name]
      package.loaded[name] = nil
      print("package.loaded[" .. name .. "] => _" .. name)
    elseif  string.match(name, "^fennel") then
      print("dropping package: " .. name)
      package.loaded[name] = nil
    end
  end

  -- don't run setup
  print("** start require(hotpot2)")
  require("hotpot2")
  print("** end require(hotpot2)")

  return hotpot
end
--
--  print(vim.inspect(package.loaders))
--  print("required hotpot from fennel")
--
--  package.loaded["hotpot2"] = nil
--  collectgarbage()
--
--  print("### cleared package.loaded")
--
--  -- wrap setup() so we require ourselves again
--  -- so we can start from a clean state
--  local _setup = hotpot.setup
--  hotpot.setup = function()
--    print("hijacked setup")
--    local val = _setup()
--    package.loaded["hotpot"] = nil
--    require("hotpot2")
--    return val
--  end
--
--  return hotpot

