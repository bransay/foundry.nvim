local NOTIFICATION_TITLE = "foundry"

local M = {}

--- @param msg string
--- @param opts? NotifyOpts
--- @return integer id
function M.notify(msg, opts) end

--- @param id integer
--- @param msg string
function M.update(id, msg) end

--- @param id integer
function M.dismiss(id) end

return M
