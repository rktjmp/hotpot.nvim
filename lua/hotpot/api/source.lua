local function split_path(path)
  local sep = string.sub(package.config, 1, 1)
  local tbl_21_auto = {}
  local i_22_auto = 0
  for v in string.gmatch(path, ("[^" .. sep .. "]+")) do
    local val_23_auto = v
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
end
local function find_module_name_parts(path_parts, acc)
  local head = path_parts[1]
  local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(path_parts, 2)
  local _2_, _3_ = head, #rest
  if ((_2_ == "init.fnl") and (_3_ == 0)) then
    return acc
  elseif ((nil ~= _2_) and (_3_ == 0)) then
    local file = _2_
    local last = string.gsub(file, "%.fnl$", "")
    table.insert(acc, last)
    return acc
  elseif ((nil ~= _2_) and true) then
    local dir = _2_
    local _ = _3_
    table.insert(acc, dir)
    return find_module_name_parts(rest, acc)
  else
    return nil
  end
end
local function find_fnl_folder(path_parts)
  local head = path_parts[1]
  local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(path_parts, 2)
  if (head == nil) then
    return nil
  elseif (head == "fnl") then
    return find_module_name_parts(rest, {})
  elseif (nil ~= head) then
    local other = head
    return find_fnl_folder(rest)
  else
    return nil
  end
end
local function guess_module_name(full_path)
  local path = split_path(full_path)
  local mod = find_fnl_folder(path)
  if (mod == nil) then
    local modname = nil
    return modname
  elseif (nil ~= mod) then
    local list = mod
    local modname = table.concat(list, ".")
    return modname
  else
    return nil
  end
end
local function source_file(full_path)
  local modname = guess_module_name(full_path)
  if (modname == nil) then
    return print(("could not find module path for require " .. "command (not descendent of a 'fnl' dir?)"))
  elseif (nil ~= modname) then
    local any = modname
    package.loaded[modname] = nil
    return require(modname)
  else
    return nil
  end
end
return {source = source_file}