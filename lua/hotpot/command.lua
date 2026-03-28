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
      R.util["file-write"](download_to_path, source)
      return vim.notify("Updated Fennel. You must restart Neovim.", vim.log.levels.INFO, {})
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
    local function _32_(_241, _242)
      return (_241 > _242)
    end
    _0 = table.sort(versions, _32_)
    local installed_version = R.fennel.version
    if ((_G.type(versions) == "table") and (nil ~= versions[1])) then
      local latest = versions[1]
      local case_33_, case_34_ = string.match(latest, "fennel%-([0-9%.]+)%.lua")
      if (case_33_ == installed_version) then
        vim.notify(string.format("Already at version %s", installed_version), vim.log.levels.INFO, {})
        return nil
      elseif (nil ~= case_33_) then
        local online_version = case_33_
        local final_url = (url .. latest)
        if force_3f then
          return final_url
        else
          local choices = {"Yes", "No"}
          local prompt = string.format("Download version %s?", online_version)
          local answer = {["ok?"] = false}
          local function _35_(_241)
            answer["ok?"] = _241
            return nil
          end
          R.ui["ui-select-sync"](choices, {prompt = prompt}, _35_)
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
local function hotpot_command_handler(_42_)
  local fargs = _42_.fargs
  local command = fargs[1]
  local args = (function (t, k) return ((getmetatable(t) or {}).__fennelrest or function (t, k) return {(table.unpack or unpack)(t, k)} end)(t, k) end)(fargs, 2)
  local params, parse_error
  do
    local case_43_, case_44_ = pcall(parse_args, args)
    if ((case_43_ == true) and (nil ~= case_44_)) then
      local params0 = case_44_
      params, parse_error = params0
    elseif ((case_43_ == false) and (nil ~= case_44_)) then
      local err = case_44_
      params, parse_error = nil, err
    else
      params, parse_error = nil
    end
  end
  local usage
  local function _46_()
    return vim.notify("Usage: Hotpot sync|autocmd params...", vim.log.levels.WARN)
  end
  usage = _46_
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
  local case_61_ = vim.split(cmd_line, "%s+")
  if ((_G.type(case_61_) == "table") and (case_61_[1] == "Hotpot") and (nil ~= case_61_[2]) and (case_61_[3] == nil)) then
    local current_partial = case_61_[2]
    return filter_param_options_no_duplicates({"sync", "watch", "fennel"}, {}, current_partial)
  elseif ((_G.type(case_61_) == "table") and (case_61_[1] == "Hotpot") and (case_61_[2] == "watch") and (nil ~= case_61_[3]) and (case_61_[4] == nil)) then
    local current_partial = case_61_[3]
    local function _62_()
      if R.autocmd["enabled?"] then
        return "disable"
      else
        return "enable"
      end
    end
    return filter_param_options_no_duplicates({_62_()}, {}, current_partial)
  elseif ((_G.type(case_61_) == "table") and (case_61_[1] == "Hotpot") and (case_61_[2] == "fennel")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_61_))}
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
  elseif ((_G.type(case_61_) == "table") and (case_61_[1] == "Hotpot") and (case_61_[2] == "sync")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_61_))}
    local case_64_, case_65_ = string.find(arg_lead, "^context=")
    if (true and (nil ~= case_65_)) then
      local _start = case_64_
      local ends = case_65_
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
      local _ = case_64_
      local current_partial = table.remove(current_params)
      return filter_param_options_no_duplicates({"context=", "force", "verbose", "atomic"}, current_params, current_partial)
    end
  else
    return nil
  end
end
local function fetch_context(_3fpath)
  local try_path
  local function _69_(...)
    local case_70_ = ...
    if (case_70_ == nil) then
      local function _71_(...)
        local case_72_ = ...
        if (case_72_ == nil) then
          return vim.uv.cwd()
        elseif (nil ~= case_72_) then
          local path = case_72_
          return path
        else
          return nil
        end
      end
      return _71_(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)))
    elseif (nil ~= case_70_) then
      local path = case_70_
      return path
    else
      return nil
    end
  end
  try_path = _69_(vim.uv.fs_realpath((_3fpath or "")))
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
    local case_77_ = string.find(args, "=", 1, true)
    if (case_77_ == 1) then
      output = vim.print
    else
      local _ = case_77_
      local function _78_(...)
        return ...
      end
      output = _78_
    end
  end
  local function _80_(source)
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
  return _80_
