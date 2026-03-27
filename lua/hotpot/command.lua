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
local function hotpot_command_sync_handler(params)
  local path = (params.context or vim.uv.cwd())
  local opts = {["force?"] = params.force, ["verbose?"] = params.verbose, ["atomic?"] = params.atomic}
  local case_8_, case_9_ = R.context.nearest(path)
  if (nil ~= case_8_) then
    local root = case_8_
    local function _10_(...)
      local case_11_, case_12_ = ...
      if ((case_11_ == true) and (nil ~= case_12_)) then
        local ctx = case_12_
        local function _13_(...)
          local case_14_, case_15_ = ...
          if ((case_14_ == true) and (nil ~= case_15_)) then
            local report = case_15_
            local case_16_, case_17_ = report, not opts["verbose?"]
            if (((_G.type(case_16_) == "table") and ((_G.type(case_16_.errors) == "table") and (case_16_.errors[1] == nil))) and (case_17_ == true)) then
              local msg = string.format("Synced %s", root)
              vim.notify(msg, vim.log.levels.INFO, {})
              return nil
            else
              local _ = case_16_
              return nil
            end
          elseif ((case_14_ == false) and (nil ~= case_15_)) then
            local err = case_15_
            return vim.notify(err, vim.log.levels.ERROR, {})
          else
            return nil
          end
        end
        return _13_(pcall(R.context.sync, ctx, opts))
      elseif ((case_11_ == false) and (nil ~= case_12_)) then
        local err = case_12_
        return vim.notify(err, vim.log.levels.ERROR, {})
      else
        return nil
      end
    end
    return _10_(pcall(R.context.new, root))
  elseif ((case_8_ == nil) and (nil ~= case_9_)) then
    local err = case_9_
    return vim.notify(err, vim.log.levels.ERROR, {})
  else
    return nil
  end
end
local function hotpot_command_watch_handler(params)
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
end
local function hotpot_command_fennel_rollback_handler(download_to_path, params)
  local case_23_ = vim.uv.fs_stat(download_to_path)
  if (_G.type(case_23_) == "table") then
    local case_24_, case_25_ = vim.uv.fs_unlink(download_to_path)
    if (case_24_ == true) then
      return vim.notify("Removed downloaded Fennel, please restart Neovim.", vim.log.levels.INFO)
    elseif ((case_24_ == nil) and (nil ~= case_25_)) then
      local err = case_25_
      return vim.notify(string.format("Unable to remove %s: %s", download_to_path, err), vim.log.levels.error)
    else
      return nil
    end
  elseif (case_23_ == nil) then
    return vim.notify("Unable to rollback, nothing to remove", vim.log.levels.ERROR)
  else
    return nil
  end
end
local function hotpot_command_fennel_version_handler(download_to_path, params)
  return vim.notify(string.format("Fennel version: %s", R.fennel.version), vim.log.levels.INFO)
