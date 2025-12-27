local M = {}

function M.setup(opts)
	M.opts = opts or {}

	-- project modules
	local cmake = require('foundry.cmake')

	local menu = require('foundry.menu')
	require('foundry.commands').init(menu, cmake)
end

return M
