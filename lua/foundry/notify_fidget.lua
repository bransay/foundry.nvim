local NOTIFICATION_TITLE = "Foundry"
local NOTIFICATION_GROUP = "foundry"

local fidget_notify = require("fidget.notification")

-- Register our notification group with a custom name
fidget_notify.set_config(NOTIFICATION_GROUP, {
	name = NOTIFICATION_TITLE,
	icon = "󰢛",
}, true)

local M = {}

local next_id = 0
local active_notifications = {}

--- @param msg string
--- @param opts? NotifyOpts
--- @return integer id
function M.notify(msg, opts)
	opts = opts or {}
	local level = opts.level or vim.log.levels.INFO

	next_id = next_id + 1
	local id = next_id

	active_notifications[id] = level

	local fidget_opts = {
		annote = NOTIFICATION_TITLE,
		group = NOTIFICATION_GROUP,
		key = id,
	}

	if opts.keep then
		fidget_opts.ttl = math.huge
	end

	fidget_notify.notify(msg, level, fidget_opts)

	return id
end

--- @param id integer
--- @param msg string
function M.update(id, msg)
	local level = active_notifications[id] or vim.log.levels.INFO

	local fidget_opts = {
		annote = NOTIFICATION_TITLE,
		group = NOTIFICATION_GROUP,
		key = id,
		update_only = true,
	}

	fidget_notify.notify(msg, level, fidget_opts)
end

--- @param id integer
function M.dismiss(id)
	active_notifications[id] = nil

	fidget_notify.remove(NOTIFICATION_GROUP, id)
end

return M