end
local function hotpot_command_fennel_update_handler(download_to_path, params)
  local function http_get(url)
    local curl_opts = "-sL"
    vim.notify(string.format("Fetching %s...", url), vim.log.levels.INFO, {})
    return vim.fn.system(table.concat({"curl", curl_opts, url}, " "))
  end
  local function install_update(update_url)
    local source = http_get(update_url)
    local case_28_, case_29_ = loadstring(source)
    if (nil ~= case_28_) then
      local func = case_28_
      local fh = assert(io.open(download_to_path, "w"), ("io.open failed:" .. download_to_path))
      local function close_handlers_13_(ok_14_, ...)
        fh:close()
        if ok_14_ then
          return ...
        else
          return error(..., 0)
        end
      end
      local function _31_()
        fh:write(source)
        return vim.notify("Updated Fennel. You must restart Neovim.", vim.log.levels.INFO, {})
      end
      local _33_
      do
        local t_32_ = _G
        if (nil ~= t_32_) then
          t_32_ = t_32_.package
        else
        end
        if (nil ~= t_32_) then
          t_32_ = t_32_.loaded
        else
        end
        if (nil ~= t_32_) then
          t_32_ = t_32_.fennel
        else
        end
        _33_ = t_32_
      end
      local or_37_ = _33_ or _G.debug
      if not or_37_ then
        local function _38_()
          return ""
        end
        or_37_ = {traceback = _38_}
      end
      return close_handlers_13_(_G.xpcall(_31_, or_37_.traceback))
    elseif ((case_28_ == nil) and (nil ~= case_29_)) then
      local err = case_29_
      return vim.notify(string.format("Invalid lua %s...", err), vim.log.levels.ERROR, {})
    else
      return nil
    end
  end
  local function check_latest_online(force_3f)
    local url = "https://fennel-lang.org/downloads/"
    local index = http_get(url)
    local _ = vim.notify("Finding latest version...", vim.log.levels.INFO, {})
    local versions
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for version in string.gmatch(index, "href=[\"'](fennel%-[0-9]+%.[0-9]+%.[0-9]+%.lua)[\"']") do
        local val_28_ = version
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      versions = tbl_26_
    end
    local _0
    local function _41_(_241, _242)
      return (_241 > _242)
    end
    _0 = table.sort(versions, _41_)
    local installed_version = R.fennel.version
    if ((_G.type(versions) == "table") and (nil ~= versions[1])) then
      local latest = versions[1]
      local case_42_, case_43_ = string.match(latest, "fennel%-([0-9%.]+)%.lua")
      if (case_42_ == installed_version) then
        vim.notify(string.format("Already at version %s", installed_version), vim.log.levels.INFO, {})
        return nil
      elseif (nil ~= case_42_) then
        local online_version = case_42_
        local final_url = (url .. latest)
        if force_3f then
          return final_url
        else
          local choices = {"Yes", "No"}
          local prompt = string.format("Download version %s?", online_version)
          local answer = {["ok?"] = false}
          local function _44_(_241)
            answer["ok?"] = _241
            return nil
          end
          R.ui["ui-select-sync"](choices, {prompt = prompt}, _44_)
          if (answer["ok?"] == "Yes") then
            return final_url
          else
            vim.notify("Ok, doing nothing.", vim.log.levels.INFO, {})
            return nil
          end
        end
      else
        return nil
      end
    elseif ((_G.type(versions) == "table") and (versions[1] == nil)) then
      vim.notify("Could not find any versions...", vim.log.levels.ERROR, {})
      return nil
    else
      return nil
    end
  end
  local _3fforce_3f = params.force
  local _3furl = params.url
  local version_url = (_3furl or check_latest_online((true == _3fforce_3f)))
  if version_url then
    return install_update(version_url)
  else
    return nil
  end
end
local function hotpot_command_fennel_handler(params)
  local download_to_path = vim.fs.joinpath(R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT, "fennel.lua")
  if ((_G.type(params) == "table") and (params.rollback == true)) then
    return hotpot_command_fennel_rollback_handler(download_to_path, params)
  elseif ((_G.type(params) == "table") and (params.update == true)) then
    return hotpot_command_fennel_update_handler(download_to_path, params)
  elseif ((_G.type(params) == "table") and (params.version == true)) then
    return hotpot_command_fennel_version_handler(download_to_path, params)
  else
    local _ = params
    return vim.notify("Unrecognised sub command", vim.log.levels.ERROR)
  end
end
local function hotpot_command_handler(_51_)
  local fargs = _51_.fargs
  local command = fargs[1]
  local args = (function (t, k) return ((getmetatable(t) or {}).__fennelrest or function (t, k) return {(table.unpack or unpack)(t, k)} end)(t, k) end)(fargs, 2)
  local params, parse_error
  do
    local case_52_, case_53_ = pcall(parse_args, args)
    if ((case_52_ == true) and (nil ~= case_53_)) then
      local params0 = case_53_
      params, parse_error = params0
    elseif ((case_52_ == false) and (nil ~= case_53_)) then
      local err = case_53_
      params, parse_error = nil, err
    else
      params, parse_error = nil
    end
  end
  local usage
  local function _55_()
    return vim.notify("Usage: Hotpot sync|autocmd params...", vim.log.levels.WARN)
  end
  usage = _55_
  if params then
    if (command == nil) then
      return usage()
    elseif (command == "fennel") then
      return hotpot_command_fennel_handler(params)
    elseif (command == "sync") then
      return hotpot_command_sync_handler(params)
    elseif (command == "watch") then
      return hotpot_command_watch_handler(params)
    else
      local _ = command
      return usage()
    end
  else
    return vim.notify(parse_error, vim.log.levels.ERROR, {})
  end
