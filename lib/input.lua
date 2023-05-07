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

local input = {}
input.binding = require "lib.input.binding"

--[[

	Structure:
	All types of input (keyboard presses, mouse clicks/movements, gamepad buttons/sticks, etc.)
	are captured and sent to the `rawinput` event.
	A full list of allowed input names is shown below, but the naming convention is as follows:
		device.type_name
		All lowercase
	`device` may be:
		key
		mouse
		gamepad
	`type` may be:
		button
		axis
	*	vector
		event
	*Vector inputs will automatically be processed if there is an axis with the same name that
		also has "_x" and "_y" components, meaning the vector input shouldn't be manually fired.
		You may fire a vector input only if there isn't an axis of the same name that has x and y axes.
	
	`name` may be anything, though there is a special case when using the `axis` type:
		With the `axis` type, an optional "_x" and "_y" may be appended to the name.
		Internally, when either of the values change, an event of type vector with the same device and
		name will be fired, using the two components as the arguments.

	When any input changes, the input.rawinput event will be fired with:
		fullName		string		The full name of the input, following the naming convention above
		player			number		The index of the player who triggered this input on their gamepad, or -1 if it wasn't from a gamepad.
		...				vararg		The value(s) of this event, depending on input type:
			button:
				pressed		boolean
			axis:
				value		number
			vector:
				x			number
				y			number
			event:
				...			Values of event
		
	
	
	There are 4 players that may receive raw inputs.
	Each player has their own associated PlayerInput object.
	When rawinput events are fired, they will be passed down to either:
		All players, if the player argument is -1
		One player, whose ID matches the argument given
	
	Each PlayerInput contains a set of ActionMaps, which may be used as different
		input maps for different contexts, such as menus and in-game. Rawinput
		events will pass down to these ActionMaps if they are enabled.
	
	Next, an ActionMap may contain a list of Actions which can be listened to by
		your game. Bindings within these Actions will listen to the rawinput
		of the containing ActionMap and determine whether to update the Action.



	Input Paths:

		Gamepad (must set to other players manually)
			gamepad.button_north
			gamepad.button_east
			gamepad.button_south
			gamepad.button_west
			gamepad.button_dpad_up
			gamepad.button_dpad_right
			gamepad.button_dpad_down
			gamepad.button_dpad_left
			gamepad.axis_dpad_x		[-1.0, 1.0]
			gamepad.axis_dpad_y		[-1.0, 1.0]
			gamepad.vector_dpad		[-1.0, 1.0], [-1.0, 1.0]
			gamepad.button_lshoulder
			gamepad.button_lstick_up
			gamepad.button_lstick_right
			gamepad.button_lstick_down
			gamepad.button_lstick_left
			gamepad.axis_lstick_x	[-1.0, 1.0]
			gamepad.axis_lstick_y	[-1.0, 1.0]
			gamepad.vector_lstick	[-1.0, 1.0], [-1.0, 1.0]
			gamepad.button_lstick
			gamepad.button_ltrigger
			gamepad.axis_ltrigger	[0.0, 1.0]
			gamepad.button_rshoulder
			gamepad.button_rstick_up
			gamepad.button_rstick_right
			gamepad.button_rstick_down
			gamepad.button_rstick_left
			gamepad.axis_rstick_x	[-1.0, 1.0]
			gamepad.axis_rstick_y	[-1.0, 1.0]
			gamepad.vector_rstick	[-1.0, 1.0], [-1.0, 1.0]
			gamepad.button_rstick
			gamepad.button_rtrigger
			gamepad.axis_rtrigger	[0.0, 1.0]
			gamepad.button_back
			gamepad.button_start
			gamepad.button_guide

			gamepad.event_connect		gamepadIndex
			gamepad.event_disconnect	gamepadIndex

		Mouse:
								<no ranges for mouse axes>
			mouse.axis_delta_x
			mouse.axis_delta_y
			mouse.vector_delta

			mouse.button_1
			mouse.button_2
			mouse.button_3
			...

			mouse.axis_pos_x
			mouse.axis_pos_y
			mouse.vector_pos

			mouse.axis_scroll_x
			mouse.axis_scroll_y
			mouse.vector_scroll

		Keyboard:
			key.any

			... (KeyConstants as defined in LOVE)
		
	

	Listed above are valid names of Inputs.
	No deadzones or any other input modifications are applied to them. The data is raw.
	button_* and all key.* Inputs will be of type boolean
	axis_*_x and axis_*_y Inputs will be a number in the range depending on the type of Input
	vector_* Inputs will return two numbers, range also dependent on Input type

	Values of Inputs should be cached

	Bindings listen for certain Input events to be fired, and will fire different events depending on what happened to the input.
	Bindings can output either a boolean value (like a button), or an axis (1d or 2d), similar to Unity
	Each event will be given the current output value of the binding.
		[Event Name]	[Occurs when..]
		started			Input first changes from default state and "activates" (Button just now pressed down, or joystick moved center outside deadzone)
		changed			Input value changes and is still activated.
		stopped			Input value rests at default and "deactivates"
	A Binding must be given a controller to listen to, which means multiple instances of Bindings will need to be created to allow multiple controllers at once. 


	<Event RawInput>
		string		inputPath
		string		inputType	(keymouse|gamepad)
		number		player
		...			varargs

	[PlayerInput]
		An object that represents a single player.
		Contains a list of [ActionMap]s. Each [ActionMap] will have raw input piped into them.

	[ActionMap]
		A collection of [Action]s.
		May be enabled or disabled.
		Contains an [Event] that will pass down piped raw inputs.
		Will also broadcast enable/disable events, which should be used by [Action]s to deactivate their outputs
	
	[Action]
		An action that can be performed when certain inputs are performed.
		Expects raw inputs, to pass down to [Binding] descendants.
		Contains 3 events:
			[Event Name]	[Occurs when..]
			started			Input first changes from default state and "activates" (Button just now pressed down, or joystick moved center outside deadzone)
			changed			Input value changes and is still activated.
			stopped			Input value rests at default and "deactivates"
		These events may be fired by [Binding] descendants when they are activated.
		Output event type may be of:
			button		boolean
			value		number
			vector		2d axis; 2 numbers
			event		any args
	
	[Binding]
		Listens for raw inputs 


	There are 4 types of bindings:
	button
		Can be triggered by:
			button
			axis (when passing a certain threshold, positive/negative)
			
	axis
		Allows 1 axis input
		{
			"axis_inputName"
		}
		or
		{
			pos = "button_inputName",
			neg = "button_inputName"
		}
	vector
		Allows 2 axis inputs
		{
			""
		}
	event
		Allows only 1 input, but with varargs


]]

