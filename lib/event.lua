--[[
BRIX: Stack to the Death, a multiplayer brick stacking game originally written for the Starfall addon in Garry's Mod, now as a standalone Love2D game.
Copyright (C) 2022  Connor Ashcroft

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see LICENSE.md).
If not, see <https://www.gnu.org/licenses/>.
]]

local event = {}


local CONN = {}
function CONN:disconnect()

	assert(self.event ~= nil, "connection does not have an associated event to disconnect from")
	self.event.callbacks[self] = nil

end

local EVENT = {}
function EVENT:connect(callback)

	local identifier = setmetatable({event = self}, {__index = CONN})
	self.callbacks[identifier] = callback
	return identifier

end

function EVENT:wait()

	local current, main = coroutine.running()
	assert(not main, "cannot wait/yield on main coroutine")
	local connection
	connection = self:connect(function(...)
		connection:disconnect()
		coroutine.resume(current, ...)
	end)
	coroutine.yield(event)

end

function EVENT:fire(...)

	for _, callback in pairs(self.callbacks) do
		callback(...)
	end

end

function EVENT:call(...)

	for _, callback in pairs(self.callbacks) do
		local returns = {callback(...)}
		if #returns > 0 then
			return unpack(returns)
		end
	end

end

function event.create()

	return setmetatable({callbacks = {}}, {__index = EVENT})

end

-- Add hooks for all applicable Love callbacks
local callbacks = {
	"displayrotated",
	"draw",
	"load",
	"quit",
	"update",
	"focus",
	"resize",
	"visible",

	"keypressed",
	"keyreleased",

	"mousemoved",
	"mousepressed",
	"mousereleased",
	"wheelmoved",

	"gamepadaxis",
	"gamepadpressed",
	"gamepadreleased",
	"joystickadded",
	"joystickaxis",
	"joystickhat",
	"joystickpressed",
	"joystickreleased",
	"joystickremoved"
}


for _, loveName in pairs(callbacks) do
	local obj = event.create()
	event[loveName] = obj
	love[loveName] = function(...)
		obj:fire(...)
	end
end

return event