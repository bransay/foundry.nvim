local NOTIFICATION_TITLE = "Foundry"

local fidget_notify = require("fidget.notification")

local M = {}

local next_id = 0

--- @param msg string
--- @param opts? NotifyOpts
--- @return integer id
function M.notify(msg, opts)
	opts = opts or {}
	local level = opts.level or vim.log.levels.INFO

	next_id = next_id + 1

	local fidget_opts = {
		annote = NOTIFICATION_TITLE,
		ttl = opts.keep and math.huge or nil,
		key = next_id,
	}

	fidget_notify.notify(msg, level, fidget_opts)

	return next_id
end

--- @param id integer
--- @param msg string
function M.update(id, msg) end

--- @param id integer
function M.dismiss(id) end

return M
