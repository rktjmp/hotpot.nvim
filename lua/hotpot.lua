assert((1 == vim.fn.has("nvim-0.9.1")), "Hotpot requires neovim 0.9.1+")
local _let_1_ = require("hotpot.loader")
local searcher = _let_1_["searcher"]
local compiled_cache_path = _let_1_["compiled-cache-path"]
local _let_2_ = require("hotpot.fs")
local join_path = _let_2_["join-path"]
local make_path = _let_2_["make-path"]
local _let_3_ = require("hotpot.common")
local set_lazy_proxy = _let_3_["set-lazy-proxy"]
local neovim_runtime = require("hotpot.neovim.runtime")
local _let_4_ = require("hotpot.api.make")
local automake = _let_4_["auto"]
make_path(compiled_cache_path)
vim.opt.runtimepath:prepend(join_path(compiled_cache_path, "*"))
table.insert(package.loaders, 2, searcher)
neovim_runtime.enable()
automake.enable()
local function setup(options)
  local runtime = require("hotpot.runtime")
  local config = runtime["set-user-config"](options)
  if config.provide_require_fennel then
    local function _5_()
      return require("hotpot.fennel")
    end
    package.preload["fennel"] = _5_
  else
  end
  if config.enable_hotpot_diagnostics then
    local diagnostics = require("hotpot.api.diagnostics")
    return diagnostics.enable()
  else
    return nil
  end
end
return set_lazy_proxy({setup = setup}, {api = "hotpot.api", runtime = "hotpot.runtime"})