end
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
local function filter_param_options_no_duplicates(possible_params, existing_params, current_param)
  if (nil == current_param) then
    _G.error("Missing argument current-param on fnl/hotpot/command.fnl:146", 2)
  else
  end
  if (nil == existing_params) then
    _G.error("Missing argument existing-params on fnl/hotpot/command.fnl:146", 2)
  else
  end
  if (nil == possible_params) then
    _G.error("Missing argument possible-params on fnl/hotpot/command.fnl:146", 2)
  else
  end
  local function filter0(options, prefix)
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
  vim.print({possible_params, existing_params, current_param})
  local existing_names
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, arg in ipairs(existing_params) do
      local val_28_ = string.match(arg, "([a-z]+=?).*")
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    existing_names = tbl_26_
  end
  local unused_names
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, param in ipairs(possible_params) do
      local val_28_
      do
        local check = param
        for _0, used in ipairs(existing_names) do
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
    unused_names = tbl_26_
  end
  return filter0(unused_names, current_param)
end
local function hotpot_command_completion(arg_lead, cmd_line, cursor_pos)
  local case_70_ = vim.split(cmd_line, "%s+")
  if ((_G.type(case_70_) == "table") and (case_70_[1] == "Hotpot") and (nil ~= case_70_[2]) and (case_70_[3] == nil)) then
    local current_partial = case_70_[2]
    return filter_param_options_no_duplicates({"sync", "watch", "fennel"}, {}, current_partial)
  elseif ((_G.type(case_70_) == "table") and (case_70_[1] == "Hotpot") and (case_70_[2] == "watch") and (nil ~= case_70_[3]) and (case_70_[4] == nil)) then
    local current_partial = case_70_[3]
    local function _71_()
      if R.autocmd["enabled?"] then
        return "disable"
      else
        return "enable"
      end
    end
    return filter_param_options_no_duplicates({_71_()}, {}, current_partial)
  elseif ((_G.type(case_70_) == "table") and (case_70_[1] == "Hotpot") and (case_70_[2] == "fennel")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_70_))}
    if ((_G.type(current_params) == "table") and (current_params[1] == "update")) then
      local current_params0 = {select(2, (table.unpack or _G.unpack)(current_params))}
      local current_partial = table.remove(current_params0)
      return filter_param_options_no_duplicates({"url=", "force"}, current_params0, current_partial)
    elseif ((_G.type(current_params) == "table") and (current_params[1] == "rollback")) then
      return {}
    elseif ((_G.type(current_params) == "table") and (current_params[1] == "version")) then
      return {}
    elseif ((_G.type(current_params) == "table") and true and (current_params[2] == nil)) then
      local _3fcurrent_partial = current_params[1]
      return filter_param_options_no_duplicates({"update", "rollback", "version"}, {}, (_3fcurrent_partial or ""))
    else
      return nil
    end
  elseif ((_G.type(case_70_) == "table") and (case_70_[1] == "Hotpot") and (case_70_[2] == "sync")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_70_))}
    local case_73_, case_74_ = string.find(arg_lead, "^context=")
    if (true and (nil ~= case_74_)) then
      local _start = case_73_
      local ends = case_74_
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
      local _ = case_73_
      local current_partial = table.remove(current_params)
      return filter_param_options_no_duplicates({"context=", "force", "verbose", "atomic"}, current_params, current_partial)
    end
  else
    return nil
  end
end
local function fetch_context(_3fpath)
  local try_path
  local function _78_(...)
    local case_79_ = ...
    if (case_79_ == nil) then
      local function _80_(...)
        local case_81_ = ...
        if (case_81_ == nil) then
          return vim.uv.cwd()
        elseif (nil ~= case_81_) then
          local path = case_81_
          return path
        else
          return nil
        end
      end
      return _80_(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)))
    elseif (nil ~= case_79_) then
      local path = case_79_
      return path
    else
      return nil
    end
  end
  try_path = _78_(vim.uv.fs_realpath((_3fpath or "")))
  return R.api.context(R.context.nearest(try_path))
end
local function pack(...)
  local tmp_9_ = {...}
  tmp_9_["n"] = select("#", ...)
  return tmp_9_
