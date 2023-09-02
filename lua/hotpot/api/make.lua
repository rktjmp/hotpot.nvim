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
  if (0 < #report) then
    vim.api.nvim_echo(report, true, {})
  else
  end
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local root_dir0 = vim.fs.normalize(root_dir)
  local _let_52_ = opts
  local force_3f = _let_52_["force"]
  local verbose_3f = _let_52_["verbose"]
  local dry_run_3f = _let_52_["dryrun"]
  local atomic_3f = _let_52_["atomic"]
  local _let_53_ = require("hotpot.fs")
  local rm_file = _let_53_["rm-file"]
  local copy_file = _let_53_["copy-file"]
  local compiler_options = opts.compiler
  local _let_54_ = find_compile_targets(root_dir0, build_spec)
  local all_compile_targets = _let_54_["build"]
  local all_ignore_targets = _let_54_["ignore"]
  local force_3f0
  local function _55_()
    local _56_ = opts["infer-force-for-file"]
    if (nil ~= _56_) then
      local file = _56_
      local function _57_(_241)
        return (_241.src == file)
      end
      return any_3f(_57_, all_ignore_targets)
    elseif true then
      local _ = _56_
      return false
    else
      return nil
    end
  end
  force_3f0 = (force_3f or _55_())
  local focused_compile_target
  local function _61_(_59_)
    local _arg_60_ = _59_
    local src = _arg_60_["src"]
    local dest = _arg_60_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_61_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir0)
  local any_errors_3f
  local function _62_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_62_, compile_results)
  local function _65_(_63_)
    local _arg_64_ = _63_
    local tmp_path = _arg_64_["tmp-path"]
    local dest = _arg_64_["dest"]
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
  map(_65_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f})
  local _return
  do
    local tbl_14_auto = {}
    for _, _68_ in ipairs(all_compile_targets) do
      local _each_69_ = _68_
      local src = _each_69_["src"]
      local dest = _each_69_["dest"]
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
    for _, _71_ in ipairs(compile_results) do
      local _each_72_ = _71_
      local src = _each_72_["src"]
      local compiled_3f = _each_72_["compiled?"]
      local err = _each_72_["err"]
      local k_15_auto, v_16_auto = nil, nil
      local function _74_()
        local _73_ = _return[src]
        _73_["compiled?"] = compiled_3f
        _73_["err"] = err
        return _73_
      end
      k_15_auto, v_16_auto = src, _74_()
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
  local function _82_(...)
    local root = (_81_)[1]
    local build_specs = (_81_)[2]
    return (string_3f(root) and table_3f(build_specs))
  end
  if (((_G.type(_81_) == "table") and (nil ~= (_81_)[1]) and (nil ~= (_81_)[2]) and ((_81_)[3] == nil)) and _82_(...)) then
    local root = (_81_)[1]
    local build_specs = (_81_)[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local function _83_(...)
      local root = (_81_)[1]
      local opts = (_81_)[2]
      local build_specs = (_81_)[3]
      return (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if (((_G.type(_81_) == "table") and (nil ~= (_81_)[1]) and (nil ~= (_81_)[2]) and (nil ~= (_81_)[3]) and ((_81_)[4] == nil)) and _83_(...)) then
      local root = (_81_)[1]
      local opts = (_81_)[2]
      local build_specs = (_81_)[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    elseif true then
      local _ = _81_
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
    local function _86_()
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
    local _let_85_ = _86_()
    local spec = _let_85_[1]
    local opts = _let_85_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local function _87_()
        local t = clean_spec
        return table_3f(t)
      end
      if ((nil ~= clean_spec) and _87_()) then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir)
    if config.build then
      local function _89_(...)
        local _90_, _91_ = ...
        if ((_G.type(_90_) == "table") and (nil ~= (_90_)["build-spec"]) and (nil ~= (_90_)["build-options"])) then
          local build_spec = (_90_)["build-spec"]
          local build_options = (_90_)["build-options"]
          local function _92_(...)
            local _93_, _94_ = ...
            if (_93_ == true) then
              local function _95_(...)
                local _96_, _97_ = ...
                if true then
                  local _ = _96_
                  local function _98_(...)
                    local _99_, _100_ = ...
                    if true then
                      local _0 = _99_
                      local function _101_(...)
                        local _102_, _103_ = ...
                        if (nil ~= _102_) then
                          local compile_results = _102_
                          local function _104_(...)
                            local _105_, _106_ = ...
                            if (nil ~= _105_) then
                              local any_errors_3f = _105_
                              if (config.clean and not build_options.dryrun and (not build_options.atomic or (build_options.atomic and not any_errors_3f))) then
                                local function _107_(...)
                                  local _108_, _109_ = ...
                                  if (nil ~= _108_) then
                                    local clean_spec = _108_
                                    local function _110_(...)
                                      local _111_, _112_ = ...
                                      if (_111_ == true) then
                                        local function _113_(...)
                                          local _114_, _115_ = ...
                                          if (nil ~= _114_) then
                                            local clean_targets = _114_
                                            return do_clean(clean_targets, build_options)
                                          elseif ((_114_ == nil) and (nil ~= _115_)) then
                                            local e = _115_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _113_(find_clean_targets(root_dir, clean_spec, compile_results))
                                      elseif ((_111_ == nil) and (nil ~= _112_)) then
                                        local e = _112_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _110_(validate_spec("clean", clean_spec))
                                  elseif ((_108_ == nil) and (nil ~= _109_)) then
                                    local e = _109_
                                    return vim.notify(e, vim.log.levels.ERROR)
                                  else
                                    return nil
                                  end
                                end
                                return _107_(clean_spec_or_default(config.clean))
                              else
                                return nil
                              end
                            elseif ((_105_ == nil) and (nil ~= _106_)) then
                              local e = _106_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          local function _121_(_241)
                            return not _241["compiled?"]
                          end
                          return _104_(any_3f(_121_, compile_results))
                        elseif ((_102_ == nil) and (nil ~= _103_)) then
                          local e = _103_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      return _101_(M.build(root_dir, build_options, build_spec))
                    elseif ((_99_ == nil) and (nil ~= _100_)) then
                      local e = _100_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options.compiler = config.compiler
                  return _98_(nil)
                elseif ((_96_ == nil) and (nil ~= _97_)) then
                  local e = _97_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              build_options["infer-force-for-file"] = current_file
              return _95_(nil)
            elseif ((_93_ == nil) and (nil ~= _94_)) then
              local e = _94_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          return _92_(validate_spec("build", build_spec))
        elseif ((_90_ == nil) and (nil ~= _91_)) then
          local e = _91_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _89_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function attach(buf)
    if not (automake_memo["attached-buffers"])[buf] then
      automake_memo["attached-buffers"][buf] = true
      local function _128_()
        local _let_129_ = require("hotpot.runtime")
        local lookup_local_config = _let_129_["lookup-local-config"]
        local loadfile_local_config = _let_129_["loadfile-local-config"]
        local full_path_current_file = vim.fn.expand("<afile>:p")
        local function _130_(...)
          local _131_ = ...
          if (nil ~= _131_) then
            local config_path = _131_
            local function _132_(...)
              local _133_ = ...
              if (nil ~= _133_) then
                local config = _133_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              elseif true then
                local __75_auto = _133_
                return ...
              else
                return nil
              end
            end
            return _132_(loadfile_local_config(config_path))
          elseif true then
            local __75_auto = _131_
            return ...
          else
            return nil
          end
        end
        _130_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _128_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _137_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _137_})
    else
      return nil
    end
  end
  M.automake = {enable = enable}
end
return M