local M = {}
local foundry_notify = require('foundry.notify')
local foundry_options = require('foundry.options')
local foundry_debug = require('foundry.debug')
local setup_opts = require('foundry').opts

function M.detect(root)
	local cargo_file = vim.fs.joinpath(root, 'Cargo.toml')
	return vim.fn.filereadable(cargo_file) == 1
end

local function profile_picker(prompt, default)
	local result = foundry_options.select_picker(function()
		return {
			{ 'dev', 'dev' },
			{ 'release', 'release' },
			{ 'test', 'test' },
			{ 'bench', 'bench' },
			{ '__custom__', 'User-defined' },
		}
	end)(prompt, default)
	if result == '__custom__' then
		return foundry_options.input_picker()(prompt, default)
	end
	return result
end

local function get_metadata()
	local result = vim.system({ 'cargo', 'metadata', '--format-version=1', '--no-deps' }, { cwd = vim.fn.getcwd() }):wait()

	if result.code ~= 0 then
		return nil
	end

	return vim.json.decode(result.stdout)
end

local function get_target_options()
	local metadata = get_metadata()
	if not metadata then
		foundry_notify.notify('cargo metadata failed', { level = vim.log.levels.ERROR })
		return {}
	end

	local targets = {}
	for _, package in ipairs(metadata.packages or {}) do
		for _, target in ipairs(package.targets or {}) do
			if vim.list_contains(target.kind or {}, 'bin') then
				table.insert(targets, { target.name, target.name })
			end
		end
	end

	if #targets == 0 then
		return {}
	end

	table.sort(targets, function(a, b) return a[1] < b[1] end)
	return targets
end

local options = {
	PROFILE = { 'profile', 'Profile', profile_picker },
	TARGET = { 'target', 'Target', foundry_options.select_picker(get_target_options) },
	EXECUTABLE_PATH = { 'exe_path', 'Executable Path', foundry_options.file_picker() },
	EXECUTABLE_ARGUMENTS = { 'exe_args', 'Executable Arguments', foundry_options.input_picker() },
	BUILD_BEFORE_RUN = { 'build_before_run', 'Build before run', foundry_options.boolean_picker() },
}
options = vim.tbl_deep_extend('force', options, foundry_debug.options)

local function get_option(option, default, show_ui)
	show_ui = show_ui or false
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

local function get_build_context()
	local profile = get_option(options.PROFILE)
	if not profile then
		foundry_notify.notify('No profile selected', { level = vim.log.levels.ERROR })
		return nil, nil
	end

	local target = get_option(options.TARGET)
	if not target then
		foundry_notify.notify('No target selected', { level = vim.log.levels.ERROR })
		return nil, nil
	end

	return profile, target
end

local function get_default_executable_path(profile, target)
	local PROFILE_TO_DIR = {
		dev = 'debug',
		test = 'debug',
		release = 'release',
		bench = 'release',
	}

	local metadata = get_metadata()
	if not metadata then
		foundry_notify.notify('cargo metadata failed', { level = vim.log.levels.ERROR })
		return nil
	end

	if not metadata.target_directory then
		foundry_notify.notify('cargo metadata missing target_directory', { level = vim.log.levels.ERROR })
		return nil
	end

	local exe_name = target
	if vim.fn.has('win32') == 1 then
		exe_name = exe_name .. '.exe'
	end

	local profile_dir = PROFILE_TO_DIR[profile] or profile
	return vim.fs.joinpath(metadata.target_directory, profile_dir, exe_name)
end

function M.build()
	local profile, target = get_build_context()
	if not profile or not target then
		return
	end

	local task_name = 'Building ' .. target .. ' (' .. profile .. ')'
	local id = foundry_notify.notify(task_name .. '...', { keep = true, spinner = true })
	local result = setup_opts.task(task_name, { 'cargo', 'build', '--profile', profile, '--bin', target })
	foundry_notify.dismiss(id)

	if result then
		foundry_notify.notify(task_name .. ' succeeded', { level = vim.log.levels.INFO })
	else
		foundry_notify.notify(task_name .. ' failed', { level = vim.log.levels.ERROR })
	end
end

