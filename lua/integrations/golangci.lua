local config = require('gox.config')
local utils = require('gox.utils')

---@class Golangci
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.golangci')

M.cmd = function(filedir)
	local cmd = {
		'golangci-lint',
		'run',
		'--out-format',
		'json',
		filedir,
	}

	if config.opts.golangci.config then
		table.insert(cmd, "-c")
		table.insert(cmd, vim.fn.expand(config.opts.golangci.config))
	end

	return cmd
end

M.handle_stdout = function(_, data, filename)
	if not data then
		return
	end

	--[[
		{"Issues":
			[
				{
					"FromLinter":"ineffassign",
					"Text":"ineffectual assignment to ctx",
					"Severity":"error",
					"SourceLines":[
						"\t\tctx, span := c.trc.Tracer(\"\").Start("
					],
					"Replacement":null,
					"Pos":{
						"Filename":"msg.go",
						"Offset":4435,
						"Line":169,
						"Column":3
					},
					"ExpectNoLint":false,
					"ExpectedNoLintLinter":""
				}
			],
			...
	--]]
	local out = {}

	for _, line in ipairs(data) do
		if line == nil or line == '' or line == 'null' then
			goto continue
		end

		local decoded = vim.json.decode(line)
		for _, issue in ipairs(decoded.Issues) do
			if not issue.Pos.Filename == filename then
				goto continue
			end
			local msg = {
				bufnr = vim.api.nvim_get_current_buf(),
				lnum = issue.Pos.Line - 1,
				col = 0,
				severity = vim.diagnostic.severity.WARN,
				source = issue.FromLinter,
				message = issue.Text,
				user_data = {},
			}

			if issue.Severity == "error" then
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
		M.cmd(utils.get_filedir()),
		{
			stdout_buffered = true,
			on_stdout = function(_, data)
				M.handle_stdout(_, data, utils.get_filename())
			end
		}
	)
end

return M
