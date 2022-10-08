local logger = require('gox.logger')
local utils = require('gox.utils')
local config = require('gox.config')
local revive = require('integrations.revive')
local gocritic = require('integrations.gocritic')
local gosec = require('integrations.gosec')

---@class Gox
local M = {}

--- @param opts GoxOptions
M.setup = function(opts)
	-- initializing the plugin
	config.setup(opts)

	local handle_data = function(data)
		if data then
			print(data)
			for _,v in ipairs(data) do
				if v then
					print(v)
				end
			end
		end
	end

	-- setting eventlisteners
	utils.new_autocmd('BufWritePost', 'codes.abe.gox', {
		pattern = "*.go",
		callback = function()
			vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), revive.namespace, 0, -1)
			vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), gocritic.namespace, 0, -1)
			vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), gosec.namespace, 0, -1)

			local revive_cmd = revive.cmd()
			table.insert(revive_cmd, utils.get_filepath())
			utils.run(
				revive_cmd,
				{
					stdout_buffered = true,
					-- on_exit = function(_, data)
					-- 	-- prints exit code
					-- 	print(data)
					-- end,
					on_stdout = revive.handle_stdout
					-- on_stdout = function(_, data)
					-- 	handle_data(data)
					-- end,
					-- on_stderr = function(_, data)
					-- 	handle_data(data)
					-- end
				}
			)

			local gocritic_cmd = gocritic.cmd()
			table.insert(gocritic_cmd, utils.get_filepath())
			utils.run(
				gocritic_cmd,
				{
					stderr_buffered = true,
					on_stderr = gocritic.handle_stderr
				}
			)

			local gosec_cmd = gosec.cmd()
			table.insert(gosec_cmd, utils.get_filedir())
			utils.run(
				gosec_cmd,
				{
					stdout_buffered = true,
					on_stdout = function(_, data)
						gosec.handle_stdout(data, utils.get_filepath())
					end
				}
			)
		end
	})

	-- adding commands
	utils.new_cmd(
		'GOXrevive',
		function()
			local cmd = revive.cmd()
			table.insert(cmd, utils.get_filepath())
			utils.run(
				cmd,
				{
					stdout_buffered = true,
					on_stdout = revive.handle_stdout,
				}
			)
		end,
		{}
	)

	utils.new_cmd(
		'GOXcritic',
		function()
			local cmd = gocritic.cmd()
			table.insert(cmd, utils.get_filepath())
			utils.run(
				cmd,
				{
					stderr_buffered = true,
					on_stderr = gocritic.handle_stderr,
				}
			)
		end,
		{}
	)

	utils.new_cmd(
		'GOXsec',
		function()
			local gosec_cmd = gosec.cmd()
			table.insert(gosec_cmd, utils.get_filedir())
			utils.run(
				gosec_cmd,
				{
					stdout_buffered = true,
					on_stdout = function(_, data)
						gosec.handle_stdout(data, utils.get_filepath())
					end
				}
			)
		end,
		{}
	)
end

return M

-- logger.warn(utils.get_filepath())
