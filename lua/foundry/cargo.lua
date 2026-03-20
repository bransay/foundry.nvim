local M = {}
local foundry_notify = require('foundry.notify')
local foundry_options = require('foundry.options')

function M.detect(root)
	local cargo_file = vim.fs.joinpath(root, 'Cargo.toml')
	return vim.fn.filereadable(cargo_file) == 1
end

local function get_profile_options()
	local result = vim.system({ 'cargo', 'metadata', '--format-version=1', '--no-deps' }, { cwd = vim.fn.getcwd() }):wait()

	if result.code ~= 0 then
		return {}
	end

	local metadata = vim.json.decode(result.stdout)
	if not metadata or not metadata.profiles then
		return {}
	end

	local results = {}
	for profile_name, _ in pairs(metadata.profiles) do
		table.insert(results, { profile_name, profile_name })
	end

	table.sort(results, function(a, b) return a[1] < b[1] end)

	return results
end

local function get_target_options()
	return {}
end

local options = {
	PROFILE = { 'profile', 'Profile', foundry_options.select_picker(get_profile_options) },
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

function M.actions()
	return {
		{ name = 'Build', action = M.build },
	}
end

return M
