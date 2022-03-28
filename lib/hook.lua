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

--[[
	Global hook event system.
	Inspired by same concept used in Garry's Mod Lua
]]

local hook = {}
local CallbackTable = {}
function hook.add(event, identifier, callback)

	if CallbackTable[event] == nil then
		CallbackTable[event] = {}
	end

	table.insert(CallbackTable[event], {identifier, callback})

end

--[[
	Runs all callbacks for a certain event. Does not halt
]]
function hook.run(event, ...)

	local list = CallbackTable[event]
	if list == nil then return end

	for _, listener in pairs(list) do
		listener[2](...)
	end

end

--[[
	Runs all callbacks for a certain event. If any of them return a value, it will break out of the iterator loop and return the value(s).
]]
function hook.call(event, ...)

	local list = CallbackTable[event]
	if list == nil then return end

	for _, listener in pairs(list) do
		local returns = {listener[2](...)}
		if #returns > 0 then
			return unpack(returns)
		end
	end

end

function hook.remove(event, identifier)

	local list = CallbackTable[event]
	if list ~= nil then
		for k, v in pairs(list) do
			if v[1] == identifier then
				table.remove(list, k)
				break
			end
		end
	end

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
	love[loveName] = function(...)
		hook.run(loveName, ...)
	end
end


return hook
