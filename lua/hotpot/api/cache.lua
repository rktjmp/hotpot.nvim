local uv = vim.loop
local function cache_prefix()
  local _let_1_ = require("hotpot.loader")
  local compiled_cache_path = _let_1_["compiled-cache-path"]
  return compiled_cache_path
end
local function confirm_remove(path)
  local message = ("Remove file? " .. path)
  local opts = "NO\nYes"
  local _2_ = vim.fn.confirm(message, opts, 1, "Warning")
  if (_2_ == 1) then
    vim.notify("Did NOT remove file.")
    return false
  elseif (_2_ == 2) then
    return uv.fs_unlink(path)
  else
    return nil
  end
end
local function clear_cache()
  local function clear_dir(dir)
    local scanner = uv.fs_scandir(dir)
    local _let_4_ = require("hotpot.fs")
    local join_path = _let_4_["join-path"]
    local function _5_()
      return uv.fs_scandir_next(scanner)
    end
    for name, type in _5_ do
      if (type == "directory") then
        local child = join_path(dir, name)
        clear_dir(child)
        uv.fs_rmdir(child)
      elseif (type == "link") then
        uv.fs_unlink(join_path(dir, name))
      elseif (type == "file") then
        uv.fs_unlink(join_path(dir, name))
      else
      end
    end
    return nil
  end
  local prefix = cache_prefix()
  local _
  if not (prefix and not ("" == prefix)) then
    local failed_what_1_auto = "(and prefix (not (= \"\" prefix)))"
    local err_2_auto = string.format("%s [failed: %s]", "cache-prefix was nil or blank, refusing to continue", failed_what_1_auto)
    _ = error(string.format(err_2_auto), 0)
  else
    _ = nil
  end
  local message = ("Remove all files under: " .. prefix)
  local options = "NO\nYes"
  local _8_ = vim.fn.confirm(message, options, 1, "Warning")
  if (_8_ == 1) then
    print("Did NOT remove files.")
    return false
  elseif (_8_ == 2) then
    return clear_dir(prefix)
  else
    return nil
  end
end
local function open_cache(_3fhow, _3fopts)
  return vim.cmd.vsplit(cache_prefix())
end
return {["open-cache"] = open_cache, ["clear-cache"] = clear_cache, ["cache-prefix"] = cache_prefix}