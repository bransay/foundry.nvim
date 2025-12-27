local M = {}

function M.setup(opts)
	M.opts = opts or {}

	vim.api.nvim_create_user_command('FoundryHello', function()
		vim.notify('Hello from foundry.nvim!')
	end, {})
end

return M