end
local function fnl_command_handler(_82_)
  local range = _82_.range
  local line1 = _82_.line1
  local line2 = _82_.line2
  local count = _82_.count
  local args = _82_.args
  local opts = _82_
  local ctx = fetch_context()
  local eval = make_output_flag_aware_eval(ctx, args)
  if ((args == "") or (args == "=")) then
    local case_83_ = {range = range, line1 = line1, line2 = line2, count = count}
    if ((case_83_.range == 1) and (nil ~= case_83_.line1) and (case_83_.line1 == case_83_.line2) and (case_83_.line1 == case_83_.count)) then
      local n = case_83_.line1
      local from = vim.fn.line(".")
      local text = table.concat(vim.api.nvim_buf_get_lines(0, (from - 1), (from + count + -1), false), "\n")
      return eval(text)
    elseif ((case_83_.range == 2) and (nil ~= case_83_.line1) and (nil ~= case_83_.line2)) then
      local a = case_83_.line1
      local b = case_83_.line2
      local last_cmd = vim.fn.histget("cmd", -1)
      local case_84_ = string.find(last_cmd, "'<,'>", 1, true)
      if (case_84_ == 1) then
        local _let_85_ = vim.fn.getcharpos("'<")
        local _buf = _let_85_[1]
        local _line = _let_85_[2]
        local start_col = _let_85_[3]
        local _virt = _let_85_[4]
        local _let_86_ = vim.fn.getcharpos("'>")
        local _buf0 = _let_86_[1]
        local _line0 = _let_86_[2]
        local end_col = _let_86_[3]
        local _virt0 = _let_86_[4]
        local text = table.concat(vim.api.nvim_buf_get_text(0, (line1 - 1), (start_col - 1), (line2 - 1), (end_col - 0), {}), "\n")
        return eval(text)
      else
        local _ = case_84_
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
local function fnlfile_command_handler(_90_)
  local args = _90_.args
  local fargs = _90_.fargs
  local path
  do
    local case_91_ = string.find(args, "=", 1, true)
    if (case_91_ == 1) then
      path = vim.trim(string.sub(args, 2))
    else
      local _ = case_91_
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
      local function _94_()
        return fh:read("*a")
      end
      local _96_
      do
        local t_95_ = _G
        if (nil ~= t_95_) then
          t_95_ = t_95_.package
        else
        end
        if (nil ~= t_95_) then
          t_95_ = t_95_.loaded
        else
        end
        if (nil ~= t_95_) then
          t_95_ = t_95_.fennel
        else
        end
        _96_ = t_95_
      end
      local or_100_ = _96_ or _G.debug
      if not or_100_ then
        local function _101_()
          return ""
        end
        or_100_ = {traceback = _101_}
      end
      file_contents = close_handlers_13_(_G.xpcall(_94_, or_100_.traceback))
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
    local function callback(_103_)
      local path = _103_.file
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
          local function _105_()
            return fh:read("*a")
          end
          local _107_
          do
            local t_106_ = _G
            if (nil ~= t_106_) then
              t_106_ = t_106_.package
            else
            end
            if (nil ~= t_106_) then
              t_106_ = t_106_.loaded
            else
            end
            if (nil ~= t_106_) then
              t_106_ = t_106_.fennel
            else
            end
            _107_ = t_106_
          end
          local or_111_ = _107_ or _G.debug
          if not or_111_ then
            local function _112_()
              return ""
            end
            or_111_ = {traceback = _112_}
          end
          file_contents = close_handlers_13_(_G.xpcall(_105_, or_111_.traceback))
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