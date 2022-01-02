vim.cmd("set rtp+=/hotpot")
vim.cmd("set rtp+=/test")

if vim.fn.empty(vim.fn.glob("/hotpot")) > 0 then
  vim.cmd("cq 255")
end

if vim.fn.empty(vim.fn.glob("/test")) > 0 then
  vim.cmd("cq 255")
end
