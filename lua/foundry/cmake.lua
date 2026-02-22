local M = {}

local setup_opts = require('foundry').opts
local foundry_options = require('foundry.options')
local foundry_debug = require('foundry.debug')

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
	TARGET = { 'target', 'Target', foundry_options.select_picker(get_targets) },
	EXECUTABLE_PATH = { 'exe_path', 'Executable Path', foundry_options.file_picker() },
	EXECUTABLE_ARGUMENTS = { 'exe_args', 'Executable Arguments', foundry_options.input_picker() },
	DEBUGGER_LANGUAGE = { 'dbg_lang', 'Debugger Language', foundry_options.input_picker() },
	BUILD_BEFORE_RUN = { 'build_before_run', 'Build before run', foundry_options.boolean_picker() },
}
-- add debugger options
options = vim.tbl_deep_extend('force', options, foundry_debug.options)

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

local function get_target_info(build_dir, target)
	local api_dir = vim.fs.joinpath(build_dir, '.cmake', 'api', 'v1')
	local target_file = vim.fs.joinpath(api_dir, 'reply', 'target-' .. target .. '-*.json')
	target_file = vim.fn.glob(target_file, true, true)

	if #target_file == 0 then
		return nil
	end
	target_file = target_file[1]

	if not vim.fn.filereadable(target_file) then
		return nil
	end

	local contents = vim.fn.readfile(target_file)
	contents = table.concat(contents, '\n')

	return vim.json.decode(contents)
end

local function get_default_executable_path(build_dir, target)
	local target_properties = get_target_info(build_dir, target)
	if not target_properties then
		return nil
	end

	local artifacts = target_properties.artifacts
	if not artifacts then
		return nil
	end

	local artifact_path = nil
	for _, artifact in ipairs(artifacts) do
		if artifact and artifact.path then
			-- too ambiguous, multiple artifacts
			if artifact_path then
				return nil
			end
			artifact_path = artifact.path
		end
	end

	return vim.fs.joinpath(build_dir, artifact_path)
end

local function get_default_debugger_language(build_dir, target)
	local target_properties = get_target_info(build_dir, target)
	if not target_properties then
		return nil
	end

	local link_properties = target_properties.link
	if not link_properties then
		return nil
	end

	local language = link_properties.language
	return language
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
	local preset = get_option(options.PRESET)
	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	local target = get_option(options.TARGET)
	if not target then
		vim.notify('No active target', vim.log.levels.ERROR)
		return
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	local executable_path = get_option(options.EXECUTABLE_PATH, get_default_executable_path(build_dir, target))
	if not executable_path then
		vim.notify('No executable to run', vim.log.levels.ERROR)
		return
	end

	if not vim.fn.filereadable(executable_path) then
		vim.notify('Executable path is not readable', vim.log.levels.ERROR)
		return
	end

	local debugger_language = get_option(options.DEBUGGER_LANGUAGE, get_default_debugger_language(build_dir, target))
	if not debugger_language then
		vim.notify('No debugger language available', vim.log.levels.ERROR)
		return
	end

	local build_before_run = (get_option(options.BUILD_BEFORE_RUN, 'true') == 'true')
	if build_before_run then
		M.build()
	end

	-- maps cmake lanugage to dap equivalent
	local language_fts = {
		['CXX'] = 'cpp'
	}

	local language_ft = language_fts[debugger_language] or debugger_language
	local arguments = get_option(options.EXECUTABLE_ARGUMENTS, '')
	local args = vim.fn.split(arguments, ' ')

	local debug = require('foundry.debug')
	local result, reason = debug.debug(language_ft, executable_path, args)

	if not result then
		vim.notify(reason, vim.log.levels.ERROR)
	end
end

function M.run()
	local preset = get_option(options.PRESET)
	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	local target = get_option(options.TARGET)
	if not target then
		vim.notify('No active target', vim.log.levels.ERROR)
		return
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	assert(build_dir, 'build_dir must be valid')

	local executable_path = get_option(options.EXECUTABLE_PATH, get_default_executable_path(build_dir, target))
	if not executable_path then
		vim.notify('No executable to run', vim.log.levels.ERROR)
		return
	end

	if not vim.fn.filereadable(executable_path) then
		vim.notify('Executable path is not readable', vim.log.levels.ERROR)
		return
	end

	local build_before_run = (get_option(options.BUILD_BEFORE_RUN, 'true') == 'true')
	if build_before_run then
		M.build()
	end

	local arguments = get_option(options.EXECUTABLE_ARGUMENTS, '')
	local cmd = vim.fn.split(arguments, ' ')

	vim.notify('Running ' .. target)

	local task_name = 'Running ' .. preset
	table.insert(cmd, 1, executable_path)
	setup_opts.task(task_name, cmd)
end

function M.test()
	local preset = get_option(options.PRESET)
	if not preset then
		vim.notify('No preset selected', vim.log.levels.ERROR)
		return
	end

	local build_dir = get_option(options.BUILD_DIR, get_default_build_dir(preset))
	if not build_dir then
		vim.notify('Invalid build directory', vim.log.levels.ERROR)
		return
	end

	local result = vim.system({ "ctest", "--show-only=json-v1" }, {cwd = build_dir}):wait()
	if result.code ~= 0 then
		vim.notify('Test discovery failed', vim.log.levels.ERROR)
		return
	end

	local json_output = vim.json.decode(result.stdout)
	if not json_output or not json_output.tests then
		vim.notify('Invalid JSON output from ctest', vim.log.levels.ERROR)
		return
	end

	local discovered_tests = {}
	for _, test in ipairs(json_output.tests) do
		table.insert(discovered_tests, test.name)
	end

	local co = coroutine.running()
	vim.ui.select(
		discovered_tests,
		{
			prompt = 'Tests',
			format_item = function(item)
				return item
			end
		},
		function(_, idx)
			coroutine.resume(co, discovered_tests[idx])
		end
	)

	local test = coroutine.yield()
	if not test then
		return
	end

	local task_name = 'Running test: ' .. test
	local cmd = { 'ctest', '-R', test }
	setup_opts.task(task_name, cmd, build_dir)
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
