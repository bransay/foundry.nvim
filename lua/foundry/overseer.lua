-- overseer integration
local M = {}

--- @param opts SetupOptions
--- @return SetupOptions
function M.modify(opts)
	local has_overseer, overseer = pcall(require, 'overseer')
	if not has_overseer then
		return opts
	end

	opts.task = function(name, cmd, cwd)
		local co = coroutine.running()
		local task = overseer.new_task({
			name = name,
			cmd = cmd,
			cwd = cwd
		})
		task:subscribe('on_complete', function(_, status)
			coroutine.resume(co, status == 'SUCCESS')
		end)
		task:remove_component('on_complete_notify')
		task:start()
		return coroutine.yield()
	end

	return opts
end

return M
