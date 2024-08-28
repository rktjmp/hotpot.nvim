local function simple_traceback(...)
  local fennel = require("hotpot.fennel")
  return fennel.traceback(...)
end
local function brain_traceback(msg)
  local fennel = require("hotpot.fennel")
  local _let_1_ = require("hotpot.fs")
  local join_path = _let_1_["join-path"]
  local semi = fennel.traceback(msg)
  local hotpot_internals_pattern = join_path(".+", ".+hotpot%.nvim", "lua", "hotpot", ".+")
  local error_head = "*** Hotpot caught a Fennel error. ***"
  local error_tail = ("*** Hotpot thinks you were requiring a module, you will   ***\n" .. "*** likely see an additional error below because lua was  ***\n" .. "*** unable to load the module.                            ***")
  local lines
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for line in string.gmatch(semi, "[^\13\n]+") do
      local val_23_auto
      if not string.match(line, hotpot_internals_pattern) then
        val_23_auto = line
      else
        val_23_auto = nil
      end
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    lines = tbl_21_auto
  end
  local function _4_()
    local state = {stack = {}, message = {}}
    for _, line in ipairs(lines) do
      local and_5_ = (line == line)
      if and_5_ then
        and_5_ = string.match(line, "^stack traceback:$")
      end
      if and_5_ then
        table.insert(state.stack, line)
        state = state
      else
        local and_7_ = (line == line)
        if and_7_ then
          and_7_ = (string.match(line, ": in function ") or string.match(line, ": in main chunk"))
        end
        if and_7_ then
          table.insert(state.stack, line)
          state = state
        else
          local and_9_ = (line == line)
          if and_9_ then
            and_9_ = string.match(line, "%s*%.%.%.$")
          end
          if and_9_ then
            state = state
          elseif (line == line) then
            table.insert(state.message, line)
            state = state
          else
            state = nil
          end
        end
      end
    end
    return state
  end
  local _let_12_ = _4_()
  local stack = _let_12_["stack"]
  local message = _let_12_["message"]
  local in_require_3f
  do
    local review_stack
    local function _13_()
      local level = 0
      local function _14_()
        level = (1 + level)
        return debug.getinfo(level, "nflS")
      end
      return _14_
    end
    review_stack = _13_
    local saw_require = false
    for frame in review_stack() do
      if saw_require then break end
      saw_require = (require == frame.func)
    end
    in_require_3f = saw_require
  end
  local full_lines
  do
    local tmp_9_auto = {}
    table.insert(tmp_9_auto, ("\n" .. error_head .. "\n"))
    local function _15_(_241)
      for _, line in ipairs(message) do
        table.insert(_241, line)
      end
      return nil
    end
    _15_(tmp_9_auto)
    table.insert(tmp_9_auto, "\n")
    local function _16_(_241)
      for _, line in ipairs(stack) do
        table.insert(_241, line)
      end
      return nil
    end
    _16_(tmp_9_auto)
    local function _17_(_241)
      if in_require_3f then
        return table.insert(_241, ("\n" .. error_tail))
      else
        return nil
      end
    end
    _17_(tmp_9_auto)
    full_lines = tmp_9_auto
  end
  local function _19_(_241)
    return string.format("\n%s\n", _241)
  end
  return _19_(string.gsub(table.concat(full_lines, "\n"), "\n\n\n+", "\n\n"))
end
return {traceback = simple_traceback, ["brain-traceback"] = brain_traceback}