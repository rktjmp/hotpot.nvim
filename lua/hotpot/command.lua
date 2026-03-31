local _local_1_ = require("hotpot.util")
local R = _local_1_.R
local notify_info = _local_1_["notify-info"]
local notify_error = _local_1_["notify-error"]
local notify_warn = _local_1_["notify-warn"]
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
        local case_4_ = string.find(val, "%", 1, true)
        if (case_4_ == 1) then
          k_22_, v_23_ = key, vim.fn.expand(val)
        else
          local _0 = case_4_
          k_22_, v_23_ = key, val
        end
      elseif (case_2_ == nil) then
        local case_6_ = string.match(arg, "^([^=]+)=$")
        if (nil ~= case_6_) then
          local name = case_6_
          k_22_, v_23_ = error(string.format("Param error: gave key %s but no value assigned.", arg), 0)
        elseif (case_6_ == nil) then
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
  local case_10_, case_11_ = R.context.nearest(path)
  if (nil ~= case_10_) then
    local root = case_10_
    local function _12_(...)
      local case_13_, case_14_ = ...
      if ((case_13_ == true) and (nil ~= case_14_)) then
        local ctx = case_14_
        local function _15_(...)
          local case_16_, case_17_ = ...
          if ((case_16_ == true) and (nil ~= case_17_)) then
            local report = case_17_
            local case_18_, case_19_ = report, not opts["verbose?"]
            if (((_G.type(case_18_) == "table") and ((_G.type(case_18_.errors) == "table") and (case_18_.errors[1] == nil))) and (case_19_ == true)) then
              local msg = string.format("Synced %s", root)
              notify_info(msg)
              return nil
            else
              local _ = case_18_
              return nil
            end
          elseif ((case_16_ == false) and (nil ~= case_17_)) then
            local err = case_17_
            return notify_error(err)
          else
            return nil
          end
        end
        return _15_(pcall(R.context.sync, ctx, opts))
      elseif ((case_13_ == false) and (nil ~= case_14_)) then
        local err = case_14_
        return notify_error(err)
      else
        return nil
      end
    end
    return _12_(pcall(R.context.new, root))
  elseif ((case_10_ == nil) and (nil ~= case_11_)) then
    local err = case_11_
    return notify_error(err)
  else
    return nil
  end
end
local function hotpot_command_watch_handler(params)
  if ((_G.type(params) == "table") and (params.enable == true)) then
    R.autocmd.enable()
    return notify_info("Enabled Hotpot autocommand")
  elseif ((_G.type(params) == "table") and (params.disable == true)) then
    R.autocmd.disable()
    return notify_info("Disabled Hotpot autocommand")
  else
    local _ = params
    return vim.notify("Usage: Hotpot watch enable|disable")
  end
end
local function hotpot_command_fennel_rollback_handler(download_to_path, params)
  local case_25_ = vim.uv.fs_stat(download_to_path)
  if (_G.type(case_25_) == "table") then
    local case_26_, case_27_ = vim.uv.fs_unlink(download_to_path)
    if (case_26_ == true) then
      return notify_info("Removed downloaded Fennel, please restart Neovim.")
    elseif ((case_26_ == nil) and (nil ~= case_27_)) then
      local err = case_27_
      return notify_error("Unable to remove %s: %s", download_to_path, err)
    else
      return nil
    end
  elseif (case_25_ == nil) then
    return notify_error("Unable to rollback, nothing to remove")
  else
    return nil
  end
end
local function hotpot_command_fennel_version_handler(download_to_path, params)
  return notify_info("Fennel version: %s", R.fennel.version)
