local M = {}

local function create_coroutine_callback(f)
	return function()
		coroutine.wrap(f)()
	end
end

function M.init(menu, module)
	vim.api.nvim_create_user_command('FoundryMenu', create_coroutine_callback(function() menu.show(module) end), {})
end

return M
