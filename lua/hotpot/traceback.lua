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
    local tbl_19_auto = {}
    local i_20_auto = 0
    for line in string.gmatch(semi, "[^\13\n]+") do
      local val_21_auto
      if not string.match(line, hotpot_internals_pattern) then
        val_21_auto = line
      else
        val_21_auto = nil
      end
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    lines = tbl_19_auto
  end
  local function _5_()
    local state = {stack = {}, message = {}}
    for _, line in ipairs(lines) do
      local function _6_()
        return string.match(line, "^stack traceback:$")
      end
      if ((line == line) and _6_()) then
        table.insert(state.stack, line)
        state = state
      else
        local function _7_()
          return (string.match(line, ": in function ") or string.match(line, ": in main chunk"))
        end
        if ((line == line) and _7_()) then
          table.insert(state.stack, line)
          state = state
        else
          local function _8_()
            return string.match(line, "%s*%.%.%.$")
          end
          if ((line == line) and _8_()) then
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
  local _let_4_ = _5_()
  local stack = _let_4_["stack"]
  local message = _let_4_["message"]
  local in_require_3f
  do
    local review_stack
    local function _10_()
      local level = 0
      local function _11_()
        level = (1 + level)
        return debug.getinfo(level, "nflS")
      end
      return _11_
    end
    review_stack = _10_
    local saw_require = false
    for frame in review_stack() do
      if saw_require then break end
      saw_require = (require == frame.func)
    end
    in_require_3f = saw_require
  end
  local full_lines
  do
    local _12_ = {}
    table.insert(_12_, ("\n" .. error_head .. "\n"))
    local function _13_(_241)
      for _, line in ipairs(message) do
        table.insert(_241, line)
      end
      return nil
    end
    _13_(_12_)
    table.insert(_12_, "\n")
    local function _14_(_241)
      for _, line in ipairs(stack) do
        table.insert(_241, line)
      end
      return nil
    end
    _14_(_12_)
    local function _15_(_241)
      if in_require_3f then
        return table.insert(_241, ("\n" .. error_tail))
      else
        return nil
      end
    end
    _15_(_12_)
    full_lines = _12_
  end
  local function _17_(_241)
    return string.format("\n%s\n", _241)
  end
  return _17_(string.gsub(table.concat(full_lines, "\n"), "\n\n\n+", "\n\n"))
end
return {traceback = simple_traceback, ["brain-traceback"] = brain_traceback}