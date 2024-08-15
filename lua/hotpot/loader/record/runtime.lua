local _local_1_ = string
local fmt = _local_1_["format"]
local REQUIRED_KEYS = {"namespace", "modname", "lua-path", "src-path"}
local function new(modname_suffix, src_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/loader/record/runtime.fnl:6")
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record/runtime.fnl:6")
  _G.assert((nil ~= modname_suffix), "Missing argument modname-suffix on fnl/hotpot/loader/record/runtime.fnl:6")
  assert(string.match(src_path, "fnl$"), "ftplugin records path must end in fnl")
  local _let_2_ = require("hotpot.loader")
  local cache_path_for_compiled_artefact = _let_2_["cache-path-for-compiled-artefact"]
  local _let_3_ = require("hotpot.fs")
  local join_path = _let_3_["join-path"]
  local _let_4_ = opts
  local runtime_type = _let_4_["runtime-type"]
  local _ = assert(runtime_type, "runtime record requires opts.runtime-type such as ftplugin, plugin etc")
  local src_path0 = vim.fs.normalize(src_path)
  local ext = src_path0:match(".+%.(.-)$")
  local init_3f = (nil ~= string.find(src_path0, "init%....$"))
  local true_modname
  local function _5_()
    if init_3f then
      return ".init"
    else
      return ""
    end
  end
  true_modname = (modname_suffix .. _5_())
  local runtime_mod_prefix = fmt("hotpot-runtime-%s", runtime_type)
  local modname = fmt("%s.%s", runtime_mod_prefix, modname_suffix)
  local unescaped_context_pattern = fmt("(%s/%s%%.%s)$", runtime_type, modname_suffix, ext)
  local context_pattern = string.gsub(unescaped_context_pattern, "[%-]", "%%%1")
  local path_inside_context_dir = string.match(src_path0, context_pattern)
  local path_to_context_dir = string.sub(src_path0, 1, (-1 * (#path_inside_context_dir + 1)))
  local lua_code_path = string.gsub(string.gsub(path_inside_context_dir, ("^" .. vim.pesc(runtime_type)), join_path("lua", runtime_mod_prefix)), "fnl$", "lua")
  local namespace
  do
    local _6_ = string.match(path_to_context_dir, ".+/(.-)/$")
    if (nil ~= _6_) then
      local namespace0 = _6_
      namespace = namespace0
    elseif (_6_ == nil) then
      namespace = string.match(path_to_context_dir, "([^/]-)/$")
    else
      namespace = nil
    end
  end
  local namespace0 = ("hotpot-runtime-" .. namespace)
  local lua_path = cache_path_for_compiled_artefact(namespace0, lua_code_path)
  local record = {["src-path"] = src_path0, ["lua-path"] = lua_path, ["cache-root-path"] = cache_path_for_compiled_artefact(namespace0), namespace = namespace0, modname = modname}
  local unsafely_3f = (opts["unsafely?"] or false)
  if (true == not unsafely_3f) then
    for _0, key in ipairs(REQUIRED_KEYS) do
      assert(record[key], fmt("could not generate required key: %s from src-path: %s", key, src_path0))
    end
  else
  end
  return record
end
return {new = new}