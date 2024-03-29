--[[
Hadron2D Game Engine for LÖVE
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

---@class EventConnection
---@field event Event
local CONN = {}
--[[
	Disconnects the connection from its event
]]
function CONN:disconnect()

	assert(self.event ~= nil, "connection does not have an associated event to disconnect from")
	self.event._count = self.event._count - 1
	self.event.listened = self.event._count > 0
	self.event.callbacks[self] = nil

end

---@class Event
---@field callbacks table
---@field listened boolean Whether anything is listening to this Event
local EVENT = {}

---Connects a function to be called back upon firing of the event
---@param callback function Callback function
---@return EventConnection connection A connection linked to this function that may be disconnected
function EVENT:connect(callback)

	local identifier = setmetatable({event = self}, {__index = CONN})
	self.callbacks[identifier] = callback
	self._count = self._count + 1
	self.listened = true
	return identifier

end

---Connects a function to be called back upon firing of the event, but only one time.
---@param callback function
---@return EventConnection connection A connection linked to this function that may be disconnected
function EVENT:onetime(callback)

	local connection
	connection = self:connect(function(...)
		connection:disconnect()
		callback(...)
	end)
	return connection

end

---Connects a function to be called back upon firing of the event. Will continue until the callback evaluates to true and disconnects the callback.
---@param callback function
---@return EventConnection connection A connection linked to this function that may be disconnected
function EVENT:connectConditional(callback)

	local connection
	connection = self:connect(function(...)
		if callback(...) then
			connection:disconnect()
		end
	end)
	return connection
end


---Halts the current coroutine until the event is fired/called. Returns the event parameters
---@async
---@return ...
function EVENT:wait()

	local current, main = coroutine.running()
	assert(not main, "cannot wait/yield on main coroutine")
	local connection
	connection = self:connect(function(...)
		connection:disconnect()
		coroutine.resume(current, ...)
	end)
	return coroutine.yield(event) -- pass event library as sentinel

end

---Halts the current coroutine until the callback evaluates to true. Returns the event parameters
---@async
---@param callback function
---@return ...
function EVENT:waitConditional(callback)

	local current, main = coroutine.running()
	assert(not main, "cannot wait/yield on main coroutine")
	local connection
	connection = self:connect(function(...)
		if callback(...) then
			connection:disconnect()
			coroutine.resume(current, ...)
		end
	end)
	return coroutine.yield(event) -- pass event library as sentinel
	
end

---Runs all event listeners
---@vararg any
function EVENT:fire(...)

	if not self.listened then return end
	for _, callback in pairs(self.callbacks) do
		callback(...)
	end

end

---Calls all event listeners until one of them returns a value
---@vararg any
---@return ... returns
function EVENT:call(...)

	if not self.listened then return end
	for _, callback in pairs(self.callbacks) do
		local returns = {callback(...)}
		if #returns > 0 then
			return unpack(returns)
		end
	end

end

---@class Filter
---@field connection EventConnection
local FILTER = setmetatable({}, {__index = EVENT})
function FILTER:disconnect()
	assert(self.connection, "filter is not connected!")
	self.connection:disconnect()
	self.connection = nil
end

--[[
	Creates and connects a Filter to this Event.
	Upon firing of the Event, a callback will be called.
	If the callback returns anything, the Filter will fire
]]
---@param callback function
---@return Filter
function EVENT:createFilter(callback)
	local filter = setmetatable({callbacks = {}}, {__index = FILTER})
	filter.connection = self:connect(function(...)
		
		local returns = {callback(...)}
		if #returns > 0 then
			filter:fire(unpack(returns))
		end

	end)
	return filter
end
---Create an event object to hook to
---@return Event event
function event.create()

	return setmetatable({callbacks = {}, listened = false, _count = 0}, {__index = EVENT})

end

---Defines a global event
---@param name string 
function event.define(name)

	assert(name ~= "create" and name ~= "define", "reserved name \"" .. name .. "\" for global event")
	event[name] = event.create()

end

-- Add hooks for all applicable Love callbacks
local callbacks = {
	"displayrotated",
	"draw",
	"load",
	"quit",
	"preupdate",
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