end
local function make_output_flag_aware_eval(ctx, args)
  if (nil == args) then
    _G.error("Missing argument args on fnl/hotpot/command.fnl:223", 2)
  else
  end
  if (nil == ctx) then
    _G.error("Missing argument ctx on fnl/hotpot/command.fnl:223", 2)
  else
  end
  local output
  do
    local case_86_ = string.find(args, "=", 1, true)
    if (case_86_ == 1) then
      output = vim.print
    else
      local _ = case_86_
      local function _87_(...)
        return ...
      end
      output = _87_
    end
  end
  local function _89_(source)
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
  return _89_
end
local function fnl_command_handler(_91_)
  local range = _91_.range
  local line1 = _91_.line1
  local line2 = _91_.line2
  local count = _91_.count
  local args = _91_.args
  local opts = _91_
  local ctx = fetch_context()
  local eval = make_output_flag_aware_eval(ctx, args)
  if ((args == "") or (args == "=")) then
    local case_92_ = {range = range, line1 = line1, line2 = line2, count = count}
    if ((case_92_.range == 1) and (nil ~= case_92_.line1) and (case_92_.line1 == case_92_.line2) and (case_92_.line1 == case_92_.count)) then
      local n = case_92_.line1
      local from = vim.fn.line(".")
      local text = table.concat(vim.api.nvim_buf_get_lines(0, (from - 1), (from + count + -1), false), "\n")
      return eval(text)
    elseif ((case_92_.range == 2) and (nil ~= case_92_.line1) and (nil ~= case_92_.line2)) then
      local a = case_92_.line1
      local b = case_92_.line2
      local last_cmd = vim.fn.histget("cmd", -1)
      local case_93_ = string.find(last_cmd, "'<,'>", 1, true)
      if (case_93_ == 1) then
        local _let_94_ = vim.fn.getcharpos("'<")
        local _buf = _let_94_[1]
        local _line = _let_94_[2]
        local start_col = _let_94_[3]
        local _virt = _let_94_[4]
        local _let_95_ = vim.fn.getcharpos("'>")
        local _buf0 = _let_95_[1]
        local _line0 = _let_95_[2]
        local end_col = _let_95_[3]
        local _virt0 = _let_95_[4]
        local text = table.concat(vim.api.nvim_buf_get_text(0, (line1 - 1), (start_col - 1), (line2 - 1), (end_col - 0), {}), "\n")
        return eval(text)
      else
        local _ = case_93_
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
local function fnlfile_command_handler(_99_)
  local args = _99_.args
  local fargs = _99_.fargs
  local path
  do
    local case_100_ = string.find(args, "=", 1, true)
    if (case_100_ == 1) then
      path = vim.trim(string.sub(args, 2))
    else
      local _ = case_100_
      path = args
    end
  end
  if vim.uv.fs_access(path, "r") then
    local ctx = fetch_context(path)
    local eval = make_output_flag_aware_eval(ctx, args)
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
      local function _103_()
        return fh:read("*a")
      end
      local _105_
      do
        local t_104_ = _G
        if (nil ~= t_104_) then
          t_104_ = t_104_.package
        else
        end
        if (nil ~= t_104_) then
          t_104_ = t_104_.loaded
        else
        end
        if (nil ~= t_104_) then
          t_104_ = t_104_.fennel
        else
        end
        _105_ = t_104_
      end
      local or_109_ = _105_ or _G.debug
      if not or_109_ then
        local function _110_()
          return ""
        end
        or_109_ = {traceback = _110_}
      end
      file_contents = close_handlers_13_(_G.xpcall(_103_, or_109_.traceback))
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
    local function callback(_112_)
      local path = _112_.file
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
          local function _114_()
            return fh:read("*a")
          end
          local _116_
          do
            local t_115_ = _G
            if (nil ~= t_115_) then
              t_115_ = t_115_.package
            else
            end
            if (nil ~= t_115_) then
              t_115_ = t_115_.loaded
            else
            end
            if (nil ~= t_115_) then
              t_115_ = t_115_.fennel
            else
            end
            _116_ = t_115_
          end
          local or_120_ = _116_ or _G.debug
          if not or_120_ then
            local function _121_()
              return ""
            end
            or_120_ = {traceback = _121_}
          end
          file_contents = close_handlers_13_(_G.xpcall(_114_, or_120_.traceback))
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