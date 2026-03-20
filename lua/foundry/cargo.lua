local M = {}
local foundry_notify = require('foundry.notify')
local foundry_options = require('foundry.options')

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
	return {}
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

function M.build()
	foundry_notify.notify('Build triggered', { level = vim.log.levels.INFO })
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
