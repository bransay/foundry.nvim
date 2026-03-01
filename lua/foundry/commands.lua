local M = {}
local foundry_notify = require('foundry.notify')

local function create_coroutine_callback(f)
	return function()
		coroutine.wrap(f)()
	end
end

local function get_action_map(actions)
	local action_map = {}
	local action_names = {}

	for _, action in ipairs(actions) do
		local cmd = action.name:gsub(' ', '')
		action_map[cmd] = action.action
		table.insert(action_names, cmd)
	end

	return action_map, action_names
end

function M.init(menu, module)
	local action_map, action_names = get_action_map(module.actions())

	vim.api.nvim_create_user_command(
		'Foundry',
		function(opts)
			if #opts.fargs == 0 then
				create_coroutine_callback(function() menu.show(module) end)()
				return
			end

			local action = action_map[table.concat(opts.fargs, '')]
			if action then
				create_coroutine_callback(action)()
			else
				foundry_notify.notify('Unknown command: ' .. table.concat(opts.fargs, ''), { level = vim.log.levels.ERROR })
			end
		end,
		{
			nargs = '*',
			complete = function() return action_names end,
		}
	)
end

return M
