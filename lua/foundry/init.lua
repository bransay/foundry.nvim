local M = {}

function M.setup(opts)
	opts = opts or {}

	local default_opts = require('foundry.setup').get_default_opts()

	-- modify with integrations
	default_opts = require('foundry.overseer').modify(default_opts)

	M.opts = vim.tbl_deep_extend('force', default_opts, opts)

	-- project modules
	-- TODO: this should be detected, not just used as is
	local cmake = require('foundry.cmake')
	local project_module = cmake

	local menu = require('foundry.menu')
	require('foundry.commands').init(menu, project_module)
end

return M
