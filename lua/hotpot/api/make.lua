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
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/api/make.fnl:11")
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
          local _16_ = f(path)
          if (_16_ == false) then
            files[path] = false
          else
            local function _17_()
              local path0 = _16_
              return string_3f(path0)
            end
            if ((nil ~= _16_) and _17_()) then
              local path0 = _16_
              files[path0] = string.gsub(path0, "%.fnl$", ".lua")
            elseif true then
              local _3fsome = _16_
              error(string.format("Invalid return value from build function: %s => %s", path, type(_3fsome)))
            else
            end
          end
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
  for _, _22_ in ipairs(spec) do
    local _each_23_ = _22_
    local glob = _each_23_[1]
    local action = _each_23_[2]
    assert(string.match(glob, "%.lua$"), string.format("clean glob patterns must end in .lua, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      if (nil == files[path]) then
        files[vim.fs.normalize(path)] = action
      else
      end
    end
  end
  for _, _25_ in ipairs(compile_targets) do
    local _each_26_ = _25_
    local dest = _each_26_["dest"]
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
  local _let_29_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_29_["compile-file"]
  local function _32_(_30_)
    local _arg_31_ = _30_
    local src = _arg_31_["src"]
    local dest = _arg_31_["dest"]
    local tmp_path = (vim.fn.tempname() .. ".lua")
    local relative_filename = string.sub(src, (2 + #root_dir))
    local _33_, _34_ = nil, nil
    local _36_
    do
      local _35_ = compiler_options.modules
      _35_["filename"] = relative_filename
      _36_ = _35_
    end
    _33_, _34_ = compile_file(src, tmp_path, _36_, compiler_options.macros, compiler_options.preprocessor)
    if (_33_ == true) then
      return {src = src, dest = dest, ["tmp-path"] = tmp_path, ["compiled?"] = true}
    elseif ((_33_ == false) and (nil ~= _34_)) then
      local e = _34_
      return {src = src, dest = dest, err = e, ["compiled?"] = false}
    else
      return nil
    end
  end
  return map(_32_, compile_targets)
end
local function report_compile_results(compile_results, _38_)
  local _arg_39_ = _38_
  local any_errors_3f = _arg_39_["any-errors?"]
  local verbose_3f = _arg_39_["verbose?"]
  local atomic_3f = _arg_39_["atomic?"]
  local dry_run_3f = _arg_39_["dry-run?"]
  local report = {}
  if dry_run_3f then
    table.insert(report, {"No changes were written to disk! Compiled with dryrun = true!\n", "DiagnosticWarn"})
  else
  end
  if (any_errors_3f and atomic_3f) then
    table.insert(report, {"No changes were written to disk! Compiled with atomic = true and some files had compilation errors!\n", "DiagnosticWarn"})
  else
  end
  local function _42_(_241)
    local _let_43_ = _241
    local compiled_3f = _let_43_["compiled?"]
    local src = _let_43_["src"]
    local dest = _let_43_["dest"]
    local function _45_()
      if (_241)["compiled?"] then
        return {"\226\152\145  ", "DiagnosticOK"}
      else
        return {"\226\152\146  ", "DiagnosticWarn"}
      end
    end
    local _let_44_ = _45_()
    local char = _let_44_[1]
    local level = _let_44_[2]
    table.insert(report, {string.format("%s%s\n", char, src), level})
    return table.insert(report, {string.format("-> %s\n", dest), level})
  end
  local function _48_(_46_)
    local _arg_47_ = _46_
    local compiled_3f = _arg_47_["compiled?"]
    return (verbose_3f or not compiled_3f)
  end
  map(_42_, filter(_48_, compile_results))
  local function _49_(_241)
    if ((_G.type(_241) == "table") and (nil ~= (_241).err)) then
      local err = (_241).err
      return table.insert(report, {err, "DiagnosticError"})
    else
      return nil
    end
  end
  map(_49_, compile_results)
  vim.api.nvim_echo(report, true, {})
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local root_dir0 = vim.fs.normalize(root_dir)
  local _let_51_ = opts
  local force_3f = _let_51_["force"]
  local verbose_3f = _let_51_["verbose"]
  local dry_run_3f = _let_51_["dryrun"]
  local atomic_3f = _let_51_["atomic"]
  local _let_52_ = require("hotpot.fs")
  local rm_file = _let_52_["rm-file"]
  local copy_file = _let_52_["copy-file"]
  local compiler_options = opts.compiler
  local _let_53_ = find_compile_targets(root_dir0, build_spec)
  local all_compile_targets = _let_53_["build"]
  local all_ignore_targets = _let_53_["ignore"]
  local force_3f0
  local function _54_()
    local _55_ = opts["infer-force-for-file"]
    if (nil ~= _55_) then
      local file = _55_
      local function _56_(_241)
        return (_241.src == file)
      end
      return any_3f(_56_, all_ignore_targets)
    elseif true then
      local _ = _55_
      return false
    else
      return nil
    end
  end
  force_3f0 = (force_3f or _54_())
  local focused_compile_target
  local function _60_(_58_)
    local _arg_59_ = _58_
    local src = _arg_59_["src"]
    local dest = _arg_59_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_60_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir0)
  local any_errors_3f
  local function _61_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_61_, compile_results)
  local function _64_(_62_)
    local _arg_63_ = _62_
    local tmp_path = _arg_63_["tmp-path"]
    local dest = _arg_63_["dest"]
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
  map(_64_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f})
  local _return
  do
    local tbl_14_auto = {}
    for _, _67_ in ipairs(all_compile_targets) do
      local _each_68_ = _67_
      local src = _each_68_["src"]
      local dest = _each_68_["dest"]
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
    for _, _70_ in ipairs(compile_results) do
      local _each_71_ = _70_
      local src = _each_71_["src"]
      local compiled_3f = _each_71_["compiled?"]
      local err = _each_71_["err"]
      local k_15_auto, v_16_auto = nil, nil
      local function _73_()
        local _72_ = _return[src]
        _72_["compiled?"] = compiled_3f
        _72_["err"] = err
        return _72_
      end
      k_15_auto, v_16_auto = src, _73_()
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
  local _let_76_ = require("hotpot.fs")
  local rm_file = _let_76_["rm-file"]
  for _, file in ipairs(clean_targets) do
    local _77_, _78_ = rm_file(file)
    if (_77_ == true) then
      vim.notify(string.format("rm %s", file), vim.log.levels.WARN)
    elseif ((_77_ == false) and (nil ~= _78_)) then
      local e = _78_
      vim.notify(string.format("Could not clean file %s, %s", file, e), vim.log.levels.ERROR)
    else
    end
  end
  return nil
end
M.build = function(...)
  local _80_ = {...}
  local function _81_(...)
    local root = (_80_)[1]
    local build_specs = (_80_)[2]
    return (string_3f(root) and table_3f(build_specs))
  end
  if (((_G.type(_80_) == "table") and (nil ~= (_80_)[1]) and (nil ~= (_80_)[2]) and ((_80_)[3] == nil)) and _81_(...)) then
    local root = (_80_)[1]
    local build_specs = (_80_)[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local function _82_(...)
      local root = (_80_)[1]
      local opts = (_80_)[2]
      local build_specs = (_80_)[3]
      return (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if (((_G.type(_80_) == "table") and (nil ~= (_80_)[1]) and (nil ~= (_80_)[2]) and (nil ~= (_80_)[3]) and ((_80_)[4] == nil)) and _82_(...)) then
      local root = (_80_)[1]
      local opts = (_80_)[2]
      local build_specs = (_80_)[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    elseif true then
      local _ = _80_
      return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
    else
      return nil
    end
  end
end
M.check = function(...)
  return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
end
do
  local function build_spec_or_default(given_spec)
    local default_spec = {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}}
    local function _85_()
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
    local _let_84_ = _85_()
    local spec = _let_84_[1]
    local opts = _let_84_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local function _86_()
        local t = clean_spec
        return table_3f(t)
      end
      if ((nil ~= clean_spec) and _86_()) then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir)
    if config.build then
      local function _88_(...)
        local _89_, _90_ = ...
        if ((_G.type(_89_) == "table") and (nil ~= (_89_)["build-spec"]) and (nil ~= (_89_)["build-options"])) then
          local build_spec = (_89_)["build-spec"]
          local build_options = (_89_)["build-options"]
          local function _91_(...)
            local _92_, _93_ = ...
            if (_92_ == true) then
              local function _94_(...)
                local _95_, _96_ = ...
                if true then
                  local _ = _95_
                  local function _97_(...)
                    local _98_, _99_ = ...
                    if true then
                      local _0 = _98_
                      local function _100_(...)
                        local _101_, _102_ = ...
                        if (nil ~= _101_) then
                          local compile_results = _101_
                          local function _103_(...)
                            local _104_, _105_ = ...
                            if (nil ~= _104_) then
                              local any_errors_3f = _104_
                              if (config.clean and not build_options.dryrun and (not build_options.atomic or (build_options.atomic and not any_errors_3f))) then
                                local function _106_(...)
                                  local _107_, _108_ = ...
                                  if (nil ~= _107_) then
                                    local clean_spec = _107_
                                    local function _109_(...)
                                      local _110_, _111_ = ...
                                      if (_110_ == true) then
                                        local function _112_(...)
                                          local _113_, _114_ = ...
                                          if (nil ~= _113_) then
                                            local clean_targets = _113_
                                            return do_clean(clean_targets, build_options)
                                          elseif ((_113_ == nil) and (nil ~= _114_)) then
                                            local e = _114_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _112_(find_clean_targets(root_dir, clean_spec, compile_results))
                                      elseif ((_110_ == nil) and (nil ~= _111_)) then
                                        local e = _111_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _109_(validate_spec("clean", clean_spec))
                                  elseif ((_107_ == nil) and (nil ~= _108_)) then
                                    local e = _108_
                                    return vim.notify(e, vim.log.levels.ERROR)
                                  else
                                    return nil
                                  end
                                end
                                return _106_(clean_spec_or_default(config.clean))
                              else
                                return nil
                              end
                            elseif ((_104_ == nil) and (nil ~= _105_)) then
                              local e = _105_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          local function _120_(_241)
                            return not _241["compiled?"]
                          end
                          return _103_(any_3f(_120_, compile_results))
                        elseif ((_101_ == nil) and (nil ~= _102_)) then
                          local e = _102_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      return _100_(M.build(root_dir, build_options, build_spec))
                    elseif ((_98_ == nil) and (nil ~= _99_)) then
                      local e = _99_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options.compiler = config.compiler
                  return _97_(nil)
                elseif ((_95_ == nil) and (nil ~= _96_)) then
                  local e = _96_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              build_options["infer-force-for-file"] = current_file
              return _94_(nil)
            elseif ((_92_ == nil) and (nil ~= _93_)) then
              local e = _93_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          return _91_(validate_spec("build", build_spec))
        elseif ((_89_ == nil) and (nil ~= _90_)) then
          local e = _90_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _88_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function attach(buf)
    if not (automake_memo["attached-buffers"])[buf] then
      automake_memo["attached-buffers"][buf] = true
      local function _127_()
        local _let_128_ = require("hotpot.runtime")
        local lookup_local_config = _let_128_["lookup-local-config"]
        local loadfile_local_config = _let_128_["loadfile-local-config"]
        local full_path_current_file = vim.fn.expand("<afile>:p")
        local function _129_(...)
          local _130_ = ...
          if (nil ~= _130_) then
            local config_path = _130_
            local function _131_(...)
              local _132_ = ...
              if (nil ~= _132_) then
                local config = _132_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              elseif true then
                local __75_auto = _132_
                return ...
              else
                return nil
              end
            end
            return _131_(loadfile_local_config(config_path))
          elseif true then
            local __75_auto = _130_
            return ...
          else
            return nil
          end
        end
        _129_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _127_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _136_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _136_})
    else
      return nil
    end
  end
  M.automake = {enable = enable}
end
return M