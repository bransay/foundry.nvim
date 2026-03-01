local NOTIFICATION_TITLE = "Foundry"
local NOTIFICATION_GROUP = "foundry"

local fidget_notify = require("fidget.notification")
local fidget_spinner = require("fidget.spinner")

-- Register our notification group with a custom name
fidget_notify.set_config(NOTIFICATION_GROUP, {
	name = NOTIFICATION_TITLE,
	icon = "󰢛",
}, true)

local M = {}

local next_id = 0
local active_notifications = {}

-- Create spinner animation for persistent notifications (1 second cycle)
local spinner_anime = fidget_spinner.animate("dots_negative", 1)

--- @param msg string
--- @param opts? NotifyOpts
--- @return integer? id Notification handle (only for persistent notifications)
function M.notify(msg, opts)
	opts = opts or {}
	local level = opts.level or vim.log.levels.INFO

	if not opts.keep then
		fidget_notify.notify(msg, level, {
			group = NOTIFICATION_GROUP,
		})
		return nil
	end

	next_id = next_id + 1
	local id = next_id

	active_notifications[id] = {
		level = level,
		msg = msg,
	}

	fidget_notify.notify(msg, level, {
		group = NOTIFICATION_GROUP,
		key = id,
		ttl = math.huge,
	})

	return id
end

--- @param id integer?
--- @param msg string
function M.update(id, msg)
	if not id then
		return
	end

	local notif = active_notifications[id]
	if not notif then
		return
	end

	-- Prepend spinner frame to message
	local spinner_frame = spinner_anime(vim.loop.now() / 1000)
	local full_msg = string.format("%s %s", spinner_frame, msg)

	fidget_notify.notify(full_msg, notif.level, {
		group = NOTIFICATION_GROUP,
		key = id,
		update_only = true,
		ttl = math.huge,
	})
end

--- @param id integer?
function M.dismiss(id)
	if not id then
		return
	end

	active_notifications[id] = nil
	fidget_notify.remove(NOTIFICATION_GROUP, id)
end

return M
