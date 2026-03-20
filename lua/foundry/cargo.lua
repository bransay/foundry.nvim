local M = {}
local foundry_notify = require('foundry.notify')
local foundry_options = require('foundry.options')
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

local function get_target_options()
	local result = vim.system({ 'cargo', 'metadata', '--format-version=1', '--no-deps' }, { cwd = vim.fn.getcwd() }):wait()

	if result.code ~= 0 then
		foundry_notify.notify('cargo metadata failed: ' .. (result.stderr or 'unknown error'), { level = vim.log.levels.ERROR })
		return {}
	end

	local metadata = vim.json.decode(result.stdout)
	if not metadata then
		foundry_notify.notify('cargo metadata returned invalid JSON', { level = vim.log.levels.ERROR })
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
}

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
		{ name = 'Options', action = M.options },
	}
end

return M
