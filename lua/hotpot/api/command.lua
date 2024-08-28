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
      local tbl_21_auto = {}
      local i_22_auto = 0
      for _, v in ipairs(_241) do
        local val_23_auto = view(v)
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      _8_ = tbl_21_auto
    end
    return print(table.concat(_8_, ", "))
  end
  print_result = _7_
  local eval
  do
    local _10_ = {(2 == range_count), code}
    if ((_10_[1] == true) and (_10_[2] == "=")) then
      local function _11_()
        local _12_ = {eval_range(0, start, stop)}
        if (_12_[1] == true) then
          local rest = {select(2, (table.unpack or _G.unpack)(_12_))}
          return print_result(rest)
        elseif ((_12_[1] == false) and (nil ~= _12_[2])) then
          local e = _12_[2]
          return false, e
        else
          return nil
        end
      end
      eval = _11_
    elseif ((_10_[1] == true) and (_10_[2] == "")) then
      local function _14_()
        return eval_range(0, start, stop)
      end
      eval = _14_
    else
      local and_15_ = ((_G.type(_10_) == "table") and true and (_10_[2] == code))
      if and_15_ then
        local _ = _10_[1]
        and_15_ = ("=" == string.sub(code, 1, 1))
      end
      if and_15_ then
        local _ = _10_[1]
        local function _17_()
          local _18_ = {eval_string(string.sub(code, 2, -1))}
          if (_18_[1] == true) then
            local rest = {select(2, (table.unpack or _G.unpack)(_18_))}
            return print_result(rest)
          elseif ((_18_[1] == false) and (nil ~= _18_[2])) then
            local e = _18_[2]
            return false, e
          else
            return nil
          end
        end
        eval = _17_
      elseif (true and (_10_[2] == code)) then
        local _ = _10_[1]
        local function _20_()
          return eval_string(code)
        end
        eval = _20_
      else
        eval = nil
      end
    end
  end
  local _22_, _23_ = eval()
  if ((_22_ == false) and (nil ~= _23_)) then
    local err = _23_
    return error(err)
  else
    return nil
  end
end
local function fnlfile(file)
  local _let_25_ = require("hotpot.api.eval")
  local eval_file = _let_25_["eval-file"]
  local _26_, _27_ = eval_file(file)
  if ((_26_ == false) and (nil ~= _27_)) then
    local err = _27_
    return error(err)
  else
    return nil
  end
end
local function fnldo(start, stop, code)
  assert((code and (code ~= "")), "Fnldo: missing expression to execute!")
  local _let_29_ = require("hotpot.fennel")
  local eval = _let_29_["eval"]
  local _let_30_ = require("hotpot.runtime")
  local traceback = _let_30_["traceback"]
  local codestr = ("(fn [line linenr] " .. code .. ")")
  local func
  do
    local _31_, _32_ = nil, nil
    local function _33_()
      return eval(codestr, {filename = "hotpot-fnldo"})
    end
    _31_, _32_ = xpcall(_33_, traceback)
    if ((_31_ == true) and (nil ~= _32_)) then
      local func0 = _32_
      func = func0
    elseif ((_31_ == false) and (nil ~= _32_)) then
      local err = _32_
      func = error(err)
    else
      func = nil
    end
  end
  for i = start, stop do
    local line = vim.api.nvim_buf_get_lines(0, (i - 1), i, false)[1]
    vim.api.nvim_buf_set_lines(0, (i - 1), i, false, {func((line or ""), i)})
  end
  return nil
end
return {["eval-operator"] = eval_operator, eval_operator = eval_operator, ["eval-operator-bang"] = eval_operator_bang, fnl = fnl, fnlfile = fnlfile, fnldo = fnldo}