local event = require "lib.event"

local rawInputState = {}
local vectorsThisFrame = {}
--- Fired when any single input is fired. Player is -1 unless it is a gamepad input
input.rawinput = event.create() 


local function handleInput(fullName, player, ...)

	if rawInputState[player] == nil then
		rawInputState[player] = {}
	end
	local state = rawInputState[player]
	state[fullName] = {...}
	local iMethod, iName, iAxis = fullName:match("(.+)%.axis_(.+)_([x|y])$") -- see if this is a vectorable axis

	if iMethod then
		-- Because gamepad events in LOVE use 1D axes and never 2D ones, we must wait for both axes of the 2D one to be updated before updating the vector.
		local vectorName = iMethod .. ".vector_" .. iName
		local iValue = ({...})[1]
		if iAxis == "x" then
			local oppositeAxis = iMethod .. ".axis_" .. iName .. "_y"
			oppositeAxis = state[oppositeAxis]
			oppositeAxis = oppositeAxis and oppositeAxis[1] or 0
			vectorsThisFrame[vectorName] = {player = player, x = iValue, y = oppositeAxis}
		else
			local oppositeAxis = iMethod .. ".axis_" .. iName .. "_x"
			oppositeAxis = state[oppositeAxis]
			oppositeAxis = oppositeAxis and oppositeAxis[1] or 0
			vectorsThisFrame[vectorName] = {player = player, x = oppositeAxis, y = iValue}
		end
	end

	

	input.rawinput:fire(fullName, player, ...)

end

event.keypressed:connect(function(key, scancode, isrepeat)
	if not isrepeat then
		handleInput("key." .. key, -1, true)
	end
end)

event.keyreleased:connect(function(key)
	handleInput("key." .. key, -1, false)
end)

event.mousemoved:connect(function(x, y, dx, dy, istouch)
	-- probably should filter these out when trying to bind inputs
	handleInput("mouse.axis_pos_x", -1, x)
	handleInput("mouse.axis_pos_y", -1, y)
	handleInput("mouse.axis_delta_x", -1, dx)
	handleInput("mouse.axis_delta_y", -1, dy)
end)

event.mousepressed:connect(function(x, y, button, istouch, presses)
	handleInput("mouse.button_" .. button, -1, true)
end)

event.mousereleased:connect(function(x, y, button, istouch, presses)
	handleInput("mouse.button_" .. button, -1, false)
end)

event.wheelmoved:connect(function(x, y)
	handleInput("mouse.axis_scroll_x", -1, x)
	handleInput("mouse.axis_scroll_y", -1, y)
end)


