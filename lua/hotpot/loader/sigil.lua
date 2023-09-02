local _local_1_ = string
local fmt = _local_1_["format"]
local _local_2_ = require("hotpot.fs")
local file_exists_3f = _local_2_["file-exists?"]
local file_missing_3f = _local_2_["file-missing?"]
local file_stat = _local_2_["file-stat"]
local rm_file = _local_2_["rm-file"]
local SIGIL_FILE = ".hotpot.lua"
local function load(path)
  local defaults = {schema = "hotpot/1", compiler = {}, build = false, colocate = false}
  local valid_3f
  local function _3_(sigil)
    local _4_
    do
      local tbl_17_auto = {}
      local i_18_auto = #tbl_17_auto
      for key, _val in pairs(sigil) do
        local val_19_auto
        do
          local _5_ = defaults[key]
          if (_5_ == nil) then
            val_19_auto = key
          else
            val_19_auto = nil
          end
        end
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      _4_ = tbl_17_auto
    end
    if ((_G.type(_4_) == "table") and ((_4_)[1] == nil)) then
      return true
    elseif (nil ~= _4_) then
      local keys = _4_
      return false, fmt("invalid keys in sigil %s: %s. The valid keys are: %s.", path, table.concat(keys, ", "), table.concat(vim.tbl_keys(defaults), ", "))
    else
      return nil
    end
  end
  valid_3f = _3_
  local function _9_(...)
    local _10_, _11_ = ...
    if (nil ~= _10_) then
      local sigil_fn = _10_
      local function _12_(...)
        local _13_, _14_ = ...
        local function _15_(...)
          local sigil = _14_
          return ("table" == type(sigil))
        end
        if (((_13_ == true) and (nil ~= _14_)) and _15_(...)) then
          local sigil = _14_
          local function _16_(...)
            local _17_, _18_ = ...
            if (_17_ == true) then
              return sigil
            elseif ((_17_ == true) and (_18_ == nil)) then
              vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
              return nil
            elseif ((_17_ == true) and (nil ~= _18_)) then
              local x = _18_
              vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
              return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
            elseif ((_17_ == nil) and (nil ~= _18_)) then
              local e = _18_
              vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
              return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
            elseif ((_17_ == false) and (nil ~= _18_)) then
              local e = _18_
              vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
              return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
            else
              return nil
            end
          end
          return _16_(valid_3f(sigil))
        elseif ((_13_ == true) and (_14_ == nil)) then
          vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
          return nil
        elseif ((_13_ == true) and (nil ~= _14_)) then
          local x = _14_
          vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
          return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
        elseif ((_13_ == nil) and (nil ~= _14_)) then
          local e = _14_
          vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
          return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
        elseif ((_13_ == false) and (nil ~= _14_)) then
          local e = _14_
          vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
          return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
        else
          return nil
        end
      end
      return _12_(pcall(sigil_fn))
    elseif ((_10_ == true) and (_11_ == nil)) then
      vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
      return nil
    elseif ((_10_ == true) and (nil ~= _11_)) then
      local x = _11_
      vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
      return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
    elseif ((_10_ == nil) and (nil ~= _11_)) then
      local e = _11_
      vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
      return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
    elseif ((_10_ == false) and (nil ~= _11_)) then
      local e = _11_
      vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
      return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
    else
      return nil
    end
  end
  return _9_(loadfile(path))
end
local function wants_colocation_3f(sigil_path)
  if (sigil_path and file_exists_3f(sigil_path)) then
    local _22_ = load(sigil_path)
    if ((_G.type(_22_) == "table") and (nil ~= (_22_).colocate)) then
      local colocate = (_22_).colocate
      return colocate
    elseif true then
      local _ = _22_
      return false
    else
      return nil
    end
  else
    return false
  end
end
return {load = load, ["wants-colocation?"] = wants_colocation_3f, SIGIL_FILE = SIGIL_FILE}