local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local M, m = {}, {}
local function buf_write_post_callback(event)
  local Context = R.Context
  local path = event.match
  local function _2_(...)
    local case_3_, case_4_ = ...
    if ((case_3_ == true) and (nil ~= case_4_)) then
      local root = case_4_
      local function _5_(...)
        local case_6_, case_7_ = ...
        if ((case_6_ == true) and (nil ~= case_7_)) then
          local ctx = case_7_
          local function _8_(...)
            local case_9_, case_10_ = ...
            if ((case_9_ == true) and true) then
              local _report = case_10_
              return nil
            elseif ((case_9_ == false) and (nil ~= case_10_)) then
              local err = case_10_
              return vim.notify(err, vim.log.level.ERROR, {})
            else
              return nil
            end
          end
          return _8_(pcall(Context.sync, ctx))
        elseif ((case_6_ == false) and (nil ~= case_7_)) then
          local err = case_7_
          return vim.notify(err, vim.log.level.ERROR, {})
        else
          return nil
        end
      end
      return _5_(pcall(Context.new, root))
    elseif ((case_3_ == false) and (nil ~= case_4_)) then
      local err = case_4_
      return vim.notify(err, vim.log.level.ERROR, {})
    else
      return nil
    end
  end
  _2_(pcall(Context.nearest, path))
  return nil
end
local _2aaugroup_id_2a = nil
M.enable = function()
  if not _2aaugroup_id_2a then
    local augroup_id = vim.api.nvim_create_augroup("hotpot-fnl-ft", {clear = true})
    vim.api.nvim_create_autocmd({"BufWritePost"}, {pattern = {"*.fnl", "*.fnlm"}, callback = buf_write_post_callback})
    _2aaugroup_id_2a = augroup_id
    return nil
  else
    return nil
  end
end
M.disable = function()
  if _2aaugroup_id_2a then
    vim.api.nvim_delete_augroup_by_id(_2aaugroup_id_2a)
    _2aaugroup_id_2a = nil
    return nil
  else
    return nil
  end
end
return M