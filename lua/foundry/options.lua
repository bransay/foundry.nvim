local M = {}

local function get_workspace_path()
	return vim.fs.joinpath(vim.fn.getcwd(), '.workspace')
end

local function ensure_workspace()
	local workspace_path = get_workspace_path()
	vim.fn.mkdir(workspace_path, 'p')
	return workspace_path
end

---@class OptionOpts
---@field choices fun()?:string[]
---@field default string?
---@field force_ui boolean?

---@param option_name string
---@param option_string string
---@param opt OptionOpts
function M.get(option_name, option_string, opt)
	local co = coroutine.running()

	-- first look for existing value
	local workspace_path = ensure_workspace()
	local option_path = vim.fs.joinpath(workspace_path, option_name)
	local existing_value = nil
	if vim.fn.filereadable(option_path) ~= 0 then
		existing_value = vim.fn.readfile(option_path)[1]
	end

	-- if default is specified then don't show ui if it doesn't exist, use that
	if not opt.force_ui then
		if existing_value then
			return existing_value
		elseif opt.default then
			return opt.default
		end
	end

	local value = nil
	if opt.choices then
		-- if choices exist then use vim.ui.select
		local choices = opt.choices()

		local display_choices = {}
		for _, item in ipairs(choices) do
			local value = item[1] or item
			local display = item[2] or item

			local display_text = display
			if existing_value and existing_value == value then
				display_text = display .. ' ' 
			end
			table.insert(display_choices, { display_text, value })
		end

		vim.ui.select(
			display_choices,
			{
				prompt = option_string,
				format_item = function(item)
					return item[1]
				end
			},
			function(selected)
				coroutine.resume(co, selected and selected[2] or nil)
			end
		)
		value = coroutine.yield()
	else
		-- otherwise use vim.ui.input
		vim.ui.input(
			{
				prompt = option_string,
				default = existing_value or ''
			},
			function(input)
				coroutine.resume(co, input)
			end
		)
		value = coroutine.yield()
	end

	if value then
		-- write new value
		vim.fn.writefile({ value }, option_path)
	end

	return value
end

return M
