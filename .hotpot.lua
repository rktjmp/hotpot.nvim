local allowed_globals = {}
for key, _ in pairs(_G) do
  table.insert(allowed_globals, key)
end

return {
  compiler = {
    modules = {
      allowedGlobals = allowed_globals
    }
  },
  build = {
    {verbose = true, atomic = true},
    {"fnl/**/*macro*.fnl", false},
    {"fnl/**/*.fnl", true},
    {"test-init.fnl", true},
    {"new-tests/**/*macro*.fnl", false},
    {"new-tests/**/utils.fnl", false},
    {"new-tests/**/*.fnl", true}
  },
  clean = {
    {"lua/hotpot/fennel.lua", false},
    {"lua/**/*.lua", true}
  }
}
