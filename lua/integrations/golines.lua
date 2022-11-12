local utils = require('gox.utils')
local logger = require('gox.logger')

---@class Golines
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.golines')

M.event = 'BufWritePre'

M.execute = function()
	vim.api.nvim_command(":%!golines -m 80 -t 2 --base-formatter gofumpt")
end

return M
