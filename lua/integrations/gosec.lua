local utils = require('gox.utils')

---@class Gosec
local M = {}

M.namespace = vim.api.nvim_create_namespace('codes.abe.gox.gosec')

M.cmd = function()
	local cmd = {
		'gosec',
		'-quiet',
		'-fmt',
		'json'
	}

	return cmd
end

M.handle_stdout = function(data, filepath)
	if not data then
		return
	end

	-- TODO: find a better way
	local str = ""
	for _, line in ipairs(data) do
		str = str .. line
	end

	--[[
		{
	"Golang errors": {
		"/path/to/file.go": [
			{
				"line": 5,
				"column": 2,
				"error": "\"time\" imported but not used"
			},
			{
				"line": 48,
				"column": 3,
				"error": "undeclared name: fmt"
			},
			{
				"line": 51,
				"column": 3,
				"error": "undeclared name: fmt"
			},
			{
				"line": 54,
				"column": 3,
				"error": "undeclared name: fmt"
			}
		]
	},
	"Issues": [
		{
			"severity": "LOW",
			"confidence": "HIGH",
			"cwe": {
				"id": "703",
				"url": "https://cwe.mitre.org/data/definitions/703.html"
			},
			"rule_id": "G104",
			"details": "Errors unhandled.",
			"file": "/path/to/file.go",
			"code": "71: func (c *client) Publish(subj string, data *[]byte) {\n72: \tc.conn.Publish(subj, *data)\n73: }\n",
			"line": "72",
			"column": "2",
			"nosec": false,
			"suppressions": null
		}
	],
	"Stats": {
		"files": 1,
		"lines": 161,
		"nosec": 0,
		"found": 1
	},
	"GosecVersion": "dev"
}
	--]]
	local out = {}

	local decoded = vim.json.decode(str)

	for _, issue in ipairs(decoded.Issues) do
		if not issue.file == filepath then
			goto issue_continue
		end

		local msg = {
			bufnr = vim.api.nvim_get_current_buf(),
			lnum = issue.line - 1,
			col = 0,
			severity = vim.diagnostic.severity.ERROR,
			source = "gosec",
			message = issue.details,
			user_data = {},
		}

		if issue.severity == "LOW" then
			msg.severity = vim.diagnostic.severity.WARN
		end

		table.insert(out, msg)
		::issue_continue::
	end

	if decoded["Golang errors"][filepath] ~= nil then
		for _, err in ipairs(decoded["Golang errors"][filepath]) do
			local msg = {
				bufnr = vim.api.nvim_get_current_buf(),
				lnum = err.line - 1,
				col = 0,
				severity = vim.diagnostic.severity.ERROR,
				source = "gosec",
				message = err.error,
				user_data = {},
			}

			table.insert(out, msg)
		end
	end

	vim.diagnostic.set(M.namespace, vim.api.nvim_get_current_buf(), out, {})
end

return M
