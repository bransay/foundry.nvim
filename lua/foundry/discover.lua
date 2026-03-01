local M = {}

-- Project modules are registered here
local project_modules = {
	['CMake'] = require('foundry.cmake'),
}

local foundry_options = require('foundry.options')
local cached_detected_project_modules = nil

local function get_detected_project_modules()
	if cached_detected_project_modules then
		return cached_detected_project_modules
	end
	local root = vim.fn.getcwd()
	local detected = {}
	for name, module in pairs(project_modules) do
		if module.detect(root) then
			table.insert(detected, name)
		end
	end
	cached_detected_project_modules = detected
	return cached_detected_project_modules
end

local function get_project_type_picker_options()
	return get_detected_project_modules()
end

local options = {
	PROJECT = { 'project_type', 'Project Type', foundry_options.select_picker(get_project_type_picker_options) },
}

local function get_option(option, default)
	local opts = {}
	if default then
		opts.default = default
	end
	if option[3] then
		opts.picker = option[3]
	end
	return foundry_options.get(option[1], option[2], opts)
end

local function get_default_project_module()
	local detected = get_detected_project_modules()
	if #detected == 1 then
		return detected[1]
	end
	return nil
end

local function find_project_module_by_name(name)
	return project_modules[name]
end

function M.detect()
	local name = get_option(options.PROJECT, get_default_project_module())
	return find_project_module_by_name(name)
end

return M