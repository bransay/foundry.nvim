local M = {}

function M.generate()
	vim.notify('Chose generate!')
end

function M.build()
	vim.notify('Chose build!')
end

function M.debug()
	vim.notify('Chose debug!')
end

function M.run()
	vim.notify('Chose run!')
end

function M.test()
	vim.notify('Chose test!')
end

function M.actions()
	return {
		{ name = 'Generate', action = M.generate },
		{ name = 'Build', action = M.build },
		{ name = 'Debug', action = M.debug },
		{ name = 'Run', action = M.run },
		{ name = 'Test', action = M.test }
	}
end

return M
