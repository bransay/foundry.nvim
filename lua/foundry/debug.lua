-- integrates with DAP and handles debugger specificities
local M = {}

local foundry_options = require('foundry.options')
local dap_exists, dap = pcall(require, 'dap')

local function debugger_adapters()
	if not dap_exists then
		return nil
	end

	local adapters = {}
	for adapter_name, _ in pairs(dap.adapters) do
		table.insert(adapters, adapter_name)
	end

	return adapters
end

M.options = {
	DEBUGGER_ADAPTER = { 'debugger_adapter', 'Debugger Adapter', foundry_options.select_picker(debugger_adapters) },
	USE_DEBUGGER_LAUNCH_CONFIGURATION = { 'debugger_launch_config', 'Use debugger launch configuration', foundry_options.boolean_picker() }
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

-- maps fields to adapters
local cpp_debugger_mappings = {
	-- we can add non-default mappings here
	-- ex. ['cppvsdbg'] = { ['program'] = 'program' },
	['default'] = {
	}
}

local debugger_mappings = {
	cpp = cpp_debugger_mappings
}

local function get_default_adapter(language_ft)
	if not dap_exists then
		return nil
	end

	local ft_configurations = dap.configurations[language_ft]
	if not ft_configurations then
		return nil
	end

	local ft_adapters = {}
	for _, ft_configuration in ipairs(ft_configurations) do
		local adapter = ft_configuration.type
		if adapter then
			if not vim.list_contains(ft_adapters, adapter) then
				table.insert(ft_adapters, adapter)
			end
		end
	end

	-- too ambiguous or no adapters found
	if #ft_adapters > 1 or #ft_adapters == 0 then
		return nil
	end

	-- there's only 1 adapter so use that
	return ft_adapters[1]
end

function M.debug(language_ft, executable_path, args)
	if not dap_exists then
		return false, 'Debugging requires nvim-dap'
	end

	local adapter = get_option(M.options.DEBUGGER_ADAPTER, get_default_adapter(language_ft))
	if not adapter then
		return false, 'Debugging requires an adapter'
	end

	local use_debugger_launch_configuration = get_option(M.options.USE_DEBUGGER_LAUNCH_CONFIGURATION, 'true') == 'true'

	local configuration = {}
	if use_debugger_launch_configuration then
		local configurations = dap.configurations[language_ft]
		if configurations then
			for _, configuration_ in ipairs(configurations) do
				if configuration_.request and string.lower(configuration_.request) == 'launch' then
					configuration = vim.deepcopy(configuration_)
				end
			end
		end
	else
		-- set everything else
		configuration.type = adapter
	end

	local adapter_mappings = {}
	local ft_mappings = debugger_mappings[language_ft]
	if ft_mappings then
		local default_mappings = ft_mappings.default or {}
		local adapter_mappings_ = ft_mappings[adapter] or {}
		adapter_mappings = vim.tbl_deep_extend('force', default_mappings, adapter_mappings_)
	end

	local name_key = adapter_mappings.name or 'name'
	local program_key = adapter_mappings.program or 'program'
	local args_key = adapter_mappings.args or 'args'
	local request_key = adapter_mappings.request or 'request'

	configuration[name_key] = 'Launch ' .. executable_path
	configuration[program_key] = executable_path
	configuration[args_key] = args
	configuration[request_key] = 'launch'

	dap.run(configuration)
	return true, ''
end

return M
