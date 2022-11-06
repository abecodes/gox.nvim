local utils = require('gox.utils')
local config = require('gox.config')

---@class Gox
local M = {}

--- @param opts GoxOptions
M.setup = function(opts)
	-- initializing the plugin
	config.setup(opts)

	for k,integration in pairs(config.integrations) do
		-- setting eventlisteners
		utils.new_autocmd('BufWritePost', 'codes.abe.gox.'..k, {
			pattern = "*.go",
			callback = function()
				integration.execute()
			end
		})

		-- adding commands
		utils.new_cmd(
			'GOX'..k,
			function()
				integration.execute()
			end,
			{}
		)
	end
end

return M
