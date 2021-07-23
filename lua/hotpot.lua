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
  -- fennel["macro-path"] = plugin_fnl_dir .. "/?.fnl;" .. fennel["macro-path"]

  -- insert searcher at head so it skips this file in favour of the fnl file
  table.insert(package.loaders, 1, fennel.searcher)
  print(vim.inspect(package.loaders))
  local hotpot = require("hotpot2")
  -- remove fennel searcher since we have our own
  table.remove(package.loaders, 1)
  print(vim.inspect(package.loaders))
  print("required hotpot from fennel")

  for name, _ in pairs(package.loaded) do
    if string.match(name, "^hotpot") then
      package.loaded[name] = nil
    end
  end
  package.loaded["hotpot2"] = nil

  -- wrap setup() so we require ourselves
  local _setup = hotpot.setup
  hotpot.setup = function()
    print("hijacked setup")
    local val = _setup()
    package.loaded["hotpot"] = nil
    require("hotpot2")
    return val
  end

  return hotpot
end
