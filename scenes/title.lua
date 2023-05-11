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
	local function computeDeadzone(value, min, max)

		max = max or 1
		if value >= 0 then
			return mapFrac(value, min, max, true)
		else
			return -mapFrac(-value, min, max, true)
		end
	
	end
	test = gui.create("Text")
	local testAction = input.binding.createAction("vector")

	local testBinding = input.binding.createBinding(testAction, "button", "desktop")
	testBinding.inputs = {
		["key.d"] = 1,
		["key.a"] = 2,
		["key.w"] = 3,
		["key.s"] = 4
	}

	local testBinding2 = input.binding.createBinding(testAction, "vector", "gamepad")
	testBinding2.inputs = {
		["gamepad.vector_lstick"] = 1,
	}
	testBinding2.processorHandler:add(input.binding.PROCESSORS.DEADZONE, {minX = 0.1, minY = 0.1})
	testBinding2.processorHandler:add(input.binding.PROCESSORS.INVERT_Y)
	testAction.processorHandler:add(input.binding.PROCESSORS.BINARY, {threshold = 0.85})

	input.rawinput:connect(function(iName, iPlayer, ...)
	
		local index = testBinding.inputs[iName]
		if index then
			testBinding.action:fire(testBinding:handleInput(index, ...))
		else
			index = testBinding2.inputs[iName]
			if index then
				testBinding2.action:fire(testBinding2:handleInput(index, ...))
			end
		end

	end)

	testAction.changed:connect(function(x, y)
	
		print("CHANGED:", x, y)

	end)

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
