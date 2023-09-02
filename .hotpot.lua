return {
  build = {
    {verbose = true, atomic = true},
    {"fnl/**/*macro*.fnl", false},
    {"fnl/**/*.fnl", true}
  },
  clean = {
    {"lua/hotpot/fennel.lua", false},
    {"lua/**/*.lua", true}
  }
}
