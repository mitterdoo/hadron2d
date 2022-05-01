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

	GUI library to render hierarchial elements on-screen
]]

local event = require "lib.event"
local gui = {}
gui.onPreDraw = event.create()
gui.onPostDraw = event.create()
gui.Classes = {}

local protected = {
	"DrawChildren",
	"Remove",
	"RemoveFromParent",
	"Add",
	"SetSize",
	"SetPos",
	"SetScale",
	"SetParent",
	"RefreshTransform",
	"_tf",
	"SetWide",
	"SetTall",
	"SetVisible",
	"GetPos",
	"GetSize",
	"GetWide",
	"GetTall",
	"AbsolutePos"
}

local transforms = {}

gui.transform = love.math.newTransform

---Provides a scale factor to apply to a rectangle to make it fit into a boundary
---@param w number Width of rectangle
---@param h number Height of rectangle
---@param bound_w number Width of boundary
---@param bound_h number Height of boundary
---@param allowOversize boolean Whether to allow fitting only 1 axis in the boundary instead of 2
---@return number
function gui.getFitScale(w, h, bound_w, bound_h, allowOversize)
	if allowOversize then
		return math.max(bound_w / w, bound_h / h)
	else
		return math.min(bound_w / w, bound_h / h)
	end
end

local function round(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

---Returns the absolute position of a point on screen with the given local position
---@param x number
---@param y number
function gui.absolutePos(x, y)

	for _, tf in pairs(transforms) do
		x, y = tf:inverseTransformPoint(x, y)
	end

	return round(x, 0), round(y, 0)

end

---Pushes a transformation to the stack.
---Must be accompanied by a closing `gui.popTransform()` before the next frame is drawn.
---@param tf table {x, y, scaleW, scaleH}
function gui.pushTransform(tf)
	table.insert(transforms, tf)
	love.graphics.push()
	love.graphics.applyTransform(tf)
end

---Pops a transformation from the stack and returns it.
---Does nothing if the stack is empty.
---@return table
function gui.popTransform()
	if #transforms == 0 then return end
	local tf = table.remove(transforms, #transforms)
	love.graphics.pop()

	return tf
end

---Pops all transforms from the stack and returns the preserved stack.
---This returned stack may be used in `gui.pushTransforms()`
---@return table
function gui.popAllTransforms()

	local toReturn = {}
	for i = #transforms, 1, -1 do
		local tf = gui.popTransform()
		table.insert(toReturn, 1, tf)
	end

	return toReturn

end

---Pushes multiple transforms onto the stack
---@param tflist table
function gui.pushTransforms(tflist)
	for _, tf in pairs(tflist) do
		gui.pushTransform(tf)
	end
end

local scissorStack = {}
---Pushes a scissor rect to the stack.
---Only one scissor operation can be performed at a time
---@param x number
---@param y number
---@param w number
---@param h number
function gui.pushScissor(x, y, w, h)
	local newX, newY = gui.absolutePos(x, y)
	local newW, newH = gui.absolutePos(x + w, y + h)
	newW = newW - newX
	newH = newH - newY
	table.insert(scissorStack, 1, {newX, newY, newW, newH})
	love.graphics.setScissor(newX, newY, newW, newH)
end

---Pops a scissor rect from the stack and returns it.
function gui.popScissor()
	local ret = table.remove(scissorStack, 1)
	if #scissorStack == 0 then
		love.graphics.setScissor()
	else
		love.graphics.setScissor(unpack(scissorStack[1]))
	end
	return ret
end




----------------------------------------------------------------
---                         Panels                           ---
----------------------------------------------------------------


---@class Panel
---@field x number
---@field y number
---@field w number
---@field h number
---@field parent Panel
---@field children table

local PANEL = {}
PANEL.__index = PANEL
PANEL.className = "Panel"

---Registers a metatable as a creatable Panel
---@param className string
---@param panelTable table Metatable
---@param baseName string Registered name of superclass
---@overload fun(className: string, panelTable: table)
function gui.register(className, panelTable, baseName)

	for _, name in pairs(protected) do
		local property = panelTable[name]
		if property ~= nil and property ~= PANEL[name] then
			error("class may not contain protected property/method \"" .. tostring(name) .. "\"")
		end
	end

	if baseName == nil then baseName = "Panel" end
	
	local baseTable = gui.Classes[baseName]
	if baseTable then
		if baseName == className then
			error("cannot inherit gui panel from itself")
		end
		panelTable.super = baseTable
		setmetatable(panelTable, {__index = baseTable})
	end
	panelTable.className = className
	panelTable.__index = panelTable
	gui.Classes[className] = panelTable

end

---Calls :Paint(w, h), draws children, then calls :PostPaint(w, h)
function PANEL:Draw()

	self:Paint(self.w, self.h)
	self:DrawChildren()
	self:PostPaint(self.w, self.h)

end

-- VIRTUAL - Called after the control has been created.
function PANEL:Init()

end

-- VIRTUAL - Called when the control is about to be removed.
function PANEL:OnRemove()

end

-- VIRTUAL - Called when the size has changed
function PANEL:OnSizeChanged(w, h)

end

-- VIRTUAL - Called before draw
function PANEL:Think()

end

-- VIRTUAL - Called when the control must be drawn. This is drawn before children.
function PANEL:Paint(w, h)

end

-- VIRTUAL - Same as Paint, but called after children have been drawn.
function PANEL:PostPaint(w, h)

end

---Removes the Panel from its parent but does not destroy it
function PANEL:RemoveFromParent()

	if self.parent then
	
		for k, v in pairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children, k)
				break
			end
		end
	
	end

end

---Removes the Panel entirely
function PANEL:Remove()

	self:OnRemove()
	self:RemoveFromParent()
	
	local children = {}
	for k, v in pairs(self.children) do table.insert(children, v) end
	
	for k, v in pairs(children) do
		v:Remove()
	end
end

---INTERNAL - Constructs a new transform for this Panel
function PANEL:RefreshTransform()

	self._tf = gui.transform(self.x, self.y, 0, self.scale_w, self.scale_h)

end

---Resize the Panel
---@param w number
---@param h number
function PANEL:SetSize(w, h)
	self.w = w
	self.h = h
	local f = self.OnSizeChanged
	if type(f) == "function" then
		f(self, w, h)
	end
end

---Sets the width of the Panel
---@param w number
function PANEL:SetWide(w)
	self.w = w
	local f = self.OnSizeChanged
	if type(f) == "function" then
		f(self, w, self.h)
	end
end

---Sets the height of the Panel
---@param h number
function PANEL:SetTall(h)
	self.h = h
	local f = self.OnSizeChanged
	if type(f) == "function" then
		f(self, self.w, h)
	end
end

---Returns the size of the Panel
---@return number w
---@return number h
function PANEL:GetSize()
	return self.w, self.h
end

---@return number w
function PANEL:GetWide()
	return self.w
end

---@return number h
function PANEL:GetTall()
	return self.h
end

---Sets the position of the Panel
---@param x number
---@param y number
function PANEL:SetPos(x, y)
	self.x = x
	self.y = y
	self:RefreshTransform()
end

---Returns the Panel's position
---@return number x
---@return number y
function PANEL:GetPos()
	return self.x, self.y
end


---Sets the scale of the Panel and its descendants
---@param sw number
---@param sh number
---@overload fun(scaleFactor: number)
function PANEL:SetScale(sw, sh)

	if sh == nil then
		sh = sw
	end
	
	self.scale_w = sw
	self.scale_h = sh
	self:RefreshTransform()

end

---@param visible boolean
function PANEL:SetVisible(visible)
	self.visible = visible
end

---@param isGlowing boolean
---@deprecated
function PANEL:SetGlow(isGlowing)
	self.glow = isGlowing
end

---Adds a child to the Panel
---@param child Panel
function PANEL:Add(child)
	child.parent = self
	table.insert(self.children, child)
end

---Sets the parent of the Panel
---@param newParent Panel
function PANEL:SetParent(newParent)

	if self.parent == nil then
		error("Cannot set parent of root Panel")
	end

	self:RemoveFromParent()
	newParent:Add(self)

end

local time = love.timer.getTime
function PANEL:DrawChildren()

	for _, child in pairs(self.children) do
	
		if child.visible then
			gui.pushTransform(child._tf)
			
			local start = time()
			child:Think()
			local totalTime = time() - start
			--[[
			if child.glow and not gui.isGlowing then
				gui.startGlow()
				start = time()
				child:Draw()
				totalTime = totalTime + (time() - start)
				gui.endGlow()
			end
			]]
			start = time()
			child:Draw()
			totalTime = totalTime + (time() - start)

			if PROFILING then
				child.perf_total = totalTime
				child.perf_average = child:perf_movingAvg()
				child.perf_total = 0
				child.perf_drawn = true
			end
			
			gui.popTransform()
		end
	
	end

end

---Returns the absolution position of a local pixel
---@param x number
---@param y number
---@return number x
---@return number y
---@return number scaleX
---@return number scaleY
function PANEL:AbsolutePos(x, y)

	local tfs = {}
	local cur = self
	while cur do
		table.insert(tfs, 1, cur._tf)
		cur = cur.parent
	end

	-- clever hack: add one pixel to requested coordinate
	local sw, sh = x + 1, y + 1
	for _, tf in pairs(tfs) do
		x, y = tf:inverseTransformPoint(x, y)
		sw, sh = tf:inverseTransformPoint(sw, sh)
	end

	-- clever hack: then subtract scaled coordinate to get scale factor
	sw = sw - x
	sh = sh - y

	local resultX, resultY = round(x, 0), round(y, 0)
	return resultX, resultY, sw, sh

end

gui.Classes["Panel"] = PANEL




local root
local _noParent_reference = {} -- store a reference to this table we only created here


function gui.create(className, parent)

	if not gui.Classes[className] then
		error("attempt to create gui Panel of unknown class \"" .. tostring(className) .. "\"")
	end
	
	local panel = {}
	panel.x = 0
	panel.y = 0
	panel.w = 64
	panel.h = 64
	panel.scale_w = 1
	panel.scale_h = 1
	panel.visible = true
	panel.children = {}

	if PROFILING then
		panel.perf_total = 0
		panel.perf_average = 0
	end

	function panel:perf_movingAvg()
		return self.perf_average + (self.perf_total - self.perf_average) * 1/100
	end
	
	setmetatable(panel, {__index = gui.Classes[className]})
	if parent == nil then
		parent = root
	end
	if parent ~= _noParent_reference then
		parent:Add(panel)
	end
	panel:RefreshTransform()
	panel:Init()
	
	return panel
	

end

local fade = {
	start = 0,
	finish = 1,
	col = {0, 0, 0, 1},
	active = false
}
function gui.fadeOut(duration, col)
	duration = duration or 1
	
	fade.start = love.timer.getTime()
	fade.finish = love.timer.getTime() + duration
	fade.col = col or fade.col
	fade.active = true
end
function gui.fadeIn(duration, col)
	duration = duration or 1
	
	fade.start = love.timer.getTime()
	fade.finish = love.timer.getTime() + duration
	fade.col = col or fade.col
	fade.active = false
end

root = gui.create("Panel", _noParent_reference)
root:SetSize(love.graphics.getDimensions())


local perf_x, perf_y = 32, 32 + 64 + 8
local perf_tab = 24
local function drawProfile(panel, info, parentMax)

	if not panel.perf_drawn then
		panel.perf_total = 0
		panel.perf_average = panel:perf_movingAvg()
	end
	panel.perf_drawn = nil

	love.graphics.print(panel.className, perf_x + info[1]*perf_tab, perf_y + info[2]*12)

	love.graphics.line(perf_x + info[1]*perf_tab + 64, perf_y + info[2]*12+6, perf_x + perf_tab*19, perf_y + info[2]*12+6)
	love.graphics.line(perf_x + perf_tab*9, perf_y + info[2]*12+1, perf_x + perf_tab*9, perf_y + info[2]*12+10)
	love.graphics.line(perf_x + perf_tab*19, perf_y + info[2]*12+1, perf_x + perf_tab*19, perf_y + info[2]*12+10)

	local perf = panel.perf_average / parentMax
	local totalPerf = panel.perf_average / 0.006
	if perf ~= perf then
		perf = 0
	end
	love.graphics.rectangle("fill", perf_x + perf_tab*9+1, perf_y+info[2]*12+2, (perf_tab*10-2)*perf, 4)
	love.graphics.rectangle("fill", perf_x + perf_tab*9+1, perf_y+info[2]*12+6, (perf_tab*10-2)*totalPerf, 4)

	love.graphics.print(tostring(math.ceil(perf*10000)/100), perf_x + perf_tab*20, perf_y + info[2]*12)
	info[2] = info[2] + 1
	for k, child in pairs(panel.children) do
		info[1] = info[1] + 1
		drawProfile(child, info, panel.perf_average)
		info[1] = info[1] - 1
	end

end

local fakeGFXControl = {
	perf_total = 0,
	perf_average = 0,
	perf_movingAvg = function(self)
		return self.perf_average + (self.perf_total - self.perf_average) * 1/100
	end,
	children = {},
	className = "GFX"
		
}

function gui.draw(context)

	context = context or root
	CTX = context
	--glow_scaleW = context.glow_scaleW
	--glow_scaleH = context.glow_scaleH
	local cw, ch, bw, bh = context.w, context.h, context.blurw, context.blurh

	gui.onPreDraw:fire()
	--gui.clearGlow()
	gui.pushTransform(context._tf)
	
	local ctxStart = time()
	context:Draw()
	local CONTEXT_TIME = time() - ctxStart
	if PROFILING then
		context.perf_total = CONTEXT_TIME
		context.perf_average = context:perf_movingAvg()
		context.perf_total = 0
		context.perf_drawn = true
	end
	
	gui.popTransform()

	ctxStart = time()
	gui.onPostDraw:fire()

	if PROFILING then
		local total = time() - ctxStart
		fakeGFXControl.perf_total = total
		fakeGFXControl.perf_average = fakeGFXControl:perf_movingAvg()
		fakeGFXControl.perf_total = 0
		fakeGFXControl.perf_drawn = true
	end

	--[[
	gui.pushRT(glowRT)


	render.drawBlurEffect(bw * glow_scaleW, bh * glow_scaleH, 1)
	render.setMaterialEffectBloom(glowRT, 1, 1, 1, 10)
	gui.popRT()

	render.setMaterialEffectAdd(glowRT)
	render.setRGBA(255, 255, 255, 255)
	for i = 1, 2 do
		render.drawTexturedRect(0, 0, cw, ch)
	end
	]]

	if context == root then
		local frac = timeFrac(time(), fade.start, fade.finish, true)
		if frac < 1 then
			local alpha
			if fade.active then
				alpha = frac*255
			else
				alpha = (1-frac)*255
			end
			fade.col[4] = alpha
			love.graphics.setColor(unpack(fade.col))
			love.graphics.rectangle("fill", -1, -1, cw, ch)
		elseif fade.active then
			fade.col[4] = 255
			love.graphics.setColor(unpack(fade.col))
			love.graphics.rectangle("fill", -1, -1, cw, ch)
		end
	end






	if PROFILING then
		context.count = context.count and (context.count + 1) or 1
		local info = {0, 0, context.count}
		love.graphics.setFont()
		drawProfile(fakeGFXControl, info, 0.006)
		drawProfile(context, info, 0.006)
	end

	--render.drawText(32 + 128/2, 32+32, tostring(RTCount), 1)

	CTX = nil

end

function gui.loadPanels(panels)

	for _, fileName in pairs(panels) do
		require("panels." .. fileName)
	end

end

return gui

