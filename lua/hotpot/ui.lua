local function ui_select_sync(choices, options, callback)
  if (nil == callback) then
    _G.error("Missing argument callback on fnl/hotpot/ui.fnl:1", 2)
  else
  end
  if (nil == options) then
    _G.error("Missing argument options on fnl/hotpot/ui.fnl:1", 2)
  else
  end
  if (nil == choices) then
    _G.error("Missing argument choices on fnl/hotpot/ui.fnl:1", 2)
  else
  end
  local selected_3f = false
  local function _4_(choice, index)
    selected_3f = true
    return callback(choice, index)
  end
  vim.ui.select(choices, options, _4_)
  local function _5_()
    return selected_3f
  end
  return vim.wait(math.huge, _5_)
end
return {["ui-select-sync"] = ui_select_sync}