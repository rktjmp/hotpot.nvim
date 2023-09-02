local _local_1_ = require("hotpot.common")
local table_3f = _local_1_["table?"]
local function_3f = _local_1_["function?"]
local boolean_3f = _local_1_["boolean?"]
local string_3f = _local_1_["string?"]
local nil_3f = _local_1_["nil?"]
local map = _local_1_["map"]
local filter = _local_1_["filter"]
local any_3f = _local_1_["any?"]
local none_3f = _local_1_["none?"]
local uv = vim.loop
local M = {}
local automake_memo = {augroup = nil, ["attached-buffers"] = {}}
local function merge_with_default_options(opts)
  _G.assert((nil ~= opts), "Missing argument opts on /home/soup/projects/personal/hotpot/master/fnl/hotpot/api/make.fnl:11")
  local _let_2_ = require("hotpot.runtime")
  local default_config = _let_2_["default-config"]
  local compiler_options = vim.tbl_extend("keep", (opts.compiler or {}), default_config().compiler)
  local opts0 = vim.tbl_extend("keep", opts, {atomic = false, dryrun = false, force = false, verbose = false})
  do end (opts0)["compiler"] = compiler_options
  if opts0.dryrun then
    opts0.verbose = true
  else
  end
  return opts0
end
local function validate_spec(kind, spec)
  local _4_
  do
    local ok = true
    for _, s in ipairs(spec) do
      if not (true == ok) then break end
      local function _5_()
        local pat = s[1]
        local act = s[2]
        return (string_3f(pat) and (boolean_3f(act) or function_3f(act)))
      end
      if (((_G.type(s) == "table") and (nil ~= s[1]) and (nil ~= s[2])) and _5_()) then
        local pat = s[1]
        local act = s[2]
        ok = true
      elseif true then
        local _0 = s
        ok = {false, string.format("Invalid pattern for %s: %s", kind, vim.inspect(s))}
      else
        ok = nil
      end
    end
    _4_ = ok
  end
  if (_4_ == true) then
    return true
  elseif ((_G.type(_4_) == "table") and ((_4_)[1] == false) and (nil ~= (_4_)[2])) then
    local e = (_4_)[2]
    return nil, e
  else
    return nil
  end
end
local function needs_compile_3f(src, dest)
  local _let_8_ = require("hotpot.fs")
  local file_missing_3f = _let_8_["file-missing?"]
  local file_stat = _let_8_["file-stat"]
  local function _11_()
    local _let_9_ = file_stat(src)
    local smtime = _let_9_["mtime"]
    local _let_10_ = file_stat(dest)
    local dmtime = _let_10_["mtime"]
    return (dmtime.sec < smtime.sec)
  end
  return (file_missing_3f(dest) or _11_())
