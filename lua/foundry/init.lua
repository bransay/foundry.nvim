local M = {}

function M.setup(opts)
	M.opts = opts or {}

	-- project modules
	-- TODO: this should be detected, not just used as is
	local cmake = require('foundry.cmake')
	local project_module = cmake

	local menu = require('foundry.menu')
	require('foundry.commands').init(menu, project_module)
end

return M
