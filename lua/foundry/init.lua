local M = {}

function M.setup(opts)
	opts = opts or {}

	local default_opts = require('foundry.setup')
	M.opts = vim.tbl_deep_extend('force', default_opts, opts)

	-- project modules
	-- TODO: this should be detected, not just used as is
	local cmake = require('foundry.cmake')
	local project_module = cmake

	local menu = require('foundry.menu')
	require('foundry.commands').init(menu, project_module)
end

return M
