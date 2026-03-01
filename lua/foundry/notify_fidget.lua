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

-- Build notification message with optional spinner prefix
local function with_spinner(msg, spinner)
	if not spinner then
		return msg
	end
	local spinner_frame = spinner_anime(vim.loop.now() / 1000)
	return string.format("%s %s", spinner_frame, msg)
end

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
		spinner = opts.spinner,
	}

	fidget_notify.notify(with_spinner(msg, opts.spinner), level, {
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

	fidget_notify.notify(with_spinner(msg, notif.spinner), notif.level, {
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
