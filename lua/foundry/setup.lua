local M = {
	task = function(name, cmd)
		local co = coroutine.running()
		vim.system(cmd, {}, function(obj)
			coroutine.resume(co, obj.code)
		end)
		local code = coroutine.yield()
		return code and code == 0 or false
	end
}

return M