local gamepadMap = {
	a = "button_south",
	b = "button_east",
	x = "button_west",
	y = "button_north",
	back = "button_back",
	guide = "button_guide",
	start = "button_start",
	leftstick = "button_lstick",
	rightstick = "button_rstick",
	leftshoulder = "button_lshoulder",
	rightshoulder = "button_rshoulder",
	dpup = "button_dpad_up",
	dpdown = "button_dpad_down",
	dpleft = "button_dpad_left",
	dpright = "button_dpad_right",
	leftx = "axis_lstick_x",
	lefty = "axis_lstick_y",
	rightx = "axis_rstick_x",
	righty = "axis_rstick_y",
	triggerleft = "axis_ltrigger",
	triggerright = "axis_rtrigger"
}
local gamepadButtonAxisMap = {
	dpup = {"axis_dpad_y", -1},
	dpdown = {"axis_dpad_y", 1},
	dpleft = {"axis_dpad_x", -1},
	dpright = {"axis_dpad_x", 1}
}

local joystickLookupByObject = {}
local joystickLookupByPlayer = {}

local disconnectedJoysticksThisUpdate = {}

event.joystickadded:connect(function(joystick)

	if joystick:isGamepad() then
		
		local ply
		for i = 1, 16 do
			if joystickLookupByPlayer[i] == nil or disconnectedJoysticksThisUpdate[i] then
				ply = i
				break
			end
		end
		assert(ply ~= nil, "No more player slots (max 16)")
	
		print("GAMEPAD CONNECTED #" .. tostring(ply))
		if disconnectedJoysticksThisUpdate[ply] then -- reusing this slot in this frame. WEIRD EDGE CASE I KNOW BUT I'M THINKING OF EVERYTHING!
			print("> REUSING SLOT DISCONNECTED THIS FRAME")
			handleInput("gamepad.event_disconnect", ply)
			disconnectedJoysticksThisUpdate[ply] = nil
		end

		joystickLookupByObject[joystick] = ply
		joystickLookupByPlayer[ply] = joystick

		handleInput("gamepad.event_connect", ply)
	end

end)

event.joystickremoved:connect(function(joystick)

	local ply = joystickLookupByObject[joystick]
	if ply == nil then
		print("WARNING: Joystick disconnected, but couldn't find an associated player number.")
		return
	end
	print("GAMEPAD DISCONNECTED #" .. tostring(ply))
	
	disconnectedJoysticksThisUpdate[ply] = joystick

end)

event.gamepadpressed:connect(function(joystick, button)

	local index = joystickLookupByObject[joystick]
	if index == nil then
		print("WARNING: Received joystick input for non-gamepad controller. (gamepadpressed: " .. tostring(button) .. ")")
		return
	end


	local mapped = gamepadMap[button] or button

	handleInput("gamepad." .. mapped, index, true)

	local axisMapped = gamepadButtonAxisMap[button]
	if axisMapped then
		handleInput("gamepad." .. axisMapped[1], index, axisMapped[2])
	end

end)

event.gamepadreleased:connect(function(joystick, button)

	local index = joystickLookupByObject[joystick]
	if index == nil then
		print("WARNING: Received joystick input for non-gamepad controller. (gamepadreleased: " .. tostring(button) .. ")")
		return
	end

	local mapped = gamepadMap[button] or button

	handleInput("gamepad." .. mapped, index, false)

	local axisMapped = gamepadButtonAxisMap[button]
	if axisMapped then
		handleInput("gamepad." .. axisMapped[1], index, 0)
	end

end)

event.gamepadaxis:connect(function(joystick, axis, value)

	local index = joystickLookupByObject[joystick]
	if index == nil then
		print("WARNING: Received joystick input for non-gamepad controller. (gamepadaxis: " .. tostring(axis) .. ", " .. tostring(value) .. ")")
		return
	end

	local mapped = gamepadMap[axis] or axis

	handleInput("gamepad." .. mapped, index, value)

end)

event.preupdate:connect(function(dt)

	for vectorName, vector in pairs(vectorsThisFrame) do
		handleInput(vectorName, vector.player, vector.x, vector.y)
	end

	for ply, joystick in pairs(disconnectedJoysticksThisUpdate) do
		joystickLookupByObject[joystick] = nil
		joystickLookupByPlayer[ply] = nil
		print("GAMEPAD !!TRULY!! DISCONNECTED #" .. tostring(ply))
		handleInput("gamepad.event_disconnect", ply)
	end

	vectorsThisFrame = {}
	disconnectedJoysticksThisUpdate = {}


end)


return input

