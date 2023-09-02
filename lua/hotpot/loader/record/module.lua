local _local_1_ = string
local fmt = _local_1_["format"]
local REQUIRED_KEYS = {"sigil-path", "lua-cache-path", "lua-colocation-path", "namespace", "modname", "lua-path", "src-path"}
local function new(modname, src_path, _2_)
  local _arg_3_ = _2_
  local prefix = _arg_3_["prefix"]
  local extension = _arg_3_["extension"]
  local opts = _arg_3_
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= extension), "Missing argument extension on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= prefix), "Missing argument prefix on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record/module.fnl:9")
  local _let_4_ = require("hotpot.loader.sigil")
  local SIGIL_FILE = _let_4_["SIGIL_FILE"]
  local _let_5_ = require("hotpot.loader")
  local cache_path_for_compiled_artefact = _let_5_["cache-path-for-compiled-artefact"]
  local src_path0 = vim.fs.normalize(src_path)
  local prefix_length = #prefix
  local extension_length = #extension
  local init_3f = (nil ~= string.find(src_path0, "init%....$"))
  local true_modname
  local function _6_()
    if init_3f then
      return ".init"
    else
      return ""
    end
  end
  true_modname = (modname .. _6_())
  local context_dir_end_position = (#src_path0 - (prefix_length + 1 + #true_modname + 1 + extension_length))
  local context_dir = string.sub(src_path0, 1, context_dir_end_position)
  local code_path = string.sub(src_path0, (context_dir_end_position + 1))
  local namespace
  do
    local _7_ = string.match(context_dir, ".+/(.-)/$")
    if (nil ~= _7_) then
      local namespace0 = _7_
      namespace = namespace0
    elseif (_7_ == nil) then
      namespace = string.match(context_dir, "([^/]-)/$")
    else
      namespace = nil
    end
  end
  local fnl_code_path = (prefix .. string.sub(code_path, (prefix_length + 1), (-1 * (1 + extension_length))) .. extension)
  local lua_code_path = ("lua" .. string.sub(code_path, (prefix_length + 1), (-1 * (1 + extension_length))) .. "lua")
  local src_path1 = (context_dir .. fnl_code_path)
  local lua_path = (context_dir .. lua_code_path)
  local lua_cache_path = cache_path_for_compiled_artefact(namespace, lua_code_path)
  local lua_colocation_path = (context_dir .. lua_code_path)
  local sigil_path = (context_dir .. SIGIL_FILE)
  local record = {["sigil-path"] = sigil_path, ["src-path"] = src_path1, ["lua-path"] = lua_cache_path, ["lua-cache-path"] = lua_cache_path, ["lua-colocation-path"] = lua_colocation_path, ["colocation-root-path"] = context_dir, ["cache-root-path"] = cache_path_for_compiled_artefact(namespace), namespace = namespace, modname = modname}
  local unsafely_3f = (opts["unsafely?"] or false)
  if (true == not unsafely_3f) then
    for _, key in ipairs(REQUIRED_KEYS) do
      assert(record[key], fmt("could not generate required key: %s from src-path: %s", key, src_path1))
    end
  else
  end
  return record
end
local function retarget(record, target)
  if (target == "colocate") then
    record["lua-path"] = record["lua-colocation-path"]
    return record
  elseif (target == "cache") then
    record["lua-path"] = record["lua-cache-path"]
    return record
  elseif true then
    local _ = target
    return error("target must be colocate or cache")
  else
    return nil
  end
end
local function _11_(_241)
  return retarget(_241, "cache")
end
local function _12_(_241)
  return retarget(_241, "colocate")
end
return {new = new, ["retarget-cache"] = _11_, ["retarget-colocation"] = _12_}