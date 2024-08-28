local _local_1_ = require("hotpot.common")
local table_3f = _local_1_["table?"]
local function_3f = _local_1_["function?"]
local boolean_3f = _local_1_["boolean?"]
local string_3f = _local_1_["string?"]
local nil_3f = _local_1_["nil?"]
local map = _local_1_["map"]
local reduce = _local_1_["reduce"]
local filter = _local_1_["filter"]
local any_3f = _local_1_["any?"]
local none_3f = _local_1_["none?"]
local uv = vim.loop
local M = {}
local automake_memo = {augroup = nil, ["attached-buffers"] = {}}
local function ns__3ems(ns)
  return math.floor((ns / 1000000))
end
local function merge_with_default_options(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/api/make.fnl:13")
  local _let_2_ = require("hotpot.runtime")
  local default_config = _let_2_["default-config"]
  local compiler_options = vim.tbl_extend("keep", (opts.compiler or {}), default_config().compiler)
  local opts0 = vim.tbl_extend("keep", opts, {atomic = false, dryrun = false, force = false, verbose = false})
  opts0["compiler"] = compiler_options
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
      local and_5_ = ((_G.type(s) == "table") and (nil ~= s[1]) and (nil ~= s[2]))
      if and_5_ then
        local pat = s[1]
        local act = s[2]
        and_5_ = (string_3f(pat) and (boolean_3f(act) or function_3f(act)))
      end
      if and_5_ then
        local pat = s[1]
        local act = s[2]
        ok = true
      else
        local _0 = s
        ok = {false, string.format("Invalid pattern for %s: %s", kind, vim.inspect(s))}
      end
    end
    _4_ = ok
  end
  if (_4_ == true) then
    return true
  elseif ((_G.type(_4_) == "table") and (_4_[1] == false) and (nil ~= _4_[2])) then
    local e = _4_[2]
    return nil, e
  else
    return nil
  end
end
local function needs_compile_3f(src, dest)
  local _let_9_ = require("hotpot.fs")
  local file_missing_3f = _let_9_["file-missing?"]
  local file_stat = _let_9_["file-stat"]
  local or_10_ = file_missing_3f(dest)
  if not or_10_ then
    local _let_12_ = file_stat(src)
    local smtime = _let_12_["mtime"]
    local _let_13_ = file_stat(dest)
    local dmtime = _let_13_["mtime"]
    or_10_ = (dmtime.sec < smtime.sec)
  end
  return or_10_
end
local function find_compile_targets(root_dir, spec)
  local files = {}
  local begin_search_at = uv.hrtime()
  local split = {build = {}, ignore = {}, ["time-ns"] = nil}
  for _, _14_ in ipairs(spec) do
    local glob = _14_[1]
    local action = _14_[2]
    assert(string.match(glob, "%.fnl$"), string.format("build glob patterns must end in .fnl, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      local path0 = vim.fs.normalize(path)
      if (nil == files[path0]) then
        local _15_ = {string.find(glob, "fnl/"), action}
        local and_16_ = ((_G.type(_15_) == "table") and true and (nil ~= _15_[2]))
        if and_16_ then
          local _1 = _15_[1]
          local f = _15_[2]
          and_16_ = function_3f(f)
        end
        if and_16_ then
          local _1 = _15_[1]
          local f = _15_[2]
          local _18_ = f(path0)
          if (_18_ == false) then
            files[path0] = false
          else
            local and_19_ = (nil ~= _18_)
            if and_19_ then
              local dest_path = _18_
              and_19_ = string_3f(dest_path)
            end
            if and_19_ then
              local dest_path = _18_
              files[path0] = string.gsub(vim.fs.normalize(dest_path), "%.fnl$", ".lua")
            else
              local _3fsome = _18_
              error(string.format("Invalid return value from build function: %s => %s", path0, type(_3fsome)))
            end
          end
        elseif (true and (_15_[2] == false)) then
          local _1 = _15_[1]
          files[path0] = false
        elseif ((_15_[1] == 1) and (_15_[2] == true)) then
          files[path0] = (root_dir .. "/lua/" .. string.sub(path0, (#root_dir + 6), -4) .. "lua")
        elseif (true and (_15_[2] == true)) then
          local _1 = _15_[1]
          files[path0] = (string.sub(path0, 1, -4) .. "lua")
        else
        end
      else
      end
    end
  end
  for path, action in pairs(files) do
    if action then
      table.insert(split.build, {src = path, dest = vim.fs.normalize(action)})
    else
      table.insert(split.ignore, {src = path})
    end
  end
  split["time-ns"] = (uv.hrtime() - begin_search_at)
  return split
end
local function find_clean_targets(root_dir, spec, compile_targets)
  local files = {}
  for _, _25_ in ipairs(spec) do
    local glob = _25_[1]
    local action = _25_[2]
    assert(string.match(glob, "%.lua$"), string.format("clean glob patterns must end in .lua, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      if (nil == files[path]) then
        files[vim.fs.normalize(path)] = action
      else
      end
    end
  end
  for _, _27_ in ipairs(compile_targets) do
    local dest = _27_["dest"]
    files[dest] = false
  end
  local tbl_21_auto = {}
  local i_22_auto = 0
  for path, action in pairs(files) do
    local val_23_auto
    if action then
      val_23_auto = path
    else
      val_23_auto = nil
    end
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
end
local function do_compile(compile_targets, compiler_options, root_dir)
  local _let_30_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_30_["compile-file"]
  do
    local _31_ = package.loaded
    if ((_G.type(_31_) == "table") and (nil ~= _31_["hotpot.fennel"])) then
      local fennel = _31_["hotpot.fennel"]
      for k, _ in pairs(fennel["macro-loaded"]) do
        fennel["macro-loaded"][k] = nil
      end
    else
    end
  end
  local function _34_(_33_)
    local src = _33_["src"]
    local dest = _33_["dest"]
    local tmp_path = (vim.fn.tempname() .. ".lua")
    local relative_filename = string.sub(src, (2 + #root_dir))
    local begin_compile_at = uv.hrtime()
    local _35_, _36_ = nil, nil
    local _37_
    do
      local tmp_9_auto = compiler_options.modules
      tmp_9_auto["filename"] = relative_filename
      _37_ = tmp_9_auto
    end
    _35_, _36_ = compile_file(src, tmp_path, _37_, compiler_options.macros, compiler_options.preprocessor)
    if (_35_ == true) then
      return {src = src, dest = dest, ["tmp-path"] = tmp_path, ["compiled?"] = true, ["time-ns"] = (uv.hrtime() - begin_compile_at)}
    elseif ((_35_ == false) and (nil ~= _36_)) then
      local e = _36_
      return {src = src, dest = dest, ["time-ns"] = (uv.hrtime() - begin_compile_at), err = e, ["compiled?"] = false}
    else
      return nil
    end
  end
  return map(_34_, compile_targets)
end
local function report_compile_results(compile_results, _39_)
  local any_errors_3f = _39_["any-errors?"]
  local verbose_3f = _39_["verbose?"]
  local atomic_3f = _39_["atomic?"]
  local dry_run_3f = _39_["dry-run?"]
  local find_time_ns = _39_["find-time-ns"]
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
    local compiled_3f = _241["compiled?"]
    local src = _241["src"]
    local dest = _241["dest"]
    local time_ns = _241["time-ns"]
    local function _43_()
      if _241["compiled?"] then
        return {"\226\152\145  ", "DiagnosticOK"}
      else
        return {"\226\152\146  ", "DiagnosticWarn"}
      end
    end
    local _let_44_ = _43_()
    local char = _let_44_[1]
    local level = _let_44_[2]
    table.insert(report, {string.format("%s%s\n", char, src), level})
    return table.insert(report, {string.format("-> %s (%sms)\n", dest, ns__3ems(time_ns)), level})
  end
  local function _46_(_45_)
    local compiled_3f = _45_["compiled?"]
    return (verbose_3f or not compiled_3f)
  end
  map(_42_, filter(_46_, compile_results))
  if verbose_3f then
    local function _48_(sum, _47_)
      local time_ns = _47_["time-ns"]
      return (sum + time_ns)
    end
    local function _50_(_49_)
      local compiled_3f = _49_["compiled?"]
      return compiled_3f
    end
    table.insert(report, {string.format("Disk: %sms Compile: %sms\n", ns__3ems(find_time_ns), ns__3ems(reduce(_48_, 0, filter(_50_, compile_results)))), "DiagnosticInfo"})
  else
  end
  local function _52_(_241)
    if ((_G.type(_241) == "table") and (nil ~= _241.err)) then
      local err = _241.err
      return table.insert(report, {err, "DiagnosticError"})
    else
      return nil
    end
  end
  map(_52_, compile_results)
  if (0 < #report) then
    vim.api.nvim_echo(report, true, {})
  else
  end
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local root_dir0 = vim.fs.normalize(root_dir)
  local force_3f = opts["force"]
  local verbose_3f = opts["verbose"]
  local dry_run_3f = opts["dryrun"]
  local atomic_3f = opts["atomic"]
  local _let_55_ = require("hotpot.fs")
  local rm_file = _let_55_["rm-file"]
  local copy_file = _let_55_["copy-file"]
  local compiler_options = opts.compiler
  local _let_56_ = find_compile_targets(root_dir0, build_spec)
  local all_compile_targets = _let_56_["build"]
  local all_ignore_targets = _let_56_["ignore"]
  local find_time_ns = _let_56_["time-ns"]
  local force_3f0
  local or_57_ = force_3f
  if not or_57_ then
    local _58_ = opts["infer-force-for-file"]
    if (nil ~= _58_) then
      local file = _58_
      local function _61_(_241)
        return (_241.src == file)
      end
      or_57_ = any_3f(_61_, all_ignore_targets)
    else
      local _ = _58_
      or_57_ = false
    end
  end
  force_3f0 = or_57_
  local focused_compile_target
  local function _65_(_64_)
    local src = _64_["src"]
    local dest = _64_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_65_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir0)
  local any_errors_3f
  local function _66_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_66_, compile_results)
  local function _68_(_67_)
    local tmp_path = _67_["tmp-path"]
    local dest = _67_["dest"]
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
  map(_68_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f, ["find-time-ns"] = find_time_ns})
  local _return
  do
    local tbl_16_auto = {}
    for _, _71_ in ipairs(all_compile_targets) do
      local src = _71_["src"]
      local dest = _71_["dest"]
      local k_17_auto, v_18_auto = src, {src = src, dest = dest}
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    _return = tbl_16_auto
  end
  local _return0
  do
    local tbl_16_auto = _return
    for _, _73_ in ipairs(compile_results) do
      local src = _73_["src"]
      local compiled_3f = _73_["compiled?"]
      local err = _73_["err"]
      local k_17_auto, v_18_auto = nil, nil
      local function _74_()
        local tmp_9_auto = _return[src]
        tmp_9_auto["compiled?"] = compiled_3f
        tmp_9_auto["err"] = err
        return tmp_9_auto
      end
      k_17_auto, v_18_auto = src, _74_()
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    _return0 = tbl_16_auto
  end
  local tbl_21_auto = {}
  local i_22_auto = 0
  for _, v in pairs(_return0) do
    local val_23_auto = v
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
end
local function do_clean(clean_targets, opts)
  local _let_77_ = require("hotpot.fs")
  local rm_file = _let_77_["rm-file"]
  for _, file in ipairs(clean_targets) do
    local _78_, _79_ = rm_file(file)
    if (_78_ == true) then
      vim.notify(string.format("rm %s", file), vim.log.levels.WARN)
    elseif ((_78_ == false) and (nil ~= _79_)) then
      local e = _79_
      vim.notify(string.format("Could not clean file %s, %s", file, e), vim.log.levels.ERROR)
    else
    end
  end
  return nil
end
M.build = function(...)
  local _81_ = {...}
  local and_82_ = ((_G.type(_81_) == "table") and (nil ~= _81_[1]) and (nil ~= _81_[2]) and (_81_[3] == nil))
  if and_82_ then
    local root = _81_[1]
    local build_specs = _81_[2]
    and_82_ = (string_3f(root) and table_3f(build_specs))
  end
  if and_82_ then
    local root = _81_[1]
    local build_specs = _81_[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local and_84_ = ((_G.type(_81_) == "table") and (nil ~= _81_[1]) and (nil ~= _81_[2]) and (nil ~= _81_[3]) and (_81_[4] == nil))
    if and_84_ then
      local root = _81_[1]
      local opts = _81_[2]
      local build_specs = _81_[3]
      and_84_ = (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if and_84_ then
      local root = _81_[1]
      local opts = _81_[2]
      local build_specs = _81_[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    else
      local _ = _81_
      return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
    end
  end
end
M.check = function(...)
  return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
end
do
  local function build_spec_or_default(given_spec)
    local default_spec = {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}}
    local function _87_()
      if (given_spec == true) then
        return {default_spec, {}}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and (given_spec[1][1] == nil)) and (given_spec[2] == nil)) then
        local opts = given_spec[1]
        return {default_spec, opts}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and (given_spec[1][1] == nil))) then
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
    local _let_88_ = _87_()
    local spec = _let_88_[1]
    local opts = _let_88_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local and_89_ = (nil ~= clean_spec)
      if and_89_ then
        local t = clean_spec
        and_89_ = table_3f(t)
      end
      if and_89_ then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir, _3fmanual_opts)
    if config.build then
      local function _92_(...)
        local _93_, _94_ = ...
        if ((_G.type(_93_) == "table") and (nil ~= _93_["build-spec"]) and (nil ~= _93_["build-options"])) then
          local build_spec = _93_["build-spec"]
          local build_options = _93_["build-options"]
          local function _95_(...)
            local _96_, _97_ = ...
            if (nil ~= _96_) then
              local build_options0 = _96_
              local function _98_(...)
                local _99_, _100_ = ...
                if (_99_ == true) then
                  local function _101_(...)
                    local _102_, _103_ = ...
                    if true then
                      local _ = _102_
                      local function _104_(...)
                        local _105_, _106_ = ...
                        if true then
                          local _0 = _105_
                          local function _107_(...)
                            local _108_, _109_ = ...
                            if (nil ~= _108_) then
                              local compile_results = _108_
                              local function _110_(...)
                                local _111_, _112_ = ...
                                if (nil ~= _111_) then
                                  local any_errors_3f = _111_
                                  if (config.clean and not build_options0.dryrun and (not build_options0.atomic or (build_options0.atomic and not any_errors_3f))) then
                                    local function _113_(...)
                                      local _114_, _115_ = ...
                                      if (nil ~= _114_) then
                                        local clean_spec = _114_
                                        local function _116_(...)
                                          local _117_, _118_ = ...
                                          if (_117_ == true) then
                                            local function _119_(...)
                                              local _120_, _121_ = ...
                                              if (nil ~= _120_) then
                                                local clean_targets = _120_
                                                local function _122_(...)
                                                  local _123_, _124_ = ...
                                                  if true then
                                                    local _1 = _123_
                                                    return compile_results
                                                  elseif ((_123_ == nil) and (nil ~= _124_)) then
                                                    local e = _124_
                                                    return vim.notify(e, vim.log.levels.ERROR)
                                                  else
                                                    return nil
                                                  end
                                                end
                                                return _122_(do_clean(clean_targets, build_options0))
                                              elseif ((_120_ == nil) and (nil ~= _121_)) then
                                                local e = _121_
                                                return vim.notify(e, vim.log.levels.ERROR)
                                              else
                                                return nil
                                              end
                                            end
                                            return _119_(find_clean_targets(root_dir, clean_spec, compile_results))
                                          elseif ((_117_ == nil) and (nil ~= _118_)) then
                                            local e = _118_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _116_(validate_spec("clean", clean_spec))
                                      elseif ((_114_ == nil) and (nil ~= _115_)) then
                                        local e = _115_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _113_(clean_spec_or_default(config.clean))
                                  else
                                    return compile_results
                                  end
                                elseif ((_111_ == nil) and (nil ~= _112_)) then
                                  local e = _112_
                                  return vim.notify(e, vim.log.levels.ERROR)
                                else
                                  return nil
                                end
                              end
                              local function _131_(_241)
                                return _241["err?"]
                              end
                              return _110_(any_3f(_131_, compile_results))
                            elseif ((_108_ == nil) and (nil ~= _109_)) then
                              local e = _109_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          return _107_(M.build(root_dir, build_options0, build_spec))
                        elseif ((_105_ == nil) and (nil ~= _106_)) then
                          local e = _106_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      build_options0.compiler = config.compiler
                      return _104_(nil)
                    elseif ((_102_ == nil) and (nil ~= _103_)) then
                      local e = _103_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options0["infer-force-for-file"] = current_file
                  return _101_(nil)
                elseif ((_99_ == nil) and (nil ~= _100_)) then
                  local e = _100_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              return _98_(validate_spec("build", build_spec))
            elseif ((_96_ == nil) and (nil ~= _97_)) then
              local e = _97_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          local function _137_(...)
            if _3fmanual_opts then
              return vim.tbl_extend("force", build_options, _3fmanual_opts)
            else
              return build_options
            end
          end
          return _95_(_137_(...))
        elseif ((_93_ == nil) and (nil ~= _94_)) then
          local e = _94_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _92_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function build(file_dir_or_dot_hotpot, _3fopts)
    local _let_140_ = require("hotpot.runtime")
    local lookup_local_config = _let_140_["lookup-local-config"]
    local loadfile_local_config = _let_140_["loadfile-local-config"]
    local query_path = vim.loop.fs_realpath(vim.fn.expand(vim.fs.normalize(file_dir_or_dot_hotpot)))
    local opts = vim.tbl_extend("keep", (_3fopts or {}), {force = true, verbose = true})
    if query_path then
      local _141_ = lookup_local_config(query_path)
      if (nil ~= _141_) then
        local config_path = _141_
        local function _142_(...)
          local _143_ = ...
          if (nil ~= _143_) then
            local config = _143_
            local function _144_(...)
              local _145_ = ...
              if true then
                local _ = _145_
                return handle_config(config, query_path, vim.fs.dirname(config_path), opts)
              else
                local __87_auto = _145_
                return ...
              end
            end
            local function _147_(...)
              if not config.build then
                config.build = true
                return nil
              else
                return nil
              end
            end
            return _144_(_147_(...))
          else
            local __87_auto = _143_
            return ...
          end
        end
        return _142_(loadfile_local_config(config_path))
      elseif (_141_ == nil) then
        return vim.notify(string.format("No .hotpot.lua file found near %s", query_path), vim.log.levels.ERROR)
      else
        return nil
      end
    else
      return vim.notify(string.format("Unable to build, no file or directory found at %s.", file_dir_or_dot_hotpot), vim.log.levels.ERROR)
    end
  end
  local function attach(buf)
    if not automake_memo["attached-buffers"][buf] then
      automake_memo["attached-buffers"][buf] = true
      local function _151_()
        local _let_152_ = require("hotpot.runtime")
        local lookup_local_config = _let_152_["lookup-local-config"]
        local loadfile_local_config = _let_152_["loadfile-local-config"]
        local full_path_current_file = vim.fs.normalize(vim.fn.expand("<afile>:p"))
        local function _153_(...)
          local _154_ = ...
          if (nil ~= _154_) then
            local config_path = _154_
            local function _155_(...)
              local _156_ = ...
              if (nil ~= _156_) then
                local config = _156_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              else
                local __87_auto = _156_
                return ...
              end
            end
            return _155_(loadfile_local_config(config_path))
          else
            local __87_auto = _154_
            return ...
          end
        end
        _153_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _151_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _160_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _160_})
    else
      return nil
    end
  end
  M.auto = {enable = enable, build = build}
end
return M