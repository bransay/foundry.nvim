local M = {}

function M.setup(opts)
	M.opts = opts or {}

	local menu = require('foundry.menu')
	require('foundry.commands').init(menu)
end

return M
