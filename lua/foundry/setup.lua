
local M = {}

--- @class SetupOptions
--- @field task? fun(name:string, cmd:string[], cwd:string):boolean

--- @return SetupOptions
function M.get_default_opts()
	--- @type SetupOptions
	local options = {
		task = function(_, cmd, cwd)
			local co = coroutine.running()
			vim.system(cmd, {cwd = cwd}, function(obj)
				coroutine.resume(co, obj.code)
			end)
			local code = coroutine.yield()
			return code and code == 0 or false
		end
	}
	return options
end

return M
