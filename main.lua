package.path = "/home/studentas/.vscode/extensions/yinfei.luahelper-0.2.29/debugger/?.lua;" .. package.path
require("LuaPanda").start("127.0.0.1", 8818)

local ubus = require("ubus")
local uloop = require("uloop")

local M = {}

local function has_internet()
	local handle = io.popen(
		"ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; echo $?"
	)
	if not handle then
		return nil, "Could not execute ping command"
	end

	local rc = handle:read("*a")
	handle:close()

	rc = tonumber(rc)

	return rc == 0
end

function M.create_service(conn)
	local methods = {
		["internet"] = {
			status = {
				function(req)
					local status, err = has_internet()

					if status == nil then
						conn:reply(req, {
							success = false,
							error = err or "Failed to get internet status"
						})
						return
					end

					local result = {
						success = true,
						status = status,
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