function M.build_all()
	local profile = get_option(options.PROFILE)
	if not profile then
		foundry_notify.notify('No profile selected', { level = vim.log.levels.ERROR })
		return
	end

	local task_name = 'Building all targets (' .. profile .. ')'
	local id = foundry_notify.notify(task_name .. '...', { keep = true, spinner = true })
	local result = setup_opts.task(task_name, { 'cargo', 'build', '--profile', profile, '--all-targets' })
	foundry_notify.dismiss(id)

	if result then
		foundry_notify.notify(task_name .. ' succeeded', { level = vim.log.levels.INFO })
	else
		foundry_notify.notify(task_name .. ' failed', { level = vim.log.levels.ERROR })
	end
end

function M.check()
	local profile = get_option(options.PROFILE)
	if not profile then
		foundry_notify.notify('No profile selected', { level = vim.log.levels.ERROR })
		return
	end

	local task_name = 'Checking (' .. profile .. ')'
	local id = foundry_notify.notify(task_name .. '...', { keep = true, spinner = true })
	local result = setup_opts.task(task_name, { 'cargo', 'check', '--profile', profile })
	foundry_notify.dismiss(id)

	if result then
		foundry_notify.notify(task_name .. ' succeeded', { level = vim.log.levels.INFO })
	else
		foundry_notify.notify(task_name .. ' failed', { level = vim.log.levels.ERROR })
	end
end

function M.run()
	local profile, target = get_build_context()
	if not profile or not target then
		return
	end

	local task_name = 'Running ' .. target .. ' (' .. profile .. ')'
	local result = setup_opts.task(task_name, { 'cargo', 'run', '--profile', profile, '--bin', target })
end

function M.clean()
	local task_name = 'Cleaning'
	local id = foundry_notify.notify(task_name .. '...', { keep = true, spinner = true })
	local result = setup_opts.task(task_name, { 'cargo', 'clean' })
	foundry_notify.dismiss(id)

	if result then
		foundry_notify.notify(task_name .. ' succeeded', { level = vim.log.levels.INFO })
	else
		foundry_notify.notify(task_name .. ' failed', { level = vim.log.levels.ERROR })
	end
end

function M.test()
	local profile = get_option(options.PROFILE)
	if not profile then
		foundry_notify.notify('No profile selected', { level = vim.log.levels.ERROR })
		return
	end

	local task_name = 'Testing (' .. profile .. ')'
	local id = foundry_notify.notify(task_name .. '...', { keep = true, spinner = true })
	local result = setup_opts.task(task_name, { 'cargo', 'test', '--profile', profile })
	foundry_notify.dismiss(id)

	if result then
		foundry_notify.notify(task_name .. ' succeeded', { level = vim.log.levels.INFO })
	else
		foundry_notify.notify(task_name .. ' failed', { level = vim.log.levels.ERROR })
	end
end

function M.debug()
	local profile, target = get_build_context()
	if not profile or not target then
		return
	end

	local executable_path = get_option(options.EXECUTABLE_PATH, get_default_executable_path(profile, target))
	if not executable_path then
		foundry_notify.notify('No executable path available', { level = vim.log.levels.ERROR })
		return
	end

	if not vim.fn.filereadable(executable_path) then
		foundry_notify.notify('Executable does not exist: ' .. executable_path, { level = vim.log.levels.ERROR })
		return
	end

	local build_before_run = get_option(options.BUILD_BEFORE_RUN, 'true') == 'true'
	if build_before_run then
		M.build()
	end

	local arguments = get_option(options.EXECUTABLE_ARGUMENTS, '') or ''
	local args = vim.fn.split(arguments, ' ')

	local debug = require('foundry.debug')
	local result, reason = debug.debug('rust', executable_path, args)

	if not result then
		foundry_notify.notify(reason, { level = vim.log.levels.ERROR })
	end
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

	local choice = coroutine.yield()
	if not choice then
		return
	end
	choice = menu_options[choice]

	get_option(choice, nil, true)
end

function M.actions()
	return {
		{ name = 'Build', action = M.build },
		{ name = 'Build All', action = M.build_all },
		{ name = 'Check', action = M.check },
		{ name = 'Clean', action = M.clean },
		{ name = 'Debug', action = M.debug },
		{ name = 'Run', action = M.run },
		{ name = 'Test', action = M.test },
		{ name = 'Options', action = M.options },
	}
end

return M
