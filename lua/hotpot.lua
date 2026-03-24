assert((1 == vim.fn.has("nvim-0.11.6")), "Hotpot requires neovim 0.11.6")
do
  local first_boot_sigil = vim.fs.joinpath(vim.fn.stdpath("cache"), "hotpot", "first-boot")
  if not vim.uv.fs_stat(first_boot_sigil) then
    vim.notify("Hotpot: Running first boot compile", vim.log.INFO, {})
    local Context = require("hotpot.aot.context")
    local ctx = Context.new(vim.fn.stdpath("config"))
    Context.sync(ctx)
    local fh = assert(io.open(first_boot_sigil, "w"), ("fs.read-file! io.open failed:" .. first_boot_sigil))
    local function close_handlers_13_(ok_14_, ...)
      fh:close()
      if ok_14_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _2_(...)
      local args_15_ = {...}
      local n_16_ = select("#", ...)
      local unpack_17_ = (_G.unpack or _G.table.unpack)
      local function _3_()
        local function _4_(...)
          local _let_5_ = vim.uv.clock_gettime("realtime")
          local sec = _let_5_.sec
          local nsec = _let_5_.nsec
          return fh:write(string.format("%s.%s", sec, nsec))
        end
        return _4_(unpack_17_(args_15_, 1, n_16_))
      end
      local _7_
      do
        local t_6_ = _G
        if (nil ~= t_6_) then
          t_6_ = t_6_.package
        else
        end
        if (nil ~= t_6_) then
          t_6_ = t_6_.loaded
        else
        end
        if (nil ~= t_6_) then
          t_6_ = t_6_.fennel
        else
        end
        _7_ = t_6_
      end
      local or_11_ = _7_ or _G.debug
      if not or_11_ then
        local function _12_()
          return ""
        end
        or_11_ = {traceback = _12_}
      end
      return _G.xpcall(_3_, or_11_.traceback)
    end
    close_handlers_13_(_2_(...))
  else
  end
end
do
  local autocmd = require("hotpot.autocmd")
  autocmd.enable()
end
local function _14_()
  return require("hotpot.aot.fennel")()
end
package.preload["fennel"] = _14_
local function setup(_3foptions)
  local default = {enable = true, fennel = {byo = false}}
  local options = vim.tbl_extend("force", default, (_3foptions or {}))
  if (false == options.enable) then
    local autocmd = require("hotpot.aot.autocmd")
    autocmd.disable()
  else
  end
  if (true == options.fennel.byo) then
    package.preload["fennel"] = nil
    return nil
  else
    return nil
  end
end
return {setup = setup}