-- utility module for executing programs

local M = {}

-- @enum ExecutablePriority
local ExecutablePriority = {
	NORMAL = 0,
	BELOW_NORMAL = 1
}

-- Cross platform priority control - important when compiling because not 
-- lowering the priority of compilation can cause UI unresponsiveness, etc.
-- @param prog_name string
-- @param args string[]
-- @param priority ExecutablePriority
-- @param output_callback fun(result:string):nil
function M.exec(prog_name, args, priority, output_callback)
	if not prog_name then
		return nil, 'Requires a program name'
	end

	if vim.fn.executable(prog_name) == 0 then
		return nil, '"' .. prog_name .. '" is not a program.'
	end

	args = args or {}
	priority = priority or ExecutablePriority.NORMAL

	-- TODO: actually do something with the priority being passed in

	table.insert(args, 1, prog_name)
	vim.system(
		args,
		{ text = true },
		function(res)
			output_callback(res.stdout)
		end
	)
end

return M
