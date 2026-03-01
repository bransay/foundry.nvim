local NOTIFICATION_TITLE = "foundry"

local M = {}

--- @class NotifyOpts
--- @field level? number vim.log.levels.INFO, WARN, ERROR, etc. Defaults to INFO
--- @field keep? boolean Keep notification persistent (don't auto-dismiss)

--- Send a notification
--- Title is automatically set to "foundry" when backend supports it
--- @param msg string
--- @param opts? NotifyOpts
--- @return integer id Notification handle (for persistent notifications)
function M.notify(msg, opts) end

--- Update a persistent notification message
--- @param id integer
--- @param msg string
function M.update(id, msg) end

--- Dismiss a notification
--- @param id integer
function M.dismiss(id) end

return M
