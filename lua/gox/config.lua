local M = {}

M.name = 'gox.nvim'

--- @class GoxOptions
local defaults = {
	revive = {
		enabled = true,
		config = "", -- empty string for default $HOME/revive.toml, else path to config
	},
	gocritic = {
		enabled = true,
	},
	gosec = {
		enabled = true,
	},
}

--- @type GoxOptions
M.opts = {}
M.debug = true

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
