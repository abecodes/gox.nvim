local utils = require('gox.utils')

---@class Gocritic
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.gocritic')

M.cmd = function(filepath)
	local cmd = {
		'gocritic',
		'check',
		'-enableAll',
		filepath,
	}

	return cmd
end

M.handle_stderr = function(_, data)
	if not data then
		return
	end

	--[[
		$GOROOT/src/fmt/fmt_test.go:1270:6: importShadow: shadow of imported package 'bytes'
	--]]
	local out = {}

	for _, line in ipairs(data) do
		if line == nil or line == "" then
			goto continue
		end

		local critic = utils.split(line, ':')
		-- local critic = {
		-- 	file = c[1],
		-- 	row = c[2],
		-- 	col = c[3],
		-- 	rule = c[4],
		-- 	failure = c[5],
		-- }

		table.insert(out, {
			bufnr = vim.api.nvim_get_current_buf(),
			lnum = critic[2] - 1,
			col = 0,
			severity = vim.diagnostic.severity.WARN,
			source = "gocritic",
			message = critic[5],
			user_data = {},
		})

		-- if critic[4] == "xxx" then
		-- 	msg.severity = vim.diagnostic.severity.ERROR
		-- end

		::continue::
	end

	vim.diagnostic.set(M.namespace, vim.api.nvim_get_current_buf(), out, {})
end

M.clear_namespace = function()
	vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), M.namespace, 0, -1)
end

M.execute = function()
	M.clear_namespace()
	utils.run(
		M.cmd(utils.get_filepath()),
		{
			stderr_buffered = true,
			on_stderr = M.handle_stderr
		}
	)
end

return M
