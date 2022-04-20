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

local sprite = {}
sprite.imgs = {}

local sheets = {}
local allCoords = {}
sprite.sheets = allCoords

local function createSheet(idx, path, coords)
	local image = love.graphics.newImage(path)
	local quads = {}
	for k, v in pairs(coords) do
		if type(k) ~= "number" then
			quads[k] = v
		else
			local quad = love.graphics.newQuad(v[1], v[2], v[3], v[4], image:getWidth(), image:getHeight())
			quads[k] = quad
		end
	end

	sheets[idx] = {img = image, quads = quads}
	sprite.imgs[idx] = image
	allCoords[idx] = quads
end

local function createMaterial(name, path)
	local image = love.graphics.newImage(path)
	sprite.imgs[name] = image
end
--[[
Imports sprites from the given table.

Example structure:

```lua
{
	-- single material
	["materialName"] = "path/to/image",
	-- spritesheet
	[1] = {
		"path/to/image",
		{
			[0] = {0, 0, 512, 512},
			example_sprite = 0
		}
	}
}
```
]]
---@param tab any
function sprite.loadSheets(tab)
	for key, value in pairs(tab) do
		if type(key) == "string" then
			createMaterial(key, value)
		else
			createSheet(key, value[1], value[2])
		end
	end
end

local drawFast = love.graphics.draw
local defaultQuad = love.graphics.newQuad(0, 0, 32, 32, 32, 32)
function sprite.draw(sheetIndex, spriteIndex, x, y, w, h, halign, valign)

	local sheet = sheets[sheetIndex]
	assert(sheet ~= nil, "unregistered sprite index \"" .. tostring(sheetIndex) .. "\"")
	local quad = sheet.quads[spriteIndex] or defaultQuad
	if w == nil and quad ~= nil then
		local _a, _b
		_a, _b, w, h = quad:getViewport()
	elseif h == nil and quad ~= nil then
		local _a, _b, nw, nh = quad:getViewport()
		h = nh * w
		w = nw * w
	end
	
	halign = halign or -1
	valign = valign or -1
	if halign == 0 then
		x = x - w/2
	elseif halign == 1 then
		x = x - w
	end
	if valign == 0 then
		y = y - h/2
	elseif valign == 1 then
		y = y - h
	end

	if quad then
		local _a, _b, qw, qh = quad:getViewport()
		drawFast(sprite.imgs[sheetIndex], quad, x, y, 0, w / qw, h / qh)
	else
		local iw, ih = sprite.imgs[sheetIndex]:getDimensions()
		drawFast(sprite.imgs[sheetIndex], x, y, 0, w / iw, h / ih)
	end
	

end

return sprite
