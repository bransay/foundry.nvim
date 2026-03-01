-- Try to use fidget backend, fall back to vanilla
if pcall(require, "fidget") then
	return require("foundry.notify_fidget")
end

-- Vanilla fallback (vim.notify)
local M = {}

--- @class NotifyOpts
--- @field level? number
--- @field keep? boolean
--- @field spinner? boolean Show spinner animation (only when keep=true)

--- @param msg string
--- @param opts? NotifyOpts
--- @return nil
function M.notify(msg, opts)
	opts = opts or {}
	local level = opts.level or vim.log.levels.INFO
	vim.notify(msg, level)
	return nil
end

--- @param _ integer
--- @param msg string
function M.update(_, msg)
	M.notify(msg, { level = vim.log.levels.INFO })
end

--- @param _ integer
function M.dismiss(_) end

return M
