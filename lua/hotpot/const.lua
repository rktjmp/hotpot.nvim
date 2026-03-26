local _1_
do
  local path = vim.fn.stdpath("config")
  local case_2_ = vim.uv.fs_stat(path)
  if ((_G.type(case_2_) == "table") and true) then
    local _type = case_2_._type
    _1_ = vim.uv.fs_realpath(vim.fs.normalize(path))
  elseif (case_2_ == nil) then
    _1_ = path
  else
    _1_ = nil
  end
end
return {HOTPOT_CONFIG_CACHE_ROOT = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "hotpot", "opt", "hotpot-config-cache")), NVIM_CONFIG_ROOT = _1_}