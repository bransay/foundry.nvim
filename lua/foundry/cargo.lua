local M = {}
local foundry_notify = require('foundry.notify')

function M.detect(root)
	local cargo_file = vim.fs.joinpath(root, 'Cargo.toml')
	return vim.fn.filereadable(cargo_file) == 1
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