local function pack(...)
  local tmp_9_ = {...}
  tmp_9_["n"] = select("#", ...)
  return tmp_9_
end
return {pack = pack}