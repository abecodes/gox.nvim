local M = {}

M.name = 'gox.nvim'

--- @class GoxOptions
local defaults = {
	revive = {
		enabled = false,
		config = "", -- empty string for default $HOME/revive.toml, else path to config
	},
	gocritic = {
		enabled = false,
	},
	gosec = {
		enabled = false,
		show_errors = false,
	},
	golangci = {
		enabled = true,
		config = "", -- empty string for default behavior
	},
}

--- @type GoxOptions
M.opts = {}
M.integrations = {}
M.debug = true

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
	for k,v in pairs(M.opts) do
		if v.enabled then
			M.integrations[k] = require('integrations.'..k)
		end
	end
end

return M
