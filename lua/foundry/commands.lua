local M = {}

function M.init(menu)
	vim.api.nvim_create_user_command('FoundryMenu', menu.show, {})
end

return M
