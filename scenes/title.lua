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
	input.rawinput:connect(function(iName, iPlayer, ...)
	
		local args = {...}
		print(iName, iPlayer, ...)

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
	test:SetScale(-2, -4)

	gui.draw()

end


scene.register("Title", SCENE)
