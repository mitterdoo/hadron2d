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
local PANEL = {}

function PANEL:Init()
	self.text = "nil"
	self.font = "default"
	self.color = {1, 1, 1}
	self.halign = "left"
	self.valign = "top"
	self.wrap = false
	self:SetSize(0, 0)
	self:_UpdateSize()
end

function PANEL:_UpdateSize()
	local font = gui.getFont(self.font)
	local lines, _
	if self.wrap then
		local linesTable
		self._textW, linesTable = font:getWrap(self.text, self.w)
		lines = #linesTable
	else
		self._textW = font:getWidth(self.text)
		_, lines = self.text:gsub("\n", "\n")
		lines = lines + 1
	end
	self._textH = font:getHeight() * lines
	print("updated text size with w, h =", self._textW, self._textH)
end

function PANEL:SetText(text)
	assert(type(text) == "string", "argument must be a string (got " .. type(text) .. ")")
	self.text = tostring(text)
	self:_UpdateSize()
end
function PANEL:SetFont(font)
	assert(gui.fonts[font] ~= nil, "attempt to set label's font to nonexistent font \"" .. tostring(font) .. "\"")
	self.font = font
	self:_UpdateSize()
end

function PANEL:SetWrap(wrap)
	self.wrap = wrap
	self:_UpdateSize()
end

function PANEL:SetColor(col)
	self.color = col
end

---@param halign string
---|"left"
---|"right"
---|"center"
function PANEL:SetHAlign(halign)
	self.halign = halign
	self:_UpdateSize()
end

---@param valign string
---|"top"
---|"bottom"
---|"center"
function PANEL:SetVAlign(valign)
	self.valign = valign
	self:_UpdateSize()
end

---@param halign string
---|"left"
---|"right"
---|"center"
---@param valign string
---|"top"
---|"bottom"
---|"center"
function PANEL:SetAlign(halign, valign)
	self.halign = halign
	self.valign = valign
	self:_UpdateSize()
end

function PANEL:Paint(w, h)

	gui.setFont(self.font)
	love.graphics.setColor(self.color)
	
	local y = 0
	if self.valign == "center" then
		y = h/2 + self._textH/-2
	elseif self.valign == "bottom" then
		y = h - self._textH
	end
	
	if self.wrap then
		love.graphics.printf(self.text, 0, y, w, self.halign)
	else
		local x = 0
		if self.halign == "center" then
			x = w/2 + self._textW/-2
		elseif self.halign == "right" then
			x = w - self._textW
		end
		love.graphics.printf(self.text, x, y, self._textW, self.halign)
	end

	--[[
	local x = 0
	if self.halign == "center" then
		x = w/2 + self._textW/-2
	elseif self.halign == "right" then
		x = w - self._textW
	end

	local y = 0
	if self.valign == "center" then
		y = h/2 + self._textH/-2
	elseif self.valign == "bottom" then
		y = h - self._textH
	end

	love.graphics.print(self.text, x, y)
	]]

end

gui.register("Label", PANEL)
