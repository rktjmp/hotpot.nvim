local function get_highlight()
  local function get_sel_start(mode)
    local _1_ = {mode, vim.fn.getpos("v")}
    if ((_G.type(_1_) == "table") and ((_1_)[1] == "v") and ((_G.type((_1_)[2]) == "table") and true and (nil ~= ((_1_)[2])[2]) and (nil ~= ((_1_)[2])[3]) and true)) then
      local _buf = ((_1_)[2])[1]
      local line = ((_1_)[2])[2]
      local col = ((_1_)[2])[3]
      local _offset = ((_1_)[2])[4]
      return {line, col}
    elseif ((_G.type(_1_) == "table") and ((_1_)[1] == "V") and ((_G.type((_1_)[2]) == "table") and true and (nil ~= ((_1_)[2])[2]) and (nil ~= ((_1_)[2])[3]) and true)) then
      local _buf = ((_1_)[2])[1]
      local line = ((_1_)[2])[2]
      local col = ((_1_)[2])[3]
      local _offset = ((_1_)[2])[4]
      return {line, 1}
    elseif true then
      local _ = _1_
      return error("Tried to get selection while not in v or V mode")
    else
      return nil
    end
  end
  local function get_cur(mode)
    local _3_ = {mode, vim.fn.getpos(".")}
    if ((_G.type(_3_) == "table") and ((_3_)[1] == "v") and ((_G.type((_3_)[2]) == "table") and true and (nil ~= ((_3_)[2])[2]) and (nil ~= ((_3_)[2])[3]) and true)) then
      local _buf = ((_3_)[2])[1]
      local line = ((_3_)[2])[2]
      local col = ((_3_)[2])[3]
      local _offset = ((_3_)[2])[4]
      return {line, col}
    elseif ((_G.type(_3_) == "table") and ((_3_)[1] == "V") and ((_G.type((_3_)[2]) == "table") and true and (nil ~= ((_3_)[2])[2]) and (nil ~= ((_3_)[2])[3]) and true)) then
      local _buf = ((_3_)[2])[1]
      local line = ((_3_)[2])[2]
      local col = ((_3_)[2])[3]
      local _offset = ((_3_)[2])[4]
      return {line, 2147483647}
    elseif true then
      local _ = _3_
      return error("Tried to get selection while not in v or V mode")
    else
      return nil
    end
  end
  local _let_5_ = vim.api.nvim_get_mode()
  local mode = _let_5_["mode"]
  local sel_start_pos = get_sel_start(mode)
  local cur_pos = get_cur(mode)
  local start, stop = nil, nil
  do
    local _6_ = {sel_start_pos, cur_pos}
    local function _7_()
      local sl = ((_6_)[1])[1]
      local sc = ((_6_)[1])[2]
      local cl = ((_6_)[2])[1]
      local cc = ((_6_)[2])[2]
      return ((sl == cl) and (sc == cc))
    end
    if (((_G.type(_6_) == "table") and ((_G.type((_6_)[1]) == "table") and (nil ~= ((_6_)[1])[1]) and (nil ~= ((_6_)[1])[2])) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]) and (nil ~= ((_6_)[2])[2]))) and _7_()) then
      local sl = ((_6_)[1])[1]
      local sc = ((_6_)[1])[2]
      local cl = ((_6_)[2])[1]
      local cc = ((_6_)[2])[2]
      start, stop = {sl, sc}, {cl, cc}
    else
      local function _8_()
        local sl = ((_6_)[1])[1]
        local sc = ((_6_)[1])[2]
        local cl = ((_6_)[2])[1]
        local cc = ((_6_)[2])[2]
        return ((sl == cl) and (sc < cc))
      end
      if (((_G.type(_6_) == "table") and ((_G.type((_6_)[1]) == "table") and (nil ~= ((_6_)[1])[1]) and (nil ~= ((_6_)[1])[2])) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]) and (nil ~= ((_6_)[2])[2]))) and _8_()) then
        local sl = ((_6_)[1])[1]
        local sc = ((_6_)[1])[2]
        local cl = ((_6_)[2])[1]
        local cc = ((_6_)[2])[2]
        start, stop = {sl, sc}, {cl, cc}
      else
        local function _9_()
          local sl = ((_6_)[1])[1]
          local sc = ((_6_)[1])[2]
          local cl = ((_6_)[2])[1]
          local cc = ((_6_)[2])[2]
          return ((sl == cl) and (cc < sc))
        end
        if (((_G.type(_6_) == "table") and ((_G.type((_6_)[1]) == "table") and (nil ~= ((_6_)[1])[1]) and (nil ~= ((_6_)[1])[2])) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]) and (nil ~= ((_6_)[2])[2]))) and _9_()) then
          local sl = ((_6_)[1])[1]
          local sc = ((_6_)[1])[2]
          local cl = ((_6_)[2])[1]
          local cc = ((_6_)[2])[2]
          start, stop = {cl, cc}, {sl, sc}
        else
          local function _10_()
            local sl = ((_6_)[1])[1]
            local sc = ((_6_)[1])[2]
            local cl = ((_6_)[2])[1]
            local cc = ((_6_)[2])[2]
            return (sl < cl)
          end
          if (((_G.type(_6_) == "table") and ((_G.type((_6_)[1]) == "table") and (nil ~= ((_6_)[1])[1]) and (nil ~= ((_6_)[1])[2])) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]) and (nil ~= ((_6_)[2])[2]))) and _10_()) then
            local sl = ((_6_)[1])[1]
            local sc = ((_6_)[1])[2]
            local cl = ((_6_)[2])[1]
            local cc = ((_6_)[2])[2]
            start, stop = {sl, sc}, {cl, cc}
          else
            local function _11_()
              local sl = ((_6_)[1])[1]
              local sc = ((_6_)[1])[2]
              local cl = ((_6_)[2])[1]
              local cc = ((_6_)[2])[2]
              return (cl < sl)
            end
            if (((_G.type(_6_) == "table") and ((_G.type((_6_)[1]) == "table") and (nil ~= ((_6_)[1])[1]) and (nil ~= ((_6_)[1])[2])) and ((_G.type((_6_)[2]) == "table") and (nil ~= ((_6_)[2])[1]) and (nil ~= ((_6_)[2])[2]))) and _11_()) then
              local sl = ((_6_)[1])[1]
              local sc = ((_6_)[1])[2]
              local cl = ((_6_)[2])[1]
              local cc = ((_6_)[2])[2]
              start, stop = {cl, cc}, {sl, sc}
            elseif true then
              local _ = _6_
              start, stop = error(string.format("unhandled selection-case :sel-start %s :cur-pos %s", vim.inspect(sel_start_pos), vim.inspect(cur_pos)))
            else
              start, stop = nil
            end
          end
        end
      end
    end
  end
  local start0, stop0 = nil, nil
  do
    local _13_ = {mode, start, stop}
    if ((_G.type(_13_) == "table") and ((_13_)[1] == "v") and ((_13_)[2] == start) and ((_13_)[3] == stop)) then
      start0, stop0 = start, stop
    elseif ((_G.type(_13_) == "table") and ((_13_)[1] == "V") and ((_G.type((_13_)[2]) == "table") and (nil ~= ((_13_)[2])[1]) and true) and ((_G.type((_13_)[3]) == "table") and (nil ~= ((_13_)[3])[1]) and true)) then
      local start_line = ((_13_)[2])[1]
      local _ = ((_13_)[2])[2]
      local stop_line = ((_13_)[3])[1]
      local _0 = ((_13_)[3])[2]
      local len
      local function _14_(_241)
        return (_241)[1]
      end
      len = #_14_(vim.api.nvim_buf_get_lines(0, (stop_line - 1), stop_line, true))
      start0, stop0 = {start_line, 1}, {stop_line, len}
    else
      start0, stop0 = nil
    end
  end
  return start0, stop0
