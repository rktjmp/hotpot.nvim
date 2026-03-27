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
local function hotpot_command_handler(_8_)
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
    elseif (command == "watch") then
      if ((_G.type(params) == "table") and (params.enable == true)) then
        R.autocmd.enable()
        return vim.notify("Enabled Hotpot autocommand", vim.log.levels.INFO, {})
      elseif ((_G.type(params) == "table") and (params.disable == true)) then
        R.autocmd.disable()
        return vim.notify("Disabled Hotpot autocommand", vim.log.levels.INFO, {})
      else
        local _ = params
        return vim.notify("Usage: Hotpot watch enable|disable")
      end
    else
      local _ = command
      return usage()
    end
  else
    return vim.notify(parse_error, vim.log.levels.ERROR, {})
  end
end
local function hotpot_command_completion(arg_lead, cmd_line, cursor_pos)
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
    return filter(part, {"sync", "watch"})
  elseif ((_G.type(case_33_) == "table") and (case_33_[1] == "Hotpot") and (case_33_[2] == "watch") and (nil ~= case_33_[3]) and (case_33_[4] == nil)) then
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
local function fetch_context(_3fpath)
  local try_path
  local function _43_(...)
    local case_44_ = ...
    if (case_44_ == nil) then
      local function _45_(...)
        local case_46_ = ...
        if (case_46_ == nil) then
          return vim.uv.cwd()
        elseif (nil ~= case_46_) then
          local path = case_46_
          return path
        else
          return nil
        end
      end
      return _45_(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)))
    elseif (nil ~= case_44_) then
      local path = case_44_
      return path
    else
      return nil
    end
  end
  try_path = _43_(vim.uv.fs_realpath((_3fpath or "")))
  return R.api.context(R.context.nearest(try_path))
end
local function pack(...)
  local tmp_9_ = {...}
  tmp_9_["n"] = select("#", ...)
  return tmp_9_
