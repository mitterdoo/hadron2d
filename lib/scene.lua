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

local event = require "lib.event"
local lists = require "lists"

local scene = {}

event.define("sceneClosing") -- (sceneObject)
event.define("sceneClose") -- (name)
event.define("sceneOpen") -- (sceneObject)

scene.registry = {}

local function closeActiveScene()
	local name = scene.active.name
	scene.active:close()
	scene.active = nil

	event.sceneClose:fire(name)
end

local function setActiveScene(name, from)

	local meta = scene.registry[name]
	scene.active = setmetatable({name = name}, {__index = meta})
	scene.active:open(from)

	event.sceneOpen:fire(scene.active)

end

function scene.register(name, tab)
	scene.registry[name] = tab
end

-- Todo: Scene transitions

function scene.open(name)

	if name == nil then
		name = scene.entry
	end

	if not scene.registry[name] then
		error("Attempt to open nil scene \"" .. tostring(name) .. "\"")
	end

	if scene.active then
		local curName = scene.active.name
		event.sceneClosing:fire(scene.active)
		closeActiveScene()
		setActiveScene(name, curName)
	else
		setActiveScene(name)
	end

end

function scene.close()

	if scene.active then
		event.sceneClosing:fire(scene.active)
		closeActiveScene()
		scene.nextScene = nil
	end
	
end

_G.scene = scene -- hack
for _, module in pairs(lists.scenes) do
	require("scenes." .. module)
end
_G.scene = nil

event.draw:connect(function(dt)

	if scene.active and type(scene.active.draw) == "function" then
		scene.active:draw(dt)
	end

end)
scene.entry = "Title"

return scene