end
local function get_range(buf, start, stop)
  assert(buf, "get-range missing buf arg")
  assert(start, "get-range missing start arg")
  assert(stop, "get-range missing stop arg")
  local lines
  do
    local _16_, _17_ = start, stop
    if (((_G.type(_16_) == "table") and (nil ~= (_16_)[1]) and (nil ~= (_16_)[2])) and ((_G.type(_17_) == "table") and (nil ~= (_17_)[1]) and (nil ~= (_17_)[2]))) then
      local start_line = (_16_)[1]
      local start_col = (_16_)[2]
      local stop_line = (_17_)[1]
      local stop_col = (_17_)[2]
      lines = vim.api.nvim_buf_get_text(buf, (start_line - 1), (start_col - 1), (stop_line - 1), stop_col, {})
    elseif ((nil ~= _16_) and (nil ~= _17_)) then
      local start_line = _16_
      local stop_line = _17_
      lines = vim.api.nvim_buf_get_lines(buf, (start_line - 1), stop_line, true)
    else
      lines = nil
    end
  end
  return table.concat(lines, "\n")
end
local function get_selection()
  local start, stop = get_highlight()
  return get_range(0, start, stop)
end
local function get_buf(buf)
  return get_range(buf, 1, -1)
end
return {["get-range"] = get_range, ["get-selection"] = get_selection, ["get-buf"] = get_buf, ["get-highlight"] = get_highlight}