end
local function make_output_aware_eval(ctx, args)
  if (nil == args) then
    _G.error("Missing argument args on fnl/hotpot/command.fnl:111", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/command.fnl:111", 2)
  else
  end
  local output
  do
    local case_51_ = string.find(args, "=", 1, true)
    if (case_51_ == 1) then
      output = vim.print
    else
      local _ = case_51_
      local function _52_(...)
        return ...
      end
      output = _52_
    end
  end
  local function _54_(source)
    local returns = pack(ctx.eval(source))
    local ok_3f = table.remove(returns, 1)
    if (ok_3f == true) then
      return output(unpack(returns, 1, (returns.n - 1)))
    elseif (ok_3f == false) then
      return vim.notify(returns[1], vim.log.levels.ERROR, {})
    else
      return nil
    end
  end
  return _54_
end
local function fnl_command_handler(_56_)
  local range = _56_.range
  local line1 = _56_.line1
  local line2 = _56_.line2
  local count = _56_.count
  local args = _56_.args
  local opts = _56_
  local ctx = fetch_context()
  local eval = make_output_aware_eval(ctx, args)
  if ((args == "") or (args == "=")) then
    local case_57_ = {range = range, line1 = line1, line2 = line2, count = count}
    if ((case_57_.range == 1) and (nil ~= case_57_.line1) and (case_57_.line1 == case_57_.line2) and (case_57_.line1 == case_57_.count)) then
      local n = case_57_.line1
      local from = vim.fn.line(".")
      local text = table.concat(vim.api.nvim_buf_get_lines(0, (from - 1), (from + count + -1), false), "\n")
      return eval(text)
    elseif ((case_57_.range == 2) and (nil ~= case_57_.line1) and (nil ~= case_57_.line2)) then
      local a = case_57_.line1
      local b = case_57_.line2
      local last_cmd = vim.fn.histget("cmd", -1)
      local case_58_ = string.find(last_cmd, "'<,'>", 1, true)
      if (case_58_ == 1) then
        local _let_59_ = vim.fn.getcharpos("'<")
        local _buf = _let_59_[1]
        local _line = _let_59_[2]
        local start_col = _let_59_[3]
        local _virt = _let_59_[4]
        local _let_60_ = vim.fn.getcharpos("'>")
        local _buf0 = _let_60_[1]
        local _line0 = _let_60_[2]
        local end_col = _let_60_[3]
        local _virt0 = _let_60_[4]
        local text = table.concat(vim.api.nvim_buf_get_text(0, (line1 - 1), (start_col - 1), (line2 - 1), (end_col - 0), {}), "\n")
        return eval(text)
      else
        local _ = case_58_
        local text = table.concat(vim.api.nvim_buf_get_lines(0, (line1 - 1), line2, false), "\n")
        return eval(text)
      end
    else
      return nil
    end
  else
    local _ = args
    local source = string.sub(args, 2)
    return eval(source)
  end
end
local function fnlfile_command_handler(_64_)
  local args = _64_.args
  local fargs = _64_.fargs
  local path
  do
    local case_65_ = string.find(args, "=", 1, true)
    if (case_65_ == 1) then
      path = vim.trim(string.sub(args, 2))
    else
      local _ = case_65_
      path = args
    end
  end
  if vim.uv.fs_access(path, "r") then
    local ctx = fetch_context(path)
    local eval = make_output_aware_eval(ctx, args)
    local file_contents
    do
      local fh = io.open(path, "r")
      local function close_handlers_13_(ok_14_, ...)
        fh:close()
        if ok_14_ then
          return ...
        else
          return error(..., 0)
        end
      end
      local function _68_()
        return fh:read("*a")
      end
      local _70_
      do
        local t_69_ = _G
        if (nil ~= t_69_) then
          t_69_ = t_69_.package
        else
        end
        if (nil ~= t_69_) then
          t_69_ = t_69_.loaded
        else
        end
        if (nil ~= t_69_) then
          t_69_ = t_69_.fennel
        else
        end
        _70_ = t_69_
      end
      local or_74_ = _70_ or _G.debug
      if not or_74_ then
        local function _75_()
          return ""
        end
        or_74_ = {traceback = _75_}
      end
      file_contents = close_handlers_13_(_G.xpcall(_68_, or_74_.traceback))
    end
    return eval(file_contents)
  else
    return vim.notify(string.format("Cant read file %s", path), vim.log.levels.ERROR, {})
  end
end
local function define_hotpot()
  return vim.api.nvim_create_user_command("Hotpot", hotpot_command_handler, {nargs = "*", complete = hotpot_command_completion, desc = "Interact with Hotpot"})
end
local function define_fnl()
  return vim.api.nvim_create_user_command("Fnl", fnl_command_handler, {nargs = "*", range = true, desc = "Evaluate string of fnl or range, with = to print output"})
end
local function define_fnlfile()
  return vim.api.nvim_create_user_command("Fnlfile", fnlfile_command_handler, {nargs = 1, complete = "file", desc = "Evaluate given fennel file"})
end
local _2aaugroup_id_2a = nil
local function support_source_command()
  if not _2aaugroup_id_2a then
    local augroup_id = vim.api.nvim_create_augroup("hotpot-source-cmd", {clear = true})
    local function callback(_77_)
      local path = _77_.file
      if vim.uv.fs_access(path, "r") then
        local ctx = fetch_context(path)
        local file_contents
        do
          local fh = io.open(path, "r")
          local function close_handlers_13_(ok_14_, ...)
            fh:close()
            if ok_14_ then
              return ...
            else
              return error(..., 0)
            end
          end
          local function _79_()
            return fh:read("*a")
          end
          local _81_
          do
            local t_80_ = _G
            if (nil ~= t_80_) then
              t_80_ = t_80_.package
            else
            end
            if (nil ~= t_80_) then
              t_80_ = t_80_.loaded
            else
            end
            if (nil ~= t_80_) then
              t_80_ = t_80_.fennel
            else
            end
            _81_ = t_80_
          end
          local or_85_ = _81_ or _G.debug
          if not or_85_ then
            local function _86_()
              return ""
            end
            or_85_ = {traceback = _86_}
          end
          file_contents = close_handlers_13_(_G.xpcall(_79_, or_85_.traceback))
        end
        return ctx.eval(file_contents)
      else
        return vim.notify(string.format("Cant read file %s", path), vim.log.levels.ERROR, {})
      end
    end
    vim.api.nvim_create_autocmd({"SourceCmd"}, {pattern = {"*.fnl"}, group = augroup_id, callback = callback})
    _2aaugroup_id_2a = augroup_id
    return nil
  else
    return nil
  end
end
local function define_commands()
  define_hotpot()
  define_fnl()
  define_fnlfile()
  return support_source_command()
end
return {enable = define_commands}