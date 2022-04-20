local gui = require "lib.gui"
local PANEL = {}

function PANEL:Paint(w, h)

	love.graphics.setColor(1, 0, 0, 1)
	love.graphics.print("Heya how's it goin")

end

gui.register("Text", PANEL)
