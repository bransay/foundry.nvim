local M = {}

function M.setup(opts)
	M.opts = opts or {}
end

function M.notify(msg, level, opts)
	opts = opts or {}
	level = level or vim.log.levels.INFO

	vim.notify(msg, level)
end

return M
