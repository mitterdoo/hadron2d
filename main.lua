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

require "lib.globals"
local scene = require "lib.scene"
local sprite = require "lib.sprite"
local gui = require "lib.gui"
local lists = require "lists"
scene.loadScenes(lists.scenes)
sprite.loadSheets(lists.sprites)
gui.loadPanels(lists.panels)

scene.open()

