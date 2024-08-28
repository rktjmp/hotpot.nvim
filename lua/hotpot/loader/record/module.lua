local fmt = string["format"]
local REQUIRED_KEYS = {"sigil-path", "lua-cache-path", "lua-colocation-path", "namespace", "modname", "lua-path", "src-path"}
local function new(modname, src_path, _1_)
  local prefix = _1_["prefix"]
  local extension = _1_["extension"]
  local opts = _1_
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= extension), "Missing argument extension on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= prefix), "Missing argument prefix on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= src_path), "Missing argument src-path on fnl/hotpot/loader/record/module.fnl:9")
  _G.assert((nil ~= modname), "Missing argument modname on fnl/hotpot/loader/record/module.fnl:9")
  local _let_2_ = require("hotpot.loader.sigil")
  local SIGIL_FILE = _let_2_["SIGIL_FILE"]
  local _let_3_ = require("hotpot.loader")
  local cache_path_for_compiled_artefact = _let_3_["cache-path-for-compiled-artefact"]
  local src_path0 = vim.fs.normalize(src_path)
  local context_dir, code_path = nil, nil
  do
    local slashed_modname = vim.pesc(string.gsub(modname, "%.", "/"))
    local pattern = fmt("(.+/)(%s/%s(.*)%%.%s)", prefix, slashed_modname, extension)
    local _4_, _5_, _6_ = string.gmatch(src_path0, pattern)()
    if ((nil ~= _4_) and (nil ~= _5_) and (_6_ == "")) then
      local context_dir0 = _4_
      local code_dir = _5_
      context_dir, code_path = context_dir0, code_dir, modname
    elseif ((nil ~= _4_) and (nil ~= _5_) and (_6_ == "/init")) then
      local context_dir0 = _4_
      local code_dir = _5_
      context_dir, code_path = context_dir0, code_dir, (modname .. ".init")
    else
      local _ = _4_
      context_dir, code_path = error(fmt("Hotpot could not extract context-dir and code-path from %s", src_path0))
    end
  end
  local namespace
  do
    local _8_ = string.match(context_dir, ".+/(.-)/$")
    if (nil ~= _8_) then
      local namespace0 = _8_
      namespace = namespace0
    elseif (_8_ == nil) then
      namespace = string.match(context_dir, "([^/]-)/$")
    else
      namespace = nil
    end
  end
  local sigil_path = (context_dir .. SIGIL_FILE)
  local lua_code_path
  do
    local pattern = fmt("(%s)(/.+%%.)(%s)$", prefix, extension)
    lua_code_path = string.gsub(code_path, pattern, "lua%2lua")
  end
  local lua_cache_path = cache_path_for_compiled_artefact(namespace, lua_code_path)
  local lua_colocation_path = (context_dir .. lua_code_path)
  local record = {["sigil-path"] = sigil_path, ["src-path"] = src_path0, ["lua-path"] = lua_cache_path, ["lua-cache-path"] = lua_cache_path, ["lua-colocation-path"] = lua_colocation_path, ["colocation-root-path"] = context_dir, ["cache-root-path"] = cache_path_for_compiled_artefact(namespace), namespace = namespace, modname = modname}
  local unsafely_3f = (opts["unsafely?"] or false)
  if (true == not unsafely_3f) then
    for _, key in ipairs(REQUIRED_KEYS) do
      assert(record[key], fmt("could not generate required key: %s from src-path: %s", key, src_path0))
    end
  else
  end
  return record
end
return {new = new}