local gui = require "lib.gui"
local PANEL = {}

function PANEL:Init()

	self.color = {1, 1, 1}

end

function PANEL:SetColor(col)
	self.color = col
end

function PANEL:Paint(w, h)
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", 0, 0, w, h)
end

gui.register("Rect", PANEL)