end
local function find_compile_targets(root_dir, spec)
  local files = {}
  local split = {build = {}, ignore = {}}
  for _, _12_ in ipairs(spec) do
    local _each_13_ = _12_
    local glob = _each_13_[1]
    local action = _each_13_[2]
    assert(string.match(glob, "%.fnl$"), string.format("build glob patterns must end in .fnl, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      if (nil == files[path]) then
        local _14_ = {string.find(glob, "fnl/"), action}
        local function _15_()
          local _1 = (_14_)[1]
          local f = (_14_)[2]
          return function_3f(f)
        end
        if (((_G.type(_14_) == "table") and true and (nil ~= (_14_)[2])) and _15_()) then
          local _1 = (_14_)[1]
          local f = (_14_)[2]
          files[path] = f(path)
        elseif ((_G.type(_14_) == "table") and true and ((_14_)[2] == false)) then
          local _1 = (_14_)[1]
          files[path] = false
        elseif ((_G.type(_14_) == "table") and ((_14_)[1] == 1) and ((_14_)[2] == true)) then
          files[path] = (root_dir .. "/lua/" .. string.sub(path, (#root_dir + 6), -4) .. "lua")
        elseif ((_G.type(_14_) == "table") and true and ((_14_)[2] == true)) then
          local _1 = (_14_)[1]
          files[path] = (string.sub(path, 1, -4) .. "lua")
        else
        end
      else
      end
    end
  end
  for path, action in pairs(files) do
    if action then
      table.insert(split.build, {src = vim.fs.normalize(path), dest = vim.fs.normalize(action)})
    else
      table.insert(split.ignore, {src = vim.fs.normalize(path)})
    end
  end
  return split
end
local function find_clean_targets(root_dir, spec, compile_targets)
  local files = {}
  for _, _19_ in ipairs(spec) do
    local _each_20_ = _19_
    local glob = _each_20_[1]
    local action = _each_20_[2]
    assert(string.match(glob, "%.lua$"), string.format("clean glob patterns must end in .lua, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      if (nil == files[path]) then
        files[path] = action
      else
      end
    end
  end
  for _, _22_ in ipairs(compile_targets) do
    local _each_23_ = _22_
    local dest = _each_23_["dest"]
    files[dest] = false
  end
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for path, action in pairs(files) do
    local val_19_auto
    if action then
      val_19_auto = path
    else
      val_19_auto = nil
    end
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function do_compile(compile_targets, compiler_options, root_dir)
  local _let_26_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_26_["compile-file"]
  local function _29_(_27_)
    local _arg_28_ = _27_
    local src = _arg_28_["src"]
    local dest = _arg_28_["dest"]
    local tmp_path = (vim.fn.tempname() .. ".lua")
    local relative_filename = string.sub(src, (2 + #root_dir))
    local _30_, _31_ = nil, nil
    local _33_
    do
      local _32_ = compiler_options.modules
      _32_["filename"] = relative_filename
      _33_ = _32_
    end
    _30_, _31_ = compile_file(src, tmp_path, _33_, compiler_options.macros, compiler_options.preprocessor)
    if (_30_ == true) then
      return {src = src, dest = dest, ["tmp-path"] = tmp_path, ["compiled?"] = true}
    elseif ((_30_ == false) and (nil ~= _31_)) then
      local e = _31_
      return {src = src, dest = dest, err = e, ["compiled?"] = false}
    else
      return nil
    end
  end
  return map(_29_, compile_targets)
end
local function report_compile_results(compile_results, _35_)
  local _arg_36_ = _35_
  local any_errors_3f = _arg_36_["any-errors?"]
  local verbose_3f = _arg_36_["verbose?"]
  local atomic_3f = _arg_36_["atomic?"]
  local dry_run_3f = _arg_36_["dry-run?"]
  if dry_run_3f then
    vim.notify("No changes were written to disk! Compiled with dryrun = true!", vim.log.levels.WARN)
  else
  end
  if (any_errors_3f and atomic_3f) then
    vim.notify("No changes were written to disk! Compiled with atomic = true and some files had compilation errors!", vim.log.levels.WARN)
  else
  end
  local function _39_(_241)
    local _let_40_ = _241
    local compiled_3f = _let_40_["compiled?"]
    local src = _let_40_["src"]
    local dest = _let_40_["dest"]
    local function _42_()
      if (_241)["compiled?"] then
        return {"\226\152\145  ", vim.log.levels.TRACE}
      else
        return {"\226\152\146  ", vim.log.levels.WARN}
      end
    end
    local _let_41_ = _42_()
    local char = _let_41_[1]
    local level = _let_41_[2]
    return vim.notify(string.format("%s%s\n-> %s", char, src, dest), level)
  end
  local function _45_(_43_)
    local _arg_44_ = _43_
    local compiled_3f = _arg_44_["compiled?"]
    return (verbose_3f or not compiled_3f)
  end
  map(_39_, filter(_45_, compile_results))
  local function _46_(_241)
    if ((_G.type(_241) == "table") and (nil ~= (_241).err)) then
      local err = (_241).err
      return vim.notify(err, vim.log.levels.WARN)
    else
      return nil
    end
  end
  map(_46_, compile_results)
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local _let_48_ = opts
  local force_3f = _let_48_["force"]
  local verbose_3f = _let_48_["verbose"]
  local dry_run_3f = _let_48_["dryrun"]
  local atomic_3f = _let_48_["atomic"]
  local _let_49_ = require("hotpot.fs")
  local rm_file = _let_49_["rm-file"]
  local copy_file = _let_49_["copy-file"]
  local compiler_options = opts.compiler
  local _let_50_ = find_compile_targets(root_dir, build_spec)
  local all_compile_targets = _let_50_["build"]
  local all_ignore_targets = _let_50_["ignore"]
  local force_3f0
  local function _51_()
    local _52_ = opts["infer-force-for-file"]
    if (nil ~= _52_) then
      local file = _52_
      local function _53_(_241)
        return (_241.src == file)
      end
      return any_3f(_53_, all_ignore_targets)
    elseif true then
      local _ = _52_
      return false
    else
      return nil
    end
  end
  force_3f0 = (force_3f or _51_())
  local focused_compile_target
  local function _57_(_55_)
    local _arg_56_ = _55_
    local src = _arg_56_["src"]
    local dest = _arg_56_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_57_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir)
  local any_errors_3f
  local function _58_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_58_, compile_results)
  local function _61_(_59_)
    local _arg_60_ = _59_
    local tmp_path = _arg_60_["tmp-path"]
    local dest = _arg_60_["dest"]
    if tmp_path then
      if (not dry_run_3f and (not atomic_3f or not any_errors_3f)) then
        copy_file(tmp_path, dest)
      else
      end
      return rm_file(tmp_path)
    else
      return nil
    end
  end
  map(_61_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f})
  local _return
  do
    local tbl_14_auto = {}
    for _, _64_ in ipairs(all_compile_targets) do
      local _each_65_ = _64_
      local src = _each_65_["src"]
      local dest = _each_65_["dest"]
      local k_15_auto, v_16_auto = src, {src = src, dest = dest}
      if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
        tbl_14_auto[k_15_auto] = v_16_auto
      else
      end
    end
    _return = tbl_14_auto
  end
  local _return0
  do
    local tbl_14_auto = _return
    for _, _67_ in ipairs(compile_results) do
      local _each_68_ = _67_
      local src = _each_68_["src"]
      local compiled_3f = _each_68_["compiled?"]
      local err = _each_68_["err"]
      local k_15_auto, v_16_auto = nil, nil
      local function _70_()
        local _69_ = _return[src]
        _69_["compiled?"] = compiled_3f
        _69_["err"] = err
        return _69_
      end
      k_15_auto, v_16_auto = src, _70_()
      if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
        tbl_14_auto[k_15_auto] = v_16_auto
      else
      end
    end
    _return0 = tbl_14_auto
  end
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, v in pairs(_return0) do
    local val_19_auto = v
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function do_clean(clean_targets, opts)
  local _let_73_ = require("hotpot.fs")
  local rm_file = _let_73_["rm-file"]
  for _, file in ipairs(clean_targets) do
    local _74_, _75_ = rm_file(file)
    if (_74_ == true) then
      vim.notify(string.format("rm %s", file), vim.log.levels.WARN)
    elseif ((_74_ == false) and (nil ~= _75_)) then
      local e = _75_
      vim.notify(string.format("Could not clean file %s, %s", file, e), vim.log.levels.ERROR)
    else
    end
  end
  return nil
end
M.build = function(...)
  local _77_ = {...}
  local function _78_(...)
    local root = (_77_)[1]
    local build_specs = (_77_)[2]
    return (string_3f(root) and table_3f(build_specs))
  end
  if (((_G.type(_77_) == "table") and (nil ~= (_77_)[1]) and (nil ~= (_77_)[2]) and ((_77_)[3] == nil)) and _78_(...)) then
    local root = (_77_)[1]
    local build_specs = (_77_)[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local function _79_(...)
      local root = (_77_)[1]
      local opts = (_77_)[2]
      local build_specs = (_77_)[3]
      return (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if (((_G.type(_77_) == "table") and (nil ~= (_77_)[1]) and (nil ~= (_77_)[2]) and (nil ~= (_77_)[3]) and ((_77_)[4] == nil)) and _79_(...)) then
      local root = (_77_)[1]
      local opts = (_77_)[2]
      local build_specs = (_77_)[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    elseif true then
      local _ = _77_
      return vim.notify(("The hotpot.api.make usage has changed, please see :h hotpot-dot-hotpot\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
    else
      return nil
    end
  end
end
M.check = function(...)
  return vim.notify(("The hotpot.api.make usage has changed, please see :h hotpot-dot-hotpot\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
end
do
  local function build_spec_or_default(given_spec)
    local default_spec = {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}}
    local function _82_()
      if (given_spec == true) then
        return {default_spec, {}}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and ((given_spec[1])[1] == nil)) and (given_spec[2] == nil)) then
        local opts = given_spec[1]
        return {default_spec, opts}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and ((given_spec[1])[1] == nil))) then
        local opts = given_spec[1]
        local spec = {select(2, (table.unpack or _G.unpack)(given_spec))}
        return {spec, opts}
      elseif (nil ~= given_spec) then
        local spec = given_spec
        return {spec, {}}
      else
        return nil
      end
    end
    local _let_81_ = _82_()
    local spec = _let_81_[1]
    local opts = _let_81_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local function _83_()
        local t = clean_spec
        return table_3f(t)
      end
      if ((nil ~= clean_spec) and _83_()) then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir)
    if config.build then
      local function _85_(...)
        local _86_, _87_ = ...
        if ((_G.type(_86_) == "table") and (nil ~= (_86_)["build-spec"]) and (nil ~= (_86_)["build-options"])) then
          local build_spec = (_86_)["build-spec"]
          local build_options = (_86_)["build-options"]
          local function _88_(...)
            local _89_, _90_ = ...
            if (_89_ == true) then
              local function _91_(...)
                local _92_, _93_ = ...
                if true then
                  local _ = _92_
                  local function _94_(...)
                    local _95_, _96_ = ...
                    if true then
                      local _0 = _95_
                      local function _97_(...)
                        local _98_, _99_ = ...
                        if (nil ~= _98_) then
                          local compile_results = _98_
                          local function _100_(...)
                            local _101_, _102_ = ...
                            if (nil ~= _101_) then
                              local any_errors_3f = _101_
                              if (config.clean and not build_options.dryrun and (not build_options.atomic or (build_options.atomic and not any_errors_3f))) then
                                local function _103_(...)
                                  local _104_, _105_ = ...
                                  if (nil ~= _104_) then
                                    local clean_spec = _104_
                                    local function _106_(...)
                                      local _107_, _108_ = ...
                                      if (_107_ == true) then
                                        local function _109_(...)
                                          local _110_, _111_ = ...
                                          if (nil ~= _110_) then
                                            local clean_targets = _110_
                                            return do_clean(clean_targets, build_options)
                                          elseif ((_110_ == nil) and (nil ~= _111_)) then
                                            local e = _111_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _109_(find_clean_targets(root_dir, clean_spec, compile_results))
                                      elseif ((_107_ == nil) and (nil ~= _108_)) then
                                        local e = _108_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _106_(validate_spec("clean", clean_spec))
                                  elseif ((_104_ == nil) and (nil ~= _105_)) then
                                    local e = _105_
                                    return vim.notify(e, vim.log.levels.ERROR)
                                  else
                                    return nil
                                  end
                                end
                                return _103_(clean_spec_or_default(config.clean))
                              else
                                return nil
                              end
                            elseif ((_101_ == nil) and (nil ~= _102_)) then
                              local e = _102_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          local function _117_(_241)
                            return not _241["compiled?"]
                          end
                          return _100_(any_3f(_117_, compile_results))
                        elseif ((_98_ == nil) and (nil ~= _99_)) then
                          local e = _99_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      return _97_(M.build(root_dir, build_options, build_spec))
                    elseif ((_95_ == nil) and (nil ~= _96_)) then
                      local e = _96_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options.compiler = config.compiler
                  return _94_(nil)
                elseif ((_92_ == nil) and (nil ~= _93_)) then
                  local e = _93_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              build_options["infer-force-for-file"] = current_file
              return _91_(nil)
            elseif ((_89_ == nil) and (nil ~= _90_)) then
              local e = _90_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          return _88_(validate_spec("build", build_spec))
        elseif ((_86_ == nil) and (nil ~= _87_)) then
          local e = _87_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _85_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function attach(buf)
    if not (automake_memo["attached-buffers"])[buf] then
      automake_memo["attached-buffers"][buf] = true
      local function _124_()
        local _let_125_ = require("hotpot.runtime")
        local lookup_local_config = _let_125_["lookup-local-config"]
        local loadfile_local_config = _let_125_["loadfile-local-config"]
        local full_path_current_file = vim.fn.expand("<afile>:p")
        local function _126_(...)
          local _127_ = ...
          if (nil ~= _127_) then
            local config_path = _127_
            local function _128_(...)
              local _129_ = ...
              if (nil ~= _129_) then
                local config = _129_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              elseif true then
                local __75_auto = _129_
                return ...
              else
                return nil
              end
            end
            return _128_(loadfile_local_config(config_path))
          elseif true then
            local __75_auto = _127_
            return ...
          else
            return nil
          end
        end
        _126_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _124_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _133_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _133_})
    else
      return nil
    end
  end
  M.automake = {enable = enable}
end
return M