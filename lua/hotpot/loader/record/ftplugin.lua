local _local_1_ = string
local fmt = _local_1_["format"]
local REQUIRED_KEYS = {"namespace", "modname", "lua-path", "src-path"}
local function new(modname, src_path, opts)
  _G.assert((nil ~= opts), "Missing argument opts on /home/soup/projects/personal/hotpot/master/fnl/hotpot/loader/record/ftplugin.fnl:4")
  _G.assert((nil ~= src_path), "Missing argument src-path on /home/soup/projects/personal/hotpot/master/fnl/hotpot/loader/record/ftplugin.fnl:4")
  _G.assert((nil ~= modname), "Missing argument modname on /home/soup/projects/personal/hotpot/master/fnl/hotpot/loader/record/ftplugin.fnl:4")
  assert(string.match(src_path, "fnl$"), "ftplugin records path must end in fnl")
  local _let_2_ = require("hotpot.loader")
  local cache_path_for_compiled_artefact = _let_2_["cache-path-for-compiled-artefact"]
  local _let_3_ = require("hotpot.fs")
  local join_path = _let_3_["join-path"]
  local init_3f = (nil ~= string.find(src_path, "init%....$"))
  local true_modname
  local function _4_()
    if init_3f then
      return ".init"
    else
      return ""
    end
  end
  true_modname = (modname .. _4_())
  local filetype = string.sub(true_modname, (#"hotpot-ftplugin." + 1))
  local context_dir_end_position = (#src_path - (1 + #"ftplugin" + 1 + #filetype + 3))
  local context_dir = string.sub(src_path, 1, context_dir_end_position)
  local code_path = string.sub(src_path, (context_dir_end_position + 1))
  local lua_code_path = string.gsub(string.gsub(code_path, "^ftplugin", join_path("lua", "hotpot-ftplugin")), "fnl$", "lua")
  local namespace
  do
    local _5_ = string.match(context_dir, ".+/(.-)/$")
    if (nil ~= _5_) then
      local namespace0 = _5_
      namespace = namespace0
    elseif (_5_ == nil) then
      namespace = string.match(context_dir, "([^/]-)/$")
    else
      namespace = nil
    end
  end
  local namespace0 = ("ftplugin-" .. namespace)
  local lua_path = cache_path_for_compiled_artefact(namespace0, lua_code_path)
  local record = {["src-path"] = src_path, ["lua-path"] = lua_path, ["cache-root-path"] = cache_path_for_compiled_artefact(namespace0), namespace = namespace0, modname = modname}
  local unsafely_3f = (opts["unsafely?"] or false)
  if (true == not unsafely_3f) then
    for _, key in ipairs(REQUIRED_KEYS) do
      assert(record[key], fmt("could not generate required key: %s from src-path: %s", key, src_path))
    end
  else
  end
  return record
end
return {new = new}