local function eval_operator()
  local _let_1_ = require("hotpot.api.eval")
  local eval_range = _let_1_["eval-range"]
  local start = vim.api.nvim_buf_get_mark(0, "[")
  local stop = vim.api.nvim_buf_get_mark(0, "]")
  local _2_, _3_ = eval_range(0, start, stop)
  if ((_2_ == false) and (nil ~= _3_)) then
    local err = _3_
    return error(err)
  else
    return nil
  end
end
local function eval_operator_bang()
  vim.go.operatorfunc = "v:lua.require'hotpot.api.command'.eval_operator"
  return vim.api.nvim_feedkeys("g@", "n", false)
end
local function fnl(start, stop, code, range_count)
  local _let_5_ = require("hotpot.api.eval")
  local eval_range = _let_5_["eval-range"]
  local eval_string = _let_5_["eval-string"]
  local _let_6_ = require("hotpot.fennel")
  local view = _let_6_["view"]
  local print_result
  local function _7_(_241)
    local _8_
    do
      local tbl_17_auto = {}
      local i_18_auto = #tbl_17_auto
      for _, v in ipairs(_241) do
        local val_19_auto = view(v)
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      _8_ = tbl_17_auto
    end
    return print(table.concat(_8_, ", "))
  end
  print_result = _7_
  local eval
  do
    local _10_ = {(2 == range_count), code}
    if ((_G.type(_10_) == "table") and ((_10_)[1] == true) and ((_10_)[2] == "=")) then
      local function _11_()
        local _12_ = {eval_range(0, start, stop)}
        if ((_G.type(_12_) == "table") and ((_12_)[1] == true)) then
          local rest = {select(2, (table.unpack or _G.unpack)(_12_))}
          return print_result(rest)
        elseif ((_G.type(_12_) == "table") and ((_12_)[1] == false) and (nil ~= (_12_)[2])) then
          local e = (_12_)[2]
          return false, e
        else
          return nil
        end
      end
      eval = _11_
    elseif ((_G.type(_10_) == "table") and ((_10_)[1] == true) and ((_10_)[2] == "")) then
      local function _14_()
        return eval_range(0, start, stop)
      end
      eval = _14_
    else
      local function _15_()
        local _ = (_10_)[1]
        return ("=" == string.sub(code, 1, 1))
      end
      if (((_G.type(_10_) == "table") and true and ((_10_)[2] == code)) and _15_()) then
        local _ = (_10_)[1]
        local function _16_()
          local _17_ = {eval_string(string.sub(code, 2, -1))}
          if ((_G.type(_17_) == "table") and ((_17_)[1] == true)) then
            local rest = {select(2, (table.unpack or _G.unpack)(_17_))}
            return print_result(rest)
          elseif ((_G.type(_17_) == "table") and ((_17_)[1] == false) and (nil ~= (_17_)[2])) then
            local e = (_17_)[2]
            return false, e
          else
            return nil
          end
        end
        eval = _16_
      elseif ((_G.type(_10_) == "table") and true and ((_10_)[2] == code)) then
        local _ = (_10_)[1]
        local function _19_()
          return eval_string(code)
        end
        eval = _19_
      else
        eval = nil
      end
    end
  end
  local _21_, _22_ = eval()
  if ((_21_ == false) and (nil ~= _22_)) then
    local err = _22_
    return error(err)
  else
    return nil
  end
end
local function fnlfile(file)
  local _let_24_ = require("hotpot.api.eval")
  local eval_file = _let_24_["eval-file"]
  local _25_, _26_ = eval_file(file)
  if ((_25_ == false) and (nil ~= _26_)) then
    local err = _26_
    return error(err)
  else
    return nil
  end
end
local function fnldo(start, stop, code)
  assert((code and (code ~= "")), "fnldo: code must not be blank")
  local _let_28_ = require("hotpot.fennel")
  local eval = _let_28_["eval"]
  local _let_29_ = require("hotpot.runtime")
  local traceback = _let_29_["traceback"]
  local codestr = ("(fn [line linenr] " .. code .. ")")
  local func
  do
    local _30_, _31_ = nil, nil
    local function _32_()
      return eval(codestr, {filename = "hotpot-fnldo"})
    end
    _30_, _31_ = xpcall(_32_, traceback)
    if ((_30_ == true) and (nil ~= _31_)) then
      local func0 = _31_
      func = func0
    elseif ((_30_ == false) and (nil ~= _31_)) then
      local err = _31_
      func = error(err)
    else
      func = nil
    end
  end
  for i = start, stop do
    local line = (vim.api.nvim_buf_get_lines(0, (i - 1), i, false))[1]
    vim.api.nvim_buf_set_lines(0, (i - 1), i, false, {func((line or ""), i)})
  end
  return nil
end
return {["eval-operator"] = eval_operator, eval_operator = eval_operator, ["eval-operator-bang"] = eval_operator_bang, fnl = fnl, fnlfile = fnlfile, fnldo = fnldo}