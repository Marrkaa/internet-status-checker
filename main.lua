local socket = require("socket")
local ubus = require("ubus")
local uloop = require("uloop")

local HOST = "8.8.8.8"
local PORT = 53

local M = {}

local function has_internet()
	local tcp = socket.tcp()
	if not tcp then
		return nil, "Could not create tcp socket"
	end

	tcp:settimeout(5)

	local ok = tcp:connect(HOST, PORT)
	if not ok then
		tcp:close()
		return false, "Could not connect to host"
	end

	return true
end

function M.create_service(conn)
	local methods = {
		["internet"] = {
			status = {
				function(req)
					local status, err = has_internet()

					if not status then
						conn:reply(req, {
							success = false,
							error = err or "Failed to get internet status"
						})
						return
					end

					local result = {
						success = true,
						status = status,
						host = HOST,
						port = PORT
					}
					conn:reply(req, result)
				end,
				{}
			}
		}
	}

	return methods
end

function M.run()
	uloop.init()

	local conn = ubus.connect()
	if not conn then
		error("Failed to connect to ubus")
	end

	local methods = M.create_service(conn)
	conn:add(methods)

	local last_online = nil

	local t
	t = uloop.timer(
		function()
			local online = has_internet()
			if online == nil then
				t:set(5 * 1000)
				return
			end

			if last_online ~= nil and online ~= last_online then
				if not online then
					conn:send("internet.lost", { online = false })
				else
					conn:send("internet.restored", { online = true })
				end
			end

			last_online = online
			t:set(5 * 1000)
		end)

	t:set(5 * 1000)
	uloop.run()
end

M.run()