end
local function hotpot_command_fennel_update_handler(download_to_path, params)
  local function http_get(url)
    local curl_opts = "-sL"
    notify_info("Fetching %s...", url)
    return vim.fn.system(table.concat({"curl", curl_opts, url}, " "))
  end
  local function install_update(update_url)
    local source = http_get(update_url)
    local case_30_, case_31_ = loadstring(source)
    if (nil ~= case_30_) then
      local func = case_30_
      R.util["file-write"](download_to_path, source)
      return notify_info("Updated Fennel. You must restart Neovim.")
    elseif ((case_30_ == nil) and (nil ~= case_31_)) then
      local err = case_31_
      return notify_error("Invalid lua %s...", err)
    else
      return nil
    end
  end
  local function check_latest_online(force_3f)
    local url = "https://fennel-lang.org/downloads/"
    local index = http_get(url)
    local _ = notify_info("Finding latest version...")
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
    local function _34_(_241, _242)
      return (_241 > _242)
    end
    _0 = table.sort(versions, _34_)
    local installed_version = R.fennel.version
    if ((_G.type(versions) == "table") and (nil ~= versions[1])) then
      local latest = versions[1]
      local case_35_, case_36_ = string.match(latest, "fennel%-([0-9%.]+)%.lua")
      if (case_35_ == installed_version) then
        notify_info("Already at version %s", installed_version)
        return nil
      elseif (nil ~= case_35_) then
        local online_version = case_35_
        local final_url = (url .. latest)
        if force_3f then
          return final_url
        else
          local choices = {"Yes", "No"}
          local prompt = string.format("Download version %s?", online_version)
          local answer = {["ok?"] = false}
          local function _37_(_241)
            answer["ok?"] = _241
            return nil
          end
          R.ui["ui-select-sync"](choices, {prompt = prompt}, _37_)
          if (answer["ok?"] == "Yes") then
            return final_url
          else
            notify_info("Ok, doing nothing.")
            return nil
          end
        end
      else
        return nil
      end
    elseif ((_G.type(versions) == "table") and (versions[1] == nil)) then
      notify_error("Could not find any versions...")
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
    return notify_error("Unrecognised sub command")
  end
end
local function hotpot_command_handler(_44_)
  local fargs = _44_.fargs
  local command = fargs[1]
  local args = (function (t, k) return ((getmetatable(t) or {}).__fennelrest or function (t, k) return {(table.unpack or unpack)(t, k)} end)(t, k) end)(fargs, 2)
  local params, parse_error
  do
    local case_45_, case_46_ = pcall(parse_args, args)
    if ((case_45_ == true) and (nil ~= case_46_)) then
      local params0 = case_46_
      params, parse_error = params0
    elseif ((case_45_ == false) and (nil ~= case_46_)) then
      local err = case_46_
      params, parse_error = nil, err
    else
      params, parse_error = nil
    end
  end
  local usage
  local function _48_()
    return notify_warn("Usage: Hotpot sync|autocmd params...")
  end
  usage = _48_
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
    return notify_error(parse_error)
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
    _G.error("Missing argument current-param on fnl/hotpot/command.fnl:148", 2)
  else
  end
  if (nil == existing_params) then
    _G.error("Missing argument existing-params on fnl/hotpot/command.fnl:148", 2)
  else
  end
  if (nil == possible_params) then
    _G.error("Missing argument possible-params on fnl/hotpot/command.fnl:148", 2)
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
  local case_63_ = vim.split(cmd_line, "%s+")
  if ((_G.type(case_63_) == "table") and (case_63_[1] == "Hotpot") and (nil ~= case_63_[2]) and (case_63_[3] == nil)) then
    local current_partial = case_63_[2]
    return filter_param_options_no_duplicates({"sync", "watch", "fennel"}, {}, current_partial)
  elseif ((_G.type(case_63_) == "table") and (case_63_[1] == "Hotpot") and (case_63_[2] == "watch") and (nil ~= case_63_[3]) and (case_63_[4] == nil)) then
    local current_partial = case_63_[3]
    local function _64_()
      if R.autocmd["enabled?"] then
        return "disable"
      else
        return "enable"
      end
    end
    return filter_param_options_no_duplicates({_64_()}, {}, current_partial)
  elseif ((_G.type(case_63_) == "table") and (case_63_[1] == "Hotpot") and (case_63_[2] == "fennel")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_63_))}
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
  elseif ((_G.type(case_63_) == "table") and (case_63_[1] == "Hotpot") and (case_63_[2] == "sync")) then
    local current_params = {select(3, (table.unpack or _G.unpack)(case_63_))}
    local case_66_, case_67_ = string.find(arg_lead, "^context=")
    if (true and (nil ~= case_67_)) then
      local _start = case_66_
      local ends = case_67_
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
      local _ = case_66_
      local current_partial = table.remove(current_params)
      return filter_param_options_no_duplicates({"context=", "force", "verbose", "atomic"}, current_params, current_partial)
    end
  else
    return nil
  end
