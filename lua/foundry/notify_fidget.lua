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

-- Global spinner update timer
local spinner_timer = nil
local spinner_count = 0  -- Count of active spinner notifications

-- Get spinner frame based on elapsed time since notification creation
local function get_spinner_frame(created_at)
	local elapsed = (vim.loop.now() - created_at) / 1000
	return spinner_anime(elapsed)
end

-- Build notification message with optional spinner prefix
local function with_spinner(msg, spinner, created_at)
	if not spinner then
		return msg
	end
	local spinner_frame = get_spinner_frame(created_at)
	return string.format("%s %s", spinner_frame, msg)
end

-- Update all active spinner notifications
local function update_spinners()
	for id, notif in pairs(active_notifications) do
		if notif.spinner then
			local full_msg = with_spinner(notif.msg, notif.spinner, notif.created_at)
			fidget_notify.notify(full_msg, notif.level, {
				group = NOTIFICATION_GROUP,
				key = id,
				update_only = true,
				ttl = math.huge,
			})
		end
	end
end

-- Start the global spinner timer if not running
local function start_spinner_timer()
	if spinner_timer then
		return
	end
	spinner_timer = vim.loop.new_timer()
	spinner_timer:start(0, 100, function()
		vim.schedule(update_spinners)
	end)
end

-- Stop the global spinner timer
local function stop_spinner_timer()
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()
		spinner_timer = nil
	end
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
	local created_at = vim.loop.now()

	active_notifications[id] = {
		level = level,
		spinner = opts.spinner,
		msg = msg,
		created_at = created_at,
	}

	if opts.spinner then
		spinner_count = spinner_count + 1
		start_spinner_timer()
	end

	fidget_notify.notify(with_spinner(msg, opts.spinner, created_at), level, {
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

	notif.msg = msg

	fidget_notify.notify(with_spinner(msg, notif.spinner, notif.created_at), notif.level, {
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

	local notif = active_notifications[id]
	if not notif then
		return
	end

	-- Remove from spinner tracking
	if notif.spinner then
		spinner_count = spinner_count - 1
		-- Stop timer if no more spinner notifications
		if spinner_count == 0 then
			stop_spinner_timer()
		end
	end

	active_notifications[id] = nil
	fidget_notify.remove(NOTIFICATION_GROUP, id)
end

return M
