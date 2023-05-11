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

local scene = require "lib.scene"
local sprite = require "lib.sprite"
local gui = require "lib.gui"
local input = require "lib.input"
local SCENE = {}

local test
function SCENE:open(from)
	test = gui.create("Text")


	local testAction = input.binding.createAction("vector") -- create an action that outputs a 2d vector (x, y)
	local bindings = {} -- define a list of bindings (i plan to make this much more modular)

	local testBinding = input.binding.createBinding(testAction, "button", "desktop") -- create a binding from a set of buttons to the action
	testBinding.inputs = { -- map these keys to +x, -x, +y, -y
		["key.d"] = 1,
		["key.a"] = 2,
		["key.w"] = 3,
		["key.s"] = 4
	}

	local testBinding2 = input.binding.createBinding(testAction, "vector", "gamepad") -- create a binding from a vector input to the action
	testBinding2.inputs = {
		["gamepad.vector_lstick"] = 1, -- map the left stick to the output
	}

	-- set up a deadzone and invert y axis
	testBinding2.processorHandler:add(input.binding.PROCESSORS.DEADZONE, {minX = 0.1, minY = 0.1})
	testBinding2.processorHandler:add(input.binding.PROCESSORS.INVERT_Y)

	-- add these bindings to the list
	bindings[1] = testBinding
	bindings[2] = testBinding2

	-- set up callback for an event that's dispatched when any sort of input is received (gamepad, keyboard, mouse)
	input.rawinput:connect(function(iName, iPlayer, ...)
	
		for _, bind in pairs(bindings) do
			local index = bind.inputs[iName] -- get numerical index of the mapped input
			if index then -- if it's been mapped:
				bind.action:fire(bind:handleInput(index, ...)) -- fire the action with whatever the binding outputs in its handler method
			end
		end

	end)

	testAction.processorHandler:add(input.binding.PROCESSORS.ROUND, {threshold = 0.85}) -- add a processor to round the vector to the nearest integer if any axis goes beyond +-0.85
	-- set up callbacks for Unity-style events tied to the action
	testAction.started:connect(function(x, y) print("ACTION STARTED:", x, y) end)
	testAction.changed:connect(function(x, y) print("ACTION CHANGED:", x, y) end)
	testAction.stopped:connect(function(x, y) print("ACTION STOPPED:", x, y) end)

end

function SCENE:close()

end

local fpsPointer = 1
local fpsCount = 15
local fpsTrack = {}

function SCENE:draw()

	local dt = love.timer.getDelta()
	fpsTrack[fpsPointer] = dt
	fpsPointer = fpsPointer % fpsCount + 1
	local total = 0
	for _, v in pairs(fpsTrack) do
		total = total + v
	end

	local fps = math.floor(fpsCount / total)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("FPS: " .. fps, 0, 600 - 20)
	love.graphics.print("This is a test scene!", 64, 64)

	test:SetPos(128, 128 + math.sin(love.timer.getTime() * math.pi * 2) * 48)
	test:SetScale(8, 4)

	gui.draw()

end


scene.register("Title", SCENE)
