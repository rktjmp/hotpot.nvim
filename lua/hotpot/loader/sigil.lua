local _local_1_ = string
local fmt = _local_1_["format"]
local SIGIL_FILE = ".hotpot.lua"
local function load(path)
  local defaults = {schema = "hotpot/1", compiler = {}, build = false, clean = false}
  local valid_3f
  local function _2_(sigil)
    local _3_
    do
      local tbl_19_auto = {}
      local i_20_auto = 0
      for key, _val in pairs(sigil) do
        local val_21_auto
        do
          local _4_ = defaults[key]
          if (_4_ == nil) then
            val_21_auto = key
          else
            val_21_auto = nil
          end
        end
        if (nil ~= val_21_auto) then
          i_20_auto = (i_20_auto + 1)
          do end (tbl_19_auto)[i_20_auto] = val_21_auto
        else
        end
      end
      _3_ = tbl_19_auto
    end
    if ((_G.type(_3_) == "table") and (_3_[1] == nil)) then
      return true
    elseif (nil ~= _3_) then
      local invalid_keys = _3_
      local e = fmt("invalid keys in sigil %s: %s. The valid keys are: %s.", path, table.concat(invalid_keys, ", "), table.concat(vim.tbl_keys(defaults), ", "))
      return false, e
    else
      return nil
    end
  end
  valid_3f = _2_
  local function _8_(...)
    local _9_, _10_ = ...
    if (nil ~= _9_) then
      local sigil_fn = _9_
      local function _11_(...)
        local _12_, _13_ = ...
        local function _14_(...)
          local sigil = _13_
          return ("table" == type(sigil))
        end
        if (((_12_ == true) and (nil ~= _13_)) and _14_(...)) then
          local sigil = _13_
          local function _15_(...)
            local _16_, _17_ = ...
            if (_16_ == true) then
              return sigil
            elseif ((_16_ == true) and (_17_ == nil)) then
              vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
              return nil
            elseif ((_16_ == true) and (nil ~= _17_)) then
              local x = _17_
              vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
              return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
            elseif ((_16_ == nil) and (nil ~= _17_)) then
              local e = _17_
              vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
              return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
            elseif ((_16_ == false) and (nil ~= _17_)) then
              local e = _17_
              vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
              return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
            else
              return nil
            end
          end
          return _15_(valid_3f(sigil))
        elseif ((_12_ == true) and (_13_ == nil)) then
          vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
          return nil
        elseif ((_12_ == true) and (nil ~= _13_)) then
          local x = _13_
          vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
          return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
        elseif ((_12_ == nil) and (nil ~= _13_)) then
          local e = _13_
          vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
          return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
        elseif ((_12_ == false) and (nil ~= _13_)) then
          local e = _13_
          vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
          return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
        else
          return nil
        end
      end
      return _11_(pcall(sigil_fn))
    elseif ((_9_ == true) and (_10_ == nil)) then
      vim.notify_once(fmt("Hotpot sigil was exists but returned nil, %s", path), vim.log.levels.WARN)
      return nil
    elseif ((_9_ == true) and (nil ~= _10_)) then
      local x = _10_
      vim.notify(table.concat({"Hotpot sigil failed to load due to an input error.", fmt("Sigil path: %s", path), fmt("Sigil returned %s instead of table", type(x))}, "\n"), vim.log.levels.ERROR)
      return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
    elseif ((_9_ == nil) and (nil ~= _10_)) then
      local e = _10_
      vim.notify(table.concat({"Hotpot sigil failed to load due to a syntax error.", fmt("Sigil path: %s", path), e}, "\n"), vim.log.levels.ERROR)
      return error("Hotpot refusing to continue to avoid unintentional side effects.", 0)
    elseif ((_9_ == false) and (nil ~= _10_)) then
      local e = _10_
      vim.notify_once(fmt("hotpot sigil was invalid, %s\n%s", path, e), vim.log.levels.ERROR)
      return error("hotpot refusing to continue to avoid unintentional side effects.", 0)
    else
      return nil
    end
  end
  return _8_(loadfile(path))
end
return {load = load, SIGIL_FILE = SIGIL_FILE}