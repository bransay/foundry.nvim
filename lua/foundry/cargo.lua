local M = {}

function M.detect(root)
	local cargo_file = vim.fs.joinpath(root, 'Cargo.toml')
	return vim.fn.filereadable(cargo_file) == 1
end

function M.actions()
	return {}
end

return M