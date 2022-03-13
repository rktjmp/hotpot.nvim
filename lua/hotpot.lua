local uv = vim.loop
local function canary_link_path(cache_dir)
  return (cache_dir .. "canary")
end
local function canary_valid_3f(cache_dir)
  local _1_, _2_ = uv.fs_realpath(canary_link_path(cache_dir))
  if ((_1_ == nil) and (nil ~= _2_)) then
    local err = _2_
    return false
  elseif (nil ~= _1_) then
    local path = _1_
    return true
  else
    return nil
  end
end
local function make_canary(cache_dir, fnl_dir)
  local canary_file
  do
    local dir = uv.fs_opendir((fnl_dir .. "/../canary/"), nil, 1)
    local content = uv.fs_readdir(dir)
    local _ = uv.fs_closedir(dir)
    canary_file = content[1].name
  end
  uv.fs_unlink(canary_link_path(cache_dir))
  return uv.fs_symlink((fnl_dir .. "/../canary/" .. canary_file), canary_link_path(cache_dir))
end
local function load_hotpot(cache_dir, fnl_dir)
  local old_package_path = package.path
  local hotpot_path = (cache_dir .. fnl_dir .. "/?.lua;" .. package.path)
  local _
  package.path = hotpot_path
  _ = nil
  local hotpot = require("hotpot.runtime")
  hotpot.install()
  do end (hotpot)["install"] = nil
  hotpot["uninstall"] = nil
  return hotpot
end
local function clear_cache(cache_dir)
  local scanner = uv.fs_scandir(cache_dir)
  local function _4_()
    return uv.fs_scandir_next(scanner)
  end
  for name, type in _4_ do
    local _5_ = type
    if (_5_ == "directory") then
      local child = (cache_dir .. "/" .. name)
      clear_cache(child)
      uv.fs_rmdir(child)
    elseif (_5_ == "file") then
      uv.fs_unlink((cache_dir .. "/" .. name))
    else
    end
  end
  return nil
end
local function bootstrap_compile(cache_dir, fnl_dir)
  local function compile_file(fnl_src, lua_dest)
    local _let_7_ = require("hotpot.fennel")
    local compile_string = _let_7_["compile-string"]
    local fnl_file = io.open(fnl_src)
    local lua_file = io.open(lua_dest, "w")
    local function close_handlers_8_auto(ok_9_auto, ...)
      lua_file:close()
      fnl_file:close()
      if ok_9_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _9_()
      local fnl_code = fnl_file:read("*a")
      local lua_code = compile_string(fnl_code, {correlate = true})
      return lua_file:write(lua_code)
    end
    return close_handlers_8_auto(_G.xpcall(_9_, (package.loaded.fennel or debug).traceback))
  end
  local function compile_dir(fennel, in_dir, out_dir)
    local scanner = uv.fs_scandir(in_dir)
    local function _10_()
      return uv.fs_scandir_next(scanner)
    end
    for name, type in _10_ do
      local _11_ = type
      if (_11_ == "directory") then
        local out_down = (cache_dir .. "/" .. in_dir .. "/" .. name)
        local in_down = (in_dir .. "/" .. name)
        vim.fn.mkdir(out_down, "p")
        compile_dir(fennel, in_down, out_down)
      elseif (_11_ == "file") then
        local out_file = (out_dir .. "/" .. string.gsub(name, ".fnl$", ".lua"))
        local in_file = (in_dir .. "/" .. name)
        if not (name == "macros.fnl") then
          compile_file(in_file, out_file)
        else
        end
      else
      end
    end
    return nil
  end
  local fennel = require("hotpot.fennel")
  local saved = {path = fennel.path, ["macro-path"] = fennel["macro-path"]}
  fennel.path = (fnl_dir .. "/?.fnl;" .. fennel.path)
  fennel["macro-path"] = (fnl_dir .. "/?.fnl;" .. fennel.path)
  table.insert(package.loaders, fennel.searcher)
  compile_dir(fennel, fnl_dir, cache_dir, "")
  fennel.path = saved.path
  fennel["macro-path"] = saved["macro-path"]
  do
    local done = nil
    for i, check in ipairs(package.loaders) do
      if done then break end
      if (check == fennel.searcher) then
        done = table.remove(package.loaders, i)
      else
        done = nil
      end
    end
  end
  return make_canary(cache_dir, fnl_dir)
end
local plugin_dir = string.gsub(uv.fs_realpath((vim.api.nvim_get_runtime_file("lua/hotpot.lua", false))[1]), "/lua/hotpot.lua$", "")
local hotpot_fnl_dir = (plugin_dir .. "/fnl")
local cache_root_dir = (vim.fn.stdpath("cache") .. "/hotpot")
local _15_ = canary_valid_3f(cache_root_dir)
if (_15_ == true) then
  return load_hotpot(cache_root_dir, hotpot_fnl_dir)
elseif (_15_ == false) then
  bootstrap_compile(cache_root_dir, hotpot_fnl_dir)
  return load_hotpot(cache_root_dir, hotpot_fnl_dir)
else
  return nil
end