end
local function fetch_context(_3fpath)
  local try_path
  local function _71_(...)
    local case_72_ = ...
    if (case_72_ == nil) then
      local function _73_(...)
        local case_74_ = ...
        if (case_74_ == nil) then
          return vim.uv.cwd()
        elseif (nil ~= case_74_) then
          local path = case_74_
          return path
        else
          return nil
        end
      end
      return _73_(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)))
    elseif (nil ~= case_72_) then
      local path = case_72_
      return path
    else
      return nil
    end
  end
  try_path = _71_(vim.uv.fs_realpath((_3fpath or "")))
  return R.api.context(R.context.nearest(try_path))
end
local function make_ctx_action_handler(ctx, args)
  local function make(output)
    local function _77_(ok_3f, ...)
      if ok_3f then
        return output(...)
      else
        return notify_error(...)
      end
    end
    return _77_
  end
  local case_79_ = string.sub(args, 1, 2)
  if (case_79_ == "=") then
    local function _80_(source)
      return make(vim.print)(ctx.eval(source))
    end
    return _80_
  elseif (case_79_ == "-") then
    local function _81_(source)
      return make(vim.print)(ctx.compile(source))
    end
    return _81_
  else
    local _ = case_79_
    local function _82_(source)
      local function _83_()
        return nil
      end
      return make(_83_)(ctx.eval(source))
    end
    return _82_
  end
end
local function fnl_command_handler(_85_)
  local range = _85_.range
  local line1 = _85_.line1
  local line2 = _85_.line2
  local count = _85_.count
  local args = _85_.args
  local opts = _85_
  local ctx = fetch_context()
  local ctx_handler = make_ctx_action_handler(ctx, args)
  if ((args == "") or (args == "=") or (args == "-")) then
    local case_86_ = {range = range, line1 = line1, line2 = line2, count = count}
    if ((case_86_.range == 1) and (nil ~= case_86_.line1) and (case_86_.line1 == case_86_.line2) and (case_86_.line1 == case_86_.count)) then
      local n = case_86_.line1
      local from = vim.fn.line(".")
      local text = table.concat(vim.api.nvim_buf_get_lines(0, (from - 1), (from + count + -1), false), "\n")
      return ctx_handler(text)
    elseif ((case_86_.range == 2) and (nil ~= case_86_.line1) and (nil ~= case_86_.line2)) then
      local a = case_86_.line1
      local b = case_86_.line2
      local last_cmd = vim.fn.histget("cmd", -1)
      local case_87_ = string.find(last_cmd, "'<,'>", 1, true)
      if (case_87_ == 1) then
        local _let_88_ = vim.fn.getcharpos("'<")
        local _buf = _let_88_[1]
        local _line = _let_88_[2]
        local start_col = _let_88_[3]
        local _virt = _let_88_[4]
        local _let_89_ = vim.fn.getcharpos("'>")
        local _buf0 = _let_89_[1]
        local _line0 = _let_89_[2]
        local end_col = _let_89_[3]
        local _virt0 = _let_89_[4]
        local text = table.concat(vim.api.nvim_buf_get_text(0, (line1 - 1), (start_col - 1), (line2 - 1), (end_col - 0), {}), "\n")
        return ctx_handler(text)
      else
        local _ = case_87_
        local text = table.concat(vim.api.nvim_buf_get_lines(0, (line1 - 1), line2, false), "\n")
        return ctx_handler(text)
      end
    else
      return nil
    end
  else
    local _ = args
    local source = string.sub(args, 2)
    return ctx_handler(source)
  end
