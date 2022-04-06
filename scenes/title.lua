local SCENE = {}

function SCENE:open(from)

end

function SCENE:close()

end

function SCENE:draw(dt)

	love.graphics.print("This is a test scene!", 64, 64)

end


scene.register("Title", SCENE)
