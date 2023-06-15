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

local gui = require "lib.gui"
local input = require "lib.input"
local event = require "lib.event"

local focusedButton
local hotButtons = {}

local PANEL = {}

--[[
	ui_up
	ui_down
	ui_left
	ui_right
	ui_accept
	ui_cancel
]]
local actions = {
	ui_up = input.binding.createAction("button"),
	ui_down = input.binding.createAction("button"),
	ui_left = input.binding.createAction("button"),
	ui_right = input.binding.createAction("button"),
	ui_accept = input.binding.createAction("button"),
	ui_proceed = input.binding.createAction("button"),
	ui_cancel = input.binding.createAction("button")
}

function PANEL:Init()

	self.branches = {}
	self.focused = false
	self.nofocus = false

	self.onPress = event.create()
	self.onFocus = event.create()

end

function PANEL:SetDisallowFocus(disallow)
	self.nofocus = disallow
end

function PANEL:SetUp(button)
	self.branches.up = button
end
function PANEL:SetDown(button)
	self.branches.down = button
end
function PANEL:SetLeft(button)
	self.branches.left = button
end
function PANEL:SetRight(button)
	self.branches.right = button
end

function PANEL:Focus()
	self.focused = true
	if focusedButton ~= self then
		if focusedButton then
			focusedButton.focused = false
		end
		focusedButton = self
		self.onFocus:fire()
		-- hook.run("buttonFocus", self)
	end
end

function PANEL:SetHotAction(action)
	-- hotButtons[action] = self
end

function PANEL:OnRemove()

	-- remove hot action

end

function PANEL:Paint(w, h)
	love.graphics.setColor(1, 0, 1, 1)
	love.graphics.rectangle("fill", 0, 0, w, h)
end


function PANEL:InternalDoPress()
end

local function ui_moveDirectionally(direction)

	if focusedButton then
		local branch = focusedButton.branches[direction]
		if branch then
			if not branch.nofocus and branch.visible then branch:Focus() end
		end
	end
	--[[
		do stuff with hot actions
	]]

end

local function ui_accept()

	if focusedButton then
		focusedButton:InternalDoPress()
		focusedButton.doPress:fire()
	end

end

local function ui_proceed()
	-- hot action for going forward
end

local function ui_cancel()
	-- hot action for going back
end

actions.ui_accept.started:connect(ui_accept)
actions.ui_proceed.started:connect(ui_proceed)
actions.ui_cancel.started:connect(ui_cancel)
actions.ui_up.started:connect(function() ui_moveDirectionally("up") end)
actions.ui_down.started:connect(function() ui_moveDirectionally("down") end)
actions.ui_left.started:connect(function() ui_moveDirectionally("left") end)
actions.ui_right.started:connect(function() ui_moveDirectionally("right") end)

gui.register("Button", PANEL)
