local M = {}

local opts = require('foundry').opts
local foundry_options = require('foundry.options')

local function get_preset_options()
	local list_presets_output = vim.fn.systemlist('cmake --list-presets')

	local results = {}
	for _, item in ipairs(list_presets_output) do
		local pattern = '^%s*"([^"]+)"%s*%-?%s*(.*)$'
		local name, nice_name = item:match(pattern)
		if name then
			table.insert(
				results,
				{
					name,
					nice_name ~= '' and nice_name or name
				}
			)
		end
	end

	return results
end

local options = {
	PRESET = { 'preset', 'Preset', get_preset_options }
}

local function get_option(option, show_ui)
	show_ui = show_ui or false
	local opts = {}
	if show_ui then
		opts.force_ui = true
	end
	if option[3] then
		opts.choices = option[3]
	end
	return foundry_options.get(option[1], option[2], opts)
end

function M.generate()
	local preset = get_option(options.PRESET)

	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	-- TODO: let's do persistent notifications that last until the preset is complete
	vim.notify('Generating preset: ' .. preset .. '...')

	-- kick off generating task
	local task_name = 'Generating preset: ' .. preset
	local result = opts.task(task_name, { 'cmake', '--preset', preset })

	if result then
		vim.notify(task_name .. ' succeeded')
	else
		vim.notify(task_name .. ' failed', vim.log.levels.ERROR)
	end
end

function M.build()
	local preset = get_option(options.PRESET)

	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	-- TODO: let's do persistent notifications that last until the preset is complete
	vim.notify('Building preset: ' .. preset .. '...')

	-- kick off generating task
	local task_name = 'Building preset: ' .. preset
	local result = opts.task(task_name, { 'cmake', '--build', '--preset', preset })

	if result then
		vim.notify(task_name .. ' succeeded')
	else
		vim.notify(task_name .. ' failed', vim.log.levels.ERROR)
	end
end

function M.debug()
	vim.notify('Chose debug!')
end

function M.run()
	vim.notify('Chose run!')
end

function M.test()
	vim.notify('Chose test!')
end

function M.options()
	local menu_options = {}
	for _, item in pairs(options) do
		table.insert(menu_options, item)
	end

	local co = coroutine.running()
	vim.ui.select(
		menu_options,
		{
			prompt = 'Options',
			format_item = function(item)
				return item[2]
			end
		},
		function(_, idx)
			coroutine.resume(co, idx)
		end
	)

	local choice = coroutine.yield();
	if not choice then
		return
	end
	choice = menu_options[choice]

	get_option(choice, true)
end

function M.actions()
	return {
		{ name = 'Generate', action = M.generate },
		{ name = 'Build', action = M.build },
		{ name = 'Debug', action = M.debug },
		{ name = 'Run', action = M.run },
		{ name = 'Test', action = M.test },
		{ name = 'Options', action = M.options },
	}
end

return M
