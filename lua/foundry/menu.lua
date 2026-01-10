local M = {}

local function format_actions(actions, icons, default_icon)
	local formatted_actions = {}

	for _, action in ipairs(actions) do
		local chosen_icon = default_icon
		for action_icon, icon in pairs(icons) do
			if string.lower(action):find(string.lower(action_icon), 1, true) then
				chosen_icon = icon
				break
			end
		end
		table.insert(formatted_actions, chosen_icon .. ' ' .. action)
	end

	return formatted_actions
end

function M.show(project_module)
	local co = coroutine.running()

	local project_actions = project_module.actions()

	local actions = {}
	local action_funcs = {}

	for _, action in ipairs(project_actions) do
		table.insert(actions, action.name)
		table.insert(action_funcs, action.action)
	end

	-- these are just for aesthetics
	local icons = {
		generate = '',
		build = '󱌣',
		debug = '󰃤',
		run = '',
		test = '󰙨',
	}
	local default_icon = ''

	local choices = format_actions(actions, icons, default_icon)

	vim.ui.select(
		choices,
		{},
		function(_, idx)
			local action = nil
			if idx then
				action = action_funcs[idx]
			end
			coroutine.resume(co, action)
		end
	)

	local action = coroutine.yield()
	if not action then
		return
	end

	action()
end

return M
