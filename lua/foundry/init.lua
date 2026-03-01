local M = {}
local foundry_notify = require('foundry.notify')

function M.setup(opts)
	coroutine.wrap(function()
		opts = opts or {}

		local default_opts = require('foundry.setup').get_default_opts()

		-- modify with integrations
		default_opts = require('foundry.overseer').modify(default_opts)

		M.opts = vim.tbl_deep_extend('force', default_opts, opts)

		local discover = require('foundry.discover')
		local project_module = discover.detect()

		if not project_module then
			vim.schedule(function()
				foundry_notify.notify('No project detected', { level = vim.log.levels.WARN })
			end)
			return
		end

		local menu = require('foundry.menu')
		require('foundry.commands').init(menu, project_module)
	end)()
end

return M