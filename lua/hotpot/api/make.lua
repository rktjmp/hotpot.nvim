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
  local begin_search_at = uv.hrtime()
  local split = {build = {}, ignore = {}, ["time-ns"] = nil}
  for _, _12_ in ipairs(spec) do
    local _each_13_ = _12_
    local glob = _each_13_[1]
    local action = _each_13_[2]
    assert(string.match(glob, "%.fnl$"), string.format("build glob patterns must end in .fnl, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      local path0 = vim.fs.normalize(path)
      if (nil == files[path0]) then
        local _14_ = {string.find(glob, "fnl/"), action}
        local function _15_()
          local _1 = _14_[1]
          local f = _14_[2]
          return function_3f(f)
        end
        if (((_G.type(_14_) == "table") and true and (nil ~= _14_[2])) and _15_()) then
          local _1 = _14_[1]
          local f = _14_[2]
          local _16_ = f(path0)
          if (_16_ == false) then
            files[path0] = false
          else
            local function _17_()
              local dest_path = _16_
              return string_3f(dest_path)
            end
            if ((nil ~= _16_) and _17_()) then
              local dest_path = _16_
              files[path0] = string.gsub(vim.fs.normalize(dest_path), "%.fnl$", ".lua")
            else
              local _3fsome = _16_
              error(string.format("Invalid return value from build function: %s => %s", path0, type(_3fsome)))
            end
          end
        elseif ((_G.type(_14_) == "table") and true and (_14_[2] == false)) then
          local _1 = _14_[1]
          files[path0] = false
        elseif ((_G.type(_14_) == "table") and (_14_[1] == 1) and (_14_[2] == true)) then
          files[path0] = (root_dir .. "/lua/" .. string.sub(path0, (#root_dir + 6), -4) .. "lua")
        elseif ((_G.type(_14_) == "table") and true and (_14_[2] == true)) then
          local _1 = _14_[1]
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
  local tbl_18_auto = {}
  local i_19_auto = 0
  for path, action in pairs(files) do
    local val_20_auto
    if action then
      val_20_auto = path
    else
      val_20_auto = nil
    end
    if (nil ~= val_20_auto) then
      i_19_auto = (i_19_auto + 1)
      do end (tbl_18_auto)[i_19_auto] = val_20_auto
    else
    end
  end
  return tbl_18_auto
end
local function do_compile(compile_targets, compiler_options, root_dir)
  local _let_29_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_29_["compile-file"]
  do
    local _30_ = package.loaded
    if ((_G.type(_30_) == "table") and (nil ~= _30_["hotpot.fennel"])) then
      local fennel = _30_["hotpot.fennel"]
      for k, _ in pairs(fennel["macro-loaded"]) do
        fennel["macro-loaded"][k] = nil
      end
    else
    end
  end
  local function _34_(_32_)
    local _arg_33_ = _32_
    local src = _arg_33_["src"]
    local dest = _arg_33_["dest"]
    local tmp_path = (vim.fn.tempname() .. ".lua")
    local relative_filename = string.sub(src, (2 + #root_dir))
    local begin_compile_at = uv.hrtime()
    local _35_, _36_ = nil, nil
    local _38_
    do
      local _37_ = compiler_options.modules
      _37_["filename"] = relative_filename
      _38_ = _37_
    end
    _35_, _36_ = compile_file(src, tmp_path, _38_, compiler_options.macros, compiler_options.preprocessor)
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
local function report_compile_results(compile_results, _40_)
  local _arg_41_ = _40_
  local any_errors_3f = _arg_41_["any-errors?"]
  local verbose_3f = _arg_41_["verbose?"]
  local atomic_3f = _arg_41_["atomic?"]
  local dry_run_3f = _arg_41_["dry-run?"]
  local find_time_ns = _arg_41_["find-time-ns"]
  local report = {}
  if dry_run_3f then
    table.insert(report, {"No changes were written to disk! Compiled with dryrun = true!\n", "DiagnosticWarn"})
  else
  end
  if (any_errors_3f and atomic_3f) then
    table.insert(report, {"No changes were written to disk! Compiled with atomic = true and some files had compilation errors!\n", "DiagnosticWarn"})
  else
  end
  local function _44_(_241)
    local _let_45_ = _241
    local compiled_3f = _let_45_["compiled?"]
    local src = _let_45_["src"]
    local dest = _let_45_["dest"]
    local time_ns = _let_45_["time-ns"]
    local function _47_()
      if _241["compiled?"] then
        return {"\226\152\145  ", "DiagnosticOK"}
      else
        return {"\226\152\146  ", "DiagnosticWarn"}
      end
    end
    local _let_46_ = _47_()
    local char = _let_46_[1]
    local level = _let_46_[2]
    table.insert(report, {string.format("%s%s\n", char, src), level})
    return table.insert(report, {string.format("-> %s (%sms)\n", dest, ns__3ems(time_ns)), level})
  end
  local function _50_(_48_)
    local _arg_49_ = _48_
    local compiled_3f = _arg_49_["compiled?"]
    return (verbose_3f or not compiled_3f)
  end
  map(_44_, filter(_50_, compile_results))
  local function _53_(sum, _51_)
    local _arg_52_ = _51_
    local time_ns = _arg_52_["time-ns"]
    return (sum + time_ns)
  end
  local function _56_(_54_)
    local _arg_55_ = _54_
    local compiled_3f = _arg_55_["compiled?"]
    return compiled_3f
  end
  table.insert(report, {string.format("Disk: %sms Compile: %sms\n", ns__3ems(find_time_ns), ns__3ems(reduce(_53_, 0, filter(_56_, compile_results)))), "DiagnosticInfo"})
  local function _57_(_241)
    if ((_G.type(_241) == "table") and (nil ~= _241.err)) then
      local err = _241.err
      return table.insert(report, {err, "DiagnosticError"})
    else
      return nil
    end
  end
  map(_57_, compile_results)
  if (0 < #report) then
    vim.api.nvim_echo(report, true, {})
  else
  end
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local root_dir0 = vim.fs.normalize(root_dir)
  local _let_60_ = opts
  local force_3f = _let_60_["force"]
  local verbose_3f = _let_60_["verbose"]
  local dry_run_3f = _let_60_["dryrun"]
  local atomic_3f = _let_60_["atomic"]
  local _let_61_ = require("hotpot.fs")
  local rm_file = _let_61_["rm-file"]
  local copy_file = _let_61_["copy-file"]
  local compiler_options = opts.compiler
  local _let_62_ = find_compile_targets(root_dir0, build_spec)
  local all_compile_targets = _let_62_["build"]
  local all_ignore_targets = _let_62_["ignore"]
  local find_time_ns = _let_62_["time-ns"]
  local force_3f0
  local function _63_(...)
    local _64_ = opts["infer-force-for-file"]
    if (nil ~= _64_) then
      local file = _64_
      local function _65_(_241)
        return (_241.src == file)
      end
      return any_3f(_65_, all_ignore_targets)
    else
      local _ = _64_
      return false
    end
  end
  force_3f0 = (force_3f or _63_())
  local focused_compile_target
  local function _69_(_67_)
    local _arg_68_ = _67_
    local src = _arg_68_["src"]
    local dest = _arg_68_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_69_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir0)
  local any_errors_3f
  local function _70_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_70_, compile_results)
  local function _73_(_71_)
    local _arg_72_ = _71_
    local tmp_path = _arg_72_["tmp-path"]
    local dest = _arg_72_["dest"]
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
  map(_73_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f, ["find-time-ns"] = find_time_ns})
  local _return
  do
    local tbl_14_auto = {}
    for _, _76_ in ipairs(all_compile_targets) do
      local _each_77_ = _76_
      local src = _each_77_["src"]
      local dest = _each_77_["dest"]
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
    for _, _79_ in ipairs(compile_results) do
      local _each_80_ = _79_
      local src = _each_80_["src"]
      local compiled_3f = _each_80_["compiled?"]
      local err = _each_80_["err"]
      local k_15_auto, v_16_auto = nil, nil
      local function _82_()
        local _81_ = _return[src]
        _81_["compiled?"] = compiled_3f
        _81_["err"] = err
        return _81_
      end
      k_15_auto, v_16_auto = src, _82_()
      if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
        tbl_14_auto[k_15_auto] = v_16_auto
      else
      end
    end
    _return0 = tbl_14_auto
  end
  local tbl_18_auto = {}
  local i_19_auto = 0
  for _, v in pairs(_return0) do
    local val_20_auto = v
    if (nil ~= val_20_auto) then
      i_19_auto = (i_19_auto + 1)
      do end (tbl_18_auto)[i_19_auto] = val_20_auto
    else
    end
  end
  return tbl_18_auto
end
local function do_clean(clean_targets, opts)
  local _let_85_ = require("hotpot.fs")
  local rm_file = _let_85_["rm-file"]
  for _, file in ipairs(clean_targets) do
    local _86_, _87_ = rm_file(file)
    if (_86_ == true) then
      vim.notify(string.format("rm %s", file), vim.log.levels.WARN)
    elseif ((_86_ == false) and (nil ~= _87_)) then
      local e = _87_
      vim.notify(string.format("Could not clean file %s, %s", file, e), vim.log.levels.ERROR)
    else
    end
  end
  return nil
end
M.build = function(...)
  local _89_ = {...}
  local function _90_(...)
    local root = _89_[1]
    local build_specs = _89_[2]
    return (string_3f(root) and table_3f(build_specs))
  end
  if (((_G.type(_89_) == "table") and (nil ~= _89_[1]) and (nil ~= _89_[2]) and (_89_[3] == nil)) and _90_(...)) then
    local root = _89_[1]
    local build_specs = _89_[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local function _91_(...)
      local root = _89_[1]
      local opts = _89_[2]
      local build_specs = _89_[3]
      return (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if (((_G.type(_89_) == "table") and (nil ~= _89_[1]) and (nil ~= _89_[2]) and (nil ~= _89_[3]) and (_89_[4] == nil)) and _91_(...)) then
      local root = _89_[1]
      local opts = _89_[2]
      local build_specs = _89_[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    else
      local _ = _89_
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
    local function _94_()
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
    local _let_93_ = _94_()
    local spec = _let_93_[1]
    local opts = _let_93_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local function _95_()
        local t = clean_spec
        return table_3f(t)
      end
      if ((nil ~= clean_spec) and _95_()) then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir, _3fmanual_opts)
    if config.build then
      local function _97_(...)
        local _98_, _99_ = ...
        if ((_G.type(_98_) == "table") and (nil ~= _98_["build-spec"]) and (nil ~= _98_["build-options"])) then
          local build_spec = _98_["build-spec"]
          local build_options = _98_["build-options"]
          local function _100_(...)
            local _101_, _102_ = ...
            if (nil ~= _101_) then
              local build_options0 = _101_
              local function _103_(...)
                local _104_, _105_ = ...
                if (_104_ == true) then
                  local function _106_(...)
                    local _107_, _108_ = ...
                    if true then
                      local _ = _107_
                      local function _109_(...)
                        local _110_, _111_ = ...
                        if true then
                          local _0 = _110_
                          local function _112_(...)
                            local _113_, _114_ = ...
                            if (nil ~= _113_) then
                              local compile_results = _113_
                              local function _115_(...)
                                local _116_, _117_ = ...
                                if (nil ~= _116_) then
                                  local any_errors_3f = _116_
                                  if (config.clean and not build_options0.dryrun and (not build_options0.atomic or (build_options0.atomic and not any_errors_3f))) then
                                    local function _118_(...)
                                      local _119_, _120_ = ...
                                      if (nil ~= _119_) then
                                        local clean_spec = _119_
                                        local function _121_(...)
                                          local _122_, _123_ = ...
                                          if (_122_ == true) then
                                            local function _124_(...)
                                              local _125_, _126_ = ...
                                              if (nil ~= _125_) then
                                                local clean_targets = _125_
                                                local function _127_(...)
                                                  local _128_, _129_ = ...
                                                  if true then
                                                    local _1 = _128_
                                                    return compile_results
                                                  elseif ((_128_ == nil) and (nil ~= _129_)) then
                                                    local e = _129_
                                                    return vim.notify(e, vim.log.levels.ERROR)
                                                  else
                                                    return nil
                                                  end
                                                end
                                                return _127_(do_clean(clean_targets, build_options0))
                                              elseif ((_125_ == nil) and (nil ~= _126_)) then
                                                local e = _126_
                                                return vim.notify(e, vim.log.levels.ERROR)
                                              else
                                                return nil
                                              end
                                            end
                                            return _124_(find_clean_targets(root_dir, clean_spec, compile_results))
                                          elseif ((_122_ == nil) and (nil ~= _123_)) then
                                            local e = _123_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _121_(validate_spec("clean", clean_spec))
                                      elseif ((_119_ == nil) and (nil ~= _120_)) then
                                        local e = _120_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _118_(clean_spec_or_default(config.clean))
                                  else
                                    return compile_results
                                  end
                                elseif ((_116_ == nil) and (nil ~= _117_)) then
                                  local e = _117_
                                  return vim.notify(e, vim.log.levels.ERROR)
                                else
                                  return nil
                                end
                              end
                              local function _136_(_241)
                                return _241["err?"]
                              end
                              return _115_(any_3f(_136_, compile_results))
                            elseif ((_113_ == nil) and (nil ~= _114_)) then
                              local e = _114_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          return _112_(M.build(root_dir, build_options0, build_spec))
                        elseif ((_110_ == nil) and (nil ~= _111_)) then
                          local e = _111_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      build_options0.compiler = config.compiler
                      return _109_(nil)
                    elseif ((_107_ == nil) and (nil ~= _108_)) then
                      local e = _108_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options0["infer-force-for-file"] = current_file
                  return _106_(nil)
                elseif ((_104_ == nil) and (nil ~= _105_)) then
                  local e = _105_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              return _103_(validate_spec("build", build_spec))
            elseif ((_101_ == nil) and (nil ~= _102_)) then
              local e = _102_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          local function _142_(...)
            if _3fmanual_opts then
              return vim.tbl_extend("force", build_options, _3fmanual_opts)
            else
              return build_options
            end
          end
          return _100_(_142_(...))
        elseif ((_98_ == nil) and (nil ~= _99_)) then
          local e = _99_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _97_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function build(file_dir_or_dot_hotpot, _3fopts)
    local _let_145_ = require("hotpot.runtime")
    local lookup_local_config = _let_145_["lookup-local-config"]
    local loadfile_local_config = _let_145_["loadfile-local-config"]
    local query_path = vim.loop.fs_realpath(vim.fn.expand(vim.fs.normalize(file_dir_or_dot_hotpot)))
    local opts = vim.tbl_extend("keep", (_3fopts or {}), {force = true, verbose = true})
    if query_path then
      local _146_ = lookup_local_config(query_path)
      if (nil ~= _146_) then
        local config_path = _146_
        local function _147_(...)
          local _148_ = ...
          if (nil ~= _148_) then
            local config = _148_
            local function _149_(...)
              local _150_ = ...
              if true then
                local _ = _150_
                return handle_config(config, query_path, vim.fs.dirname(config_path), opts)
              else
                local __84_auto = _150_
                return ...
              end
            end
            local function _152_(...)
              if not config.build then
                config.build = true
                return nil
              else
                return nil
              end
            end
            return _149_(_152_(...))
          else
            local __84_auto = _148_
            return ...
          end
        end
        return _147_(loadfile_local_config(config_path))
      elseif (_146_ == nil) then
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
      local function _156_()
        local _let_157_ = require("hotpot.runtime")
        local lookup_local_config = _let_157_["lookup-local-config"]
        local loadfile_local_config = _let_157_["loadfile-local-config"]
        local full_path_current_file = vim.fs.normalize(vim.fn.expand("<afile>:p"))
        local function _158_(...)
          local _159_ = ...
          if (nil ~= _159_) then
            local config_path = _159_
            local function _160_(...)
              local _161_ = ...
              if (nil ~= _161_) then
                local config = _161_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              else
                local __84_auto = _161_
                return ...
              end
            end
            return _160_(loadfile_local_config(config_path))
          else
            local __84_auto = _159_
            return ...
          end
        end
        _158_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _156_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _165_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _165_})
    else
      return nil
    end
  end
  M.auto = {enable = enable, build = build}
end
return M