end
local function fnlfile_command_handler(_93_)
  local args = _93_.args
  local fargs = _93_.fargs
  local path
  do
    local case_94_ = string.find(args, "=", 1, true)
    if (case_94_ == 1) then
      path = vim.trim(string.sub(args, 2))
    else
      local _ = case_94_
      path = args
    end
  end
  if vim.uv.fs_access(path, "r") then
    local ctx = fetch_context(path)
    local ctx_handler = make_ctx_action_handler(ctx, args)
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
      local function _97_()
        return fh:read("*a")
      end
      local _99_
      do
        local t_98_ = _G
        if (nil ~= t_98_) then
          t_98_ = t_98_.package
        else
        end
        if (nil ~= t_98_) then
          t_98_ = t_98_.loaded
        else
        end
        if (nil ~= t_98_) then
          t_98_ = t_98_.fennel
        else
        end
        _99_ = t_98_
      end
      local or_103_ = _99_ or _G.debug
      if not or_103_ then
        local function _104_()
          return ""
        end
        or_103_ = {traceback = _104_}
      end
      file_contents = close_handlers_13_(_G.xpcall(_97_, or_103_.traceback))
    end
    return ctx_handler(file_contents)
  else
    return notify_error("Cant read file %s", path)
  end
end
local function define_hotpot()
  return vim.api.nvim_create_user_command("Hotpot", hotpot_command_handler, {nargs = "*", complete = hotpot_command_completion, desc = "Interact with Hotpot"})
end
local function define_fnl()
  return vim.api.nvim_create_user_command("Fnl", fnl_command_handler, {nargs = "*", range = true, desc = "Evaluate string of fnl or range, with = to print output"})
end
local function define_fnl_eval()
  local function _107_(_106_)
    local args = _106_.args
    local fargs = _106_.fargs
    local opts = _106_
    local case_108_ = string.find(args, "=", 1, true)
    if (case_108_ == 1) then
      return fnl_command_handler(opts)
    else
      local _ = case_108_
      local function _109_()
        opts["args"] = ("=" .. args)
        local _110_
        do
          table.insert(fargs, 1, "=")
          _110_ = fargs
        end
        opts["fargs"] = _110_
        return opts
      end
      return fnl_command_handler(_109_())
    end
  end
  return vim.api.nvim_create_user_command("FnlEval", _107_, {range = true, nargs = "*", desc = "Alias for :<range?>Fnl=`"})
end
local function define_fnl_compile()
  local function _113_(_112_)
    local args = _112_.args
    local fargs = _112_.fargs
    local opts = _112_
    local case_114_ = string.find(args, "-", 1, true)
    if (case_114_ == 1) then
      return fnl_command_handler(opts)
    else
      local _ = case_114_
      local function _115_()
        opts["args"] = ("-" .. args)
        local _116_
        do
          table.insert(fargs, 1, "-")
          _116_ = fargs
        end
        opts["fargs"] = _116_
        return opts
      end
      return fnl_command_handler(_115_())
    end
  end
  return vim.api.nvim_create_user_command("FnlCompile", _113_, {range = true, nargs = "*", desc = "Alias for :<range?>Fnl-`"})
end
local function define_fnlfile()
  return vim.api.nvim_create_user_command("Fnlfile", fnlfile_command_handler, {nargs = 1, complete = "file", desc = "Evaluate given fennel file"})
end
local _2aaugroup_id_2a = nil
local function support_source_command()
  if not _2aaugroup_id_2a then
    local augroup_id = vim.api.nvim_create_augroup("hotpot-source-cmd", {clear = true})
    local function callback(_118_)
      local path = _118_.file
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
          local function _120_()
            return fh:read("*a")
          end
          local _122_
          do
            local t_121_ = _G
            if (nil ~= t_121_) then
              t_121_ = t_121_.package
            else
            end
            if (nil ~= t_121_) then
              t_121_ = t_121_.loaded
            else
            end
            if (nil ~= t_121_) then
              t_121_ = t_121_.fennel
            else
            end
            _122_ = t_121_
          end
          local or_126_ = _122_ or _G.debug
          if not or_126_ then
            local function _127_()
              return ""
            end
            or_126_ = {traceback = _127_}
          end
          file_contents = close_handlers_13_(_G.xpcall(_120_, or_126_.traceback))
        end
        return ctx.eval(file_contents)
      else
        return notify_error("Cant read file %s", path)
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
  define_fnl_eval()
  define_fnl_compile()
  return support_source_command()
end
return {enable = define_commands}