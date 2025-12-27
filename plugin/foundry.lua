if vim.g.loaded_foundry then
	return
end
vim.g.loaded_foundry = true

vim.notify('foundry.nvim loaded', vim.log.levels.DEBUG)

require('foundry').setup()
