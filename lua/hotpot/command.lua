local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local function parse_args(args)
  local tbl_21_ = {}
  for _, arg in ipairs(args) do
    local k_22_, v_23_
    do
      local case_2_, case_3_ = string.match(arg, "^([^=]+)=(.+)$")
      if ((nil ~= case_2_) and (case_3_ == "true")) then
        local key = case_2_
        k_22_, v_23_ = key, true
      elseif ((nil ~= case_2_) and (case_3_ == "false")) then
        local key = case_2_
        k_22_, v_23_ = key, false
      elseif ((nil ~= case_2_) and (nil ~= case_3_)) then
        local key = case_2_
        local val = case_3_
        k_22_, v_23_ = key, val
      elseif (case_2_ == nil) then
        local case_4_ = string.match(arg, "^([^=]+)=$")
        if (nil ~= case_4_) then
          local name = case_4_
          k_22_, v_23_ = error(string.format("Param error: gave key %s but no value assigned.", arg), 0)
        elseif (case_4_ == nil) then
          k_22_, v_23_ = arg, true
        else
          k_22_, v_23_ = nil
        end
      else
        k_22_, v_23_ = nil
      end
    end
    if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
      tbl_21_[k_22_] = v_23_
    else
    end
  end
  return tbl_21_
end
local function command_handler(_8_)
  local fargs = _8_.fargs
  local command = fargs[1]
  local args = (function (t, k) return ((getmetatable(t) or {}).__fennelrest or function (t, k) return {(table.unpack or unpack)(t, k)} end)(t, k) end)(fargs, 2)
  local params, parse_error
  do
    local case_9_, case_10_ = pcall(parse_args, args)
    if ((case_9_ == true) and (nil ~= case_10_)) then
      local params0 = case_10_
      params, parse_error = params0
    elseif ((case_9_ == false) and (nil ~= case_10_)) then
      local err = case_10_
      params, parse_error = nil, err
    else
      params, parse_error = nil
    end
  end
  local usage
  local function _12_()
    return vim.notify("Usage: Hotpot sync|autocmd params...")
  end
  usage = _12_
  if params then
    if (command == nil) then
      return usage()
    elseif (command == "sync") then
      local path = (params.context or vim.uv.cwd())
      local opts = {["force?"] = params.force, ["verbose?"] = params.verbose, ["atomic?"] = params.atomic}
      local case_13_, case_14_ = R.context.nearest(path)
      if (nil ~= case_13_) then
        local root = case_13_
        local function _15_(...)
          local case_16_, case_17_ = ...
          if ((case_16_ == true) and (nil ~= case_17_)) then
            local ctx = case_17_
            local function _18_(...)
              local case_19_, case_20_ = ...
              if ((case_19_ == true) and (nil ~= case_20_)) then
                local report = case_20_
                local case_21_, case_22_ = report, not opts["verbose?"]
                if (((_G.type(case_21_) == "table") and ((_G.type(case_21_.errors) == "table") and (case_21_.errors[1] == nil))) and (case_22_ == true)) then
                  local msg = string.format("Synced %s", root)
                  vim.notify(msg, vim.log.levels.INFO, {})
                  return nil
                else
                  local _ = case_21_
                  return nil
                end
              elseif ((case_19_ == false) and (nil ~= case_20_)) then
                local err = case_20_
                return vim.notify(err, vim.log.levels.ERROR, {})
              else
                return nil
              end
            end
            return _18_(pcall(R.context.sync, ctx, opts))
          elseif ((case_16_ == false) and (nil ~= case_17_)) then
            local err = case_17_
            return vim.notify(err, vim.log.levels.ERROR, {})
          else
            return nil
          end
        end
        return _15_(pcall(R.context.new, root))
      elseif ((case_13_ == nil) and (nil ~= case_14_)) then
        local err = case_14_
        return vim.notify(err, vim.log.levels.ERROR, {})
      else
        return nil
      end
    elseif (command == "autocmd") then
      if ((_G.type(params) == "table") and (params.enable == true)) then
        R.autocmd.enable()
        return vim.notify("Enabled Hotpot autocommand", vim.log.levels.INFO, {})
      elseif ((_G.type(params) == "table") and (params.disable == true)) then
        R.autocmd.disable()
        return vim.notify("Disabled Hotpot autocommand", vim.log.levels.INFO, {})
      else
        local _ = params
        return vim.notify("Usage: Hotpot autocmd enable|disable")
      end
    else
      local _ = command
      return usage()
    end
  else
    return vim.notify(parse_error, vim.log.levels.ERROR, {})
  end
end
local function command_completion(arg_lead, cmd_line, cursor_pos)
  local function filter(prefix, options)
    if (prefix == "") then
      return options
    else
      local _ = prefix
      local tbl_26_ = {}
      local i_27_ = 0
      for _0, opt in ipairs(options) do
        local val_28_
        if vim.startswith(opt, prefix) then
          val_28_ = opt
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    end
  end
  local case_33_ = vim.split(cmd_line, "%s+")
  if ((_G.type(case_33_) == "table") and (case_33_[1] == "Hotpot") and (nil ~= case_33_[2]) and (case_33_[3] == nil)) then
    local part = case_33_[2]
    return filter(part, {"sync", "autocmd"})
  elseif ((_G.type(case_33_) == "table") and (case_33_[1] == "Hotpot") and (case_33_[2] == "autocmd") and (nil ~= case_33_[3]) and (case_33_[4] == nil)) then
    local part = case_33_[3]
    if R.autocmd["enabled?"]() then
      return filter(part, {"disable"})
    else
      return filter(part, {"enable"})
    end
  elseif ((_G.type(case_33_) == "table") and (case_33_[1] == "Hotpot") and (case_33_[2] == "sync")) then
    local rest = case_33_
    local case_35_, case_36_ = string.find(arg_lead, "^context=")
    if (true and (nil ~= case_36_)) then
      local _start = case_35_
      local ends = case_36_
      local partial_path = string.sub(arg_lead, (ends + 1))
      local paths = vim.fn.getcompletion(partial_path, "dir")
      local tbl_26_ = {}
      local i_27_ = 0
      for _, path in ipairs(paths) do
        local val_28_ = ("context=" .. path)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    else
      local _ = case_35_
      local part = table.remove(rest)
      local existing_params
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _0, arg in ipairs(rest) do
          local val_28_ = string.match(arg, "([a-z]+=?).*")
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        existing_params = tbl_26_
      end
      local new_params
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _0, param in ipairs({"context=", "force", "verbose", "atomic"}) do
          local val_28_
          do
            local check = param
            for _1, used in ipairs(existing_params) do
              if not check then break end
              if (used ~= check) then
                check = check
              else
                check = nil
              end
            end
            val_28_ = check
          end
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        new_params = tbl_26_
      end
      return filter(part, new_params)
    end
  else
    return nil
  end
end
local function define_command()
  return vim.api.nvim_create_user_command("Hotpot", command_handler, {nargs = "*", complete = command_completion})
end
return {enable = define_command}