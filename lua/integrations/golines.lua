local utils = require('gox.utils')
local logger = require('gox.logger')

---@class Golines
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.golines')

M.event = 'BufWritePre'

M.cmd = function()
	local cmd = {
		'golines',
		'-m',
		'80',
		'-t',
		'2',
		'--base-formatter',
		'gofumpt'
	}

	return cmd
end

M.handle_stderr = function(_, data)
	if not data then
		return
	end

	for _, line in ipairs(data) do
		if line == nil or line == '' or line == 'null' then
			goto continue
		end

		logger.warn(line)
		::continue::
	end
end

M.handle_stdout = function(_, data)
	if not data then
		return
	end

	local currPos = vim.api.nvim_win_get_cursor(0)

	vim.api.nvim_buf_set_lines(
		0,
		0,
		-1,
		false,
		data
	)
	local maxLines = vim.api.nvim_buf_line_count(0)

	if not (vim.fn.getline(maxLines) == '') then
		vim.fn.append(vim.fn.line('$'), '')
	else
		while vim.fn.getline(maxLines) == '' and vim.fn.getline(maxLines - 1) == '' do
			vim.api.nvim_buf_set_lines(
				0,
				-2,
				-1,
				false,
				{}
			)

			maxLines = vim.api.nvim_buf_line_count(0)
		end
	end

	-- old position outside of bounds
	if maxLines < currPos[1] then
		currPos[1] =  maxLines
	end

	vim.api.nvim_win_set_cursor(0, currPos)
	-- this is fishy, no idea rn why I need this
	vim.api.nvim_command("noautocmd :update")
end

M.execute = function()
	if not vim.api.nvim_buf_get_option(0, "modified") then
		return
	end

	local jobid = utils.run(
		M.cmd(),
		{
			stderr_buffered = true,
			on_stderr = M.handle_stderr,
			stdout_buffered = true,
			on_stdout = M.handle_stdout
		}
	)

	vim.fn.chansend(
		jobid, table.concat(
			vim.api.nvim_buf_get_lines(
				0,
				0,
				vim.api.nvim_buf_line_count(0),
				false
			),
			'\n'
		)
	)
	vim.fn.chanclose(jobid, 'stdin')
end

return M
