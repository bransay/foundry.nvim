local M = {}

function M.init(menu, module)
	vim.api.nvim_create_user_command('FoundryMenu', function() menu.show(module) end, {})
end

return M
