-- utility module for executing programs

local M = {}

-- @enum ExecutablePriority
local ExecutablePriority = {
	NORMAL = 0,
	BELOW_NORMAL = 1
}

-- @param prog_name string
-- @param args string[]
-- @param priority ExecutablePriority
function M.exec(prog_name, args, priority)
	if not prog_name then
		return nil, 'Requires a program name'
	end

	if vim.fn.executable(prog_name) == 0 then
		return nil, '"' .. prog_name .. '" is not a program.'
	end

	args = args or {}
	priority = priority or ExecutablePriority.NORMAL
end

return M
