local _1_
do
  local path = vim.fn.stdpath("config")
  local case_2_ = vim.uv.fs_realpath(vim.fs.normalize(path))
  if (nil ~= case_2_) then
    local real_path = case_2_
    _1_ = real_path
  elseif (case_2_ == nil) then
    _1_ = path
  else
    _1_ = nil
  end
end
return {HOTPOT_CONFIG_CACHE_ROOT = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "hotpot", "opt", "hotpot-config-cache")), NVIM_CONFIG_ROOT = _1_}