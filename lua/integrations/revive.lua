local config = require('gox.config')
local utils = require('gox.utils')

---@class Revive
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.revive')

M.event = 'BufWritePost'

M.cmd = function(filepath)
	local cmd = {
		'revive',
		'-formatter',
		'json',
		filepath,
	}

	if config.opts.revive.config then
		table.insert(cmd, "-config")
		table.insert(cmd, vim.fn.expand(config.opts.revive.config))
	end

	return cmd
end

M.handle_stdout = function(_, data)
	if not data then
		return
	end

	--[[
		[{"Severity":"warning","Failure":"should have a package comment","RuleName":"package-comments","Category":"comments","P
osition":{"Start":{"Filename":"XXX","Offset":0,"Line":1,"C
olumn":1},"End":{"Filename":"XXX","Offset":399,"Line":24,"
Column":2}},"Confidence":1,"ReplacementLine":""}]
	--]]
	local out = {}

	for _, line in ipairs(data) do
		if line == nil or line == '' or line == 'null' then
			goto continue
		end

		local decoded = vim.json.decode(line)
		for _, result in ipairs(decoded) do
			local msg = {
				bufnr = vim.api.nvim_get_current_buf(),
				lnum = result.Position.Start.Line - 1,
				col = 0,
				severity = vim.diagnostic.severity.WARN,
				source = "revive",
				message = result.Failure,
				user_data = {},
			}

			if result.Severity == "error" then
				msg.severity = vim.diagnostic.severity.ERROR
			end

			table.insert(out, msg)
		end

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
			stdout_buffered = true,
			on_stdout = M.handle_stdout
		}
	)
end

return M
