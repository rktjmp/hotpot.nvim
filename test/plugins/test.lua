plugin = {
  name = "table-plugin",
  call = function (ast, scope)
    if ast[1][1] == "+" then
      table.insert(ast, 1)
    end
    return nil
  end,
  versions = {"1.2.1"}
}

require("hotpot").setup({
  compiler = {
    modules = {
      plugins = {
        "plugin",
        plugin,
      }
    }
  }
})

-- trigger a compile to run the plugins
local value = require("force_compile")
if value == 4 then
  os.exit(0)
else
  os.exit(1)
end
