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

local scene = require "lib.scene"
local sprite = require "lib.sprite"
local SCENE = {}

function SCENE:open(from)

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
	local start = 10
	local spriteCount = math.min(35000, math.max(0, math.ceil(((love.timer.getTime() - start) * 60) ^ 1.5)))
	local maxW = 48*2
	local spritesDrawn = 0

	math.randomseed(123452321)
	for i = 1, spriteCount do
		local positionIndex = i % 6000
		local idx = math.random(1, 50)
		if sprite.sheets[1][idx] ~= nil then
			sprite.draw(1, idx,
				8 * ((positionIndex - 1) % maxW + 1) + math.sin(love.timer.getTime()/0.5*math.pi*2+i*3)*8,
				32 + 8 * math.floor((positionIndex - 1) / maxW) + math.cos(love.timer.getTime()/math.sqrt(2)/2*math.pi*2+i)*8,
				32, 32)
			spritesDrawn = spritesDrawn + 1
		end
	end

	love.graphics.print("FPS: " .. fps, 0, 600 - 20)
	love.graphics.print("This is a test scene!", 64, 64)
	love.graphics.print("Sprites Drawn: " .. spritesDrawn, 100, 600 - 20)

end


scene.register("Title", SCENE)
