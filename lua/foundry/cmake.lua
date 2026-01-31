local M = {}

local setup_opts = require('foundry').opts
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

local get_targets_func = nil
local function get_targets()
	if not get_targets_func then
		return nil
	end
	return get_targets_func()
end

local options = {
	BUILD_DIR = { 'build_dir', 'Build Directory', foundry_options.directory_picker() },
	PRESET = { 'preset', 'Preset', foundry_options.select_picker(get_preset_options) },
	TARGET = { 'target', 'Target', foundry_options.select_picker(get_targets) }
}

local function get_option(option, default, show_ui)
	show_ui = show_ui or false
	---@type OptionOpts
	local opts = {}
	if show_ui then
		opts.force_ui = true
	end
	if option[3] then
		opts.picker = option[3]
	end
	if default then
		opts.default = default
	end
	return foundry_options.get(option[1], option[2], opts)
end

local function get_default_build_dir(preset)
	return vim.fs.joinpath(vim.fn.getcwd(), 'build', preset)
end

get_targets_func = function()
	local preset = get_option(options.PRESET)
	if not preset then
		vim.notify('Choosing targets requires preset', vim.log.levels.ERROR)
		return nil
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	-- use the cmake file api to find all targets
	local api_dir = vim.fs.joinpath(build_dir, '.cmake', 'api', 'v1')
	local query_dir = vim.fs.joinpath(api_dir, 'query', 'client-foundry.nvim')
	vim.fn.mkdir(query_dir, '-p')
	local query_file = vim.fs.joinpath(query_dir, 'codemodel-v2')
	if vim.fn.writefile({}, query_file) ~= 0 then
		return nil
	end

	M.generate()

	-- look for the reply
	local codemodel_file = vim.fs.joinpath(api_dir, 'reply', 'codemodel-v2-*.json')
	codemodel_file = vim.fn.glob(codemodel_file, true, true)

	if #codemodel_file == 0 then
		vim.notify('Cmake file api failure - no response', vim.log.levels.ERROR)
		return nil
	end
	codemodel_file = codemodel_file[1]

	if not vim.fn.filereadable(codemodel_file) then
		vim.notify('Cmake file api failure - could not read response', vim.log.levels.ERROR)
		return nil
	end

	local contents = vim.fn.readfile(codemodel_file)
	contents = table.concat(contents, '\n')

	local function invalid_response()
		vim.notify('Cmake file api failure - invalid response', vim.log.levels.ERROR)
		return nil
	end

	local codemodel = vim.json.decode(contents)
	if not codemodel then
		return invalid_response()
	end

	local configurations = codemodel.configurations
	if not configurations then
		return invalid_response()
	end

	local targets = {}
	for _, configuration in ipairs(configurations) do
		if not configuration then
			return invalid_response()
		end

		local configuration_targets = configuration.targets
		if not configuration_targets then
			return invalid_response()
		end

		for _, target in ipairs(configuration_targets) do
			local target_name = target.name
			if not target_name then
				return invalid_response()
			end

			table.insert(targets, target_name)
		end
	end

	return targets
end

function M.generate()
	local preset = get_option(options.PRESET)

	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	-- TODO: let's do persistent notifications that last until the preset is complete
	vim.notify('Generating preset: ' .. preset .. '...')

	-- kick off generating task
	local task_name = 'Generating preset: ' .. preset
	local result = setup_opts.task(task_name, { 'cmake', '--preset', preset, '-B', build_dir })

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

	local target = get_option(options.TARGET)
	if not target then
		vim.notify('No active target', vim.log.levels.ERROR)
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	-- TODO: let's do persistent notifications that last until the preset is complete
	vim.notify('Building target: ' .. target .. '...')

	-- kick off generating task
	local task_name = 'Building target: ' .. target
	local result = setup_opts.task(task_name, { 'cmake', '--build', build_dir, '--target', target })

	if result then
		vim.notify(task_name .. ' succeeded')
	else
		vim.notify(task_name .. ' failed', vim.log.levels.ERROR)
	end
end

function M.build_all()
	local preset = get_option(options.PRESET)

	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	-- TODO: let's do persistent notifications that last until the preset is complete
	vim.notify('Building preset: ' .. preset .. '...')

	-- kick off generating task
	local task_name = 'Building preset: ' .. preset
	local result = setup_opts.task(task_name, { 'cmake', '--build', build_dir })

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

	get_option(choice, nil, true)
end

function M.actions()
	return {
		{ name = 'Generate', action = M.generate },
		{ name = 'Build', action = M.build },
		{ name = 'Build All', action = M.build_all },
		{ name = 'Debug', action = M.debug },
		{ name = 'Run', action = M.run },
		{ name = 'Test', action = M.test },
		{ name = 'Options', action = M.options },
	}
end

return M
