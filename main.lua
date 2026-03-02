package.path = "/home/studentas/.vscode/extensions/yinfei.luahelper-0.2.29/debugger/?.lua;" .. package.path
require("LuaPanda").start("127.0.0.1", 8818)

local ubus = require("ubus")
local uloop = require("uloop")
local destination = "8.8.8.8"

local M = {}

local function has_internet()
	local handle = io.popen(
		"ping -q -c 1 -W 1 " .. destination .. " >/dev/null 2>&1; echo $?"
	)
	if not handle then
		return nil, "Could not execute ping command"
	end

	local rc = handle:read("*a")
	handle:close()

	rc = tonumber(rc)

	if rc == 0 then
		return true, "connected"

	else
		return false, "disconnected"
	end
end

function M.create_service(conn)
	local methods = {
		["internet"] = {
			status = {
				function(req)
					local status, msg = has_internet()
					if status == nil then
						conn:reply(req, {
							error = msg or "Failed to get internet status",
							destination = destination
						})
						return
					end
					
					local result = {
						status = msg,
						destination = destination
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
				if online == true then
					conn:send("internet.status", { internet = "connected", destination = destination })
				else
					conn:send("internet.status", { internet = "disconnected", destination = destination })
				end
			end

			last_online = online
			t:set(5 * 1000)
		end)

	t:set(5 * 1000)
	uloop.run()
end

M.run()