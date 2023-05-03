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
input.rawinput = event.create() -- Fired when any single input is fired. Player is -1 unless it is a gamepad input

---Represents a player and their inputs
---@class PlayerInput
---@field maps table<ActionMap>
---@field player number Player index
local PINPUT = {}

---Sends the given RawInput event args to all listening `ActionMap`s
---@param iName string Input name
---@param player number Player index
---@vararg any
function PINPUT:fire(iName, player, ...)

	for mapName, map in pairs(self.maps) do
		if map.enabled then
			map.event:fire(iName, player, ...)
		end
	end

end











---@class State
---@field state table<any>
---@field changed Event
local STATE = {}
STATE.__meta = STATE

---@param k number
function STATE:__index(k)
	if type(k) == "number" then
		return self.state[k]
	end
end

---@param ... any
---@return table oldState Returns old state if a change was made
function STATE:set(...)
	local oldState = self.state
	local newState = {...}
	
	local aLen, bLen = #oldState, #newState
	if aLen ~= bLen then
		self.state = newState
		if self.changed.listened then
			self.changed:fire(table.copy(newState), table.copy(oldState))
		end

		return oldState
	end

	for i = 1, bLen do
		if oldState[i] ~= newState[i] then
			self.state = newState
			if self.changed.listened then
				self.changed:fire(table.copy(newState), table.copy(oldState))
			end
			return oldState
		end
	end

end

---Sets an individual parameter of the state
---@param i number Index
---@param value any
---@return boolean changed
---@return any oldValue
function STATE:setSingle(i, value)
	local oldValue = self.state[i]
	if oldValue ~= value then
		if self.changed.listened then
			local oldState = table.copy(self.state)
			local newState = table.copy(self.state)
			newState[i] = value
			self.changed:fire(newState, oldState)
		end
		self.state[i] = value
		self.changed:fire()
		return true, oldValue
	end
	return false
end

local function createState(...)

	local state = setmetatable({
		state = {...},
		changed = event.create()
	}, {__index = STATE})

	return state

end








---@class Binding
---@field action Action
local BINDING = {}

---Creates a Binding to map certain rawinput events to the output of an Action
---@param deviceFilter table<string>
local function createBinding(deviceFilter, ...)

	local binding = setmetatable({

	}, {__index = BINDING})

	return binding

end



local function computeDeadzone(value, min, max)

	max = max or 1
	if value >= 0 then
		return mapFrac(value, min, max, true)
	else
		return mapFrac(value, -max, -min, true)
	end

end

---@class ButtonAxisHandler
---@field state State
---@field output function
local BAXISHANDLER = {}

---Handles the input of a button for the axis.
---@param index number 1 for positive, 2 for negative
---@param pressed boolean
function BAXISHANDLER:handleInput(index, pressed)

	local state = self.state
	if state:setSingle(index, pressed) then
		if not state[1] and not state[2] then
			-- idle
			self.output(0)
		else
			if pressed then
				self.output(index == 1 and 1 or -1)
			else
				self.output(index == 1 and -1 or 1)
			end
		end
	end

end

---Creates a ButtonAxisHandler to map 2 button inputs to a signed 1D axis [-1, 1]
---@return ButtonAxisHandler handler
local function createAxisHandler()

	local handler = setmetatable({
		state = createState(false, false),
		output = event.create()
	}, {__index = BAXISHANDLER})

	return handler

end


--[[
	 
	A lookup table for different typed of bindings. The structure is as follows:
		BindingTypes.mapFromDevice.mapToDevice
	which will point to an "interface" table.
	Interface structure:
		name			type
			desc
		--------------------
		init			function(self)
			Invoked upon creation of the Binding

		handleInput		function(self, index, pressed)
			Invoked upon the raw change of any inputs listened to by this Binding
			index is the index of this input in the default/override tables from the Binding class

		inputType		string
			Type of device to listen to for inputs. May be:
			button|axis|vector|event
		
		requiredInputs	number
			Number of inputs required to be listened to.

		outputType		string
			The type of the signal that is outputted from the Binding to be dispatched by its parenting Action. May be:
			button|axis|vector|event
			This must match the outputType of the Action or an error will be thrown.
	Each unique interface may also have additional fields
	
	A Binding shall __index its corresponding interface.
	Meanwhile a Binding class will have the following structure:
		name					type
			desc
		--------------------
		action					Action
			Parent action
		default					table<string>
			Ordered list of input names to listen to by default
		override				table<string>
			Same as above, but overrides the default input of the same key in the table.
		state					State
			
		
]]
local BindingTypes = {

	-- button -> button
	button = {
		inputType = "button",
		outputType = "button",
		requiredInputs = 1,

		init = function(self)
			self.state = createState(false)
		end,

		handleInput = function(self, index, pressed)
			
			if self.state:set(pressed) then
				if pressed then
					self.action.started:fire(pressed)
				else
					self.action.stopped:fire(pressed)
				end
				self.action.changed:fire(pressed)
			end

		end,

		captureInput = function(self, fullName, pressed)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			return iType == "button" and pressed
		end,
	},

	-- axis -> axis
	axis = {
		
		inputType = "axis",
		outputType = "axis",
		requiredInputs = 1,

		deadzoneMin = 0.1,
		deadzoneMax = 1,

		init = function(self)
			self.state = createState(0)
		end,

		handleInput = function(self, index, value)

			value = computeDeadzone(value, self.deadzoneMin, self.deadzoneMax)
			
			local old = self.state:set(value)
			if old then
				if old[1] == 0 then
					self.action.started:fire(value)
				elseif value == 0 then
					self.action.stopped:fire(value)
				end
				self.action.changed:fire(value)
			end

		end,

		captureInput = function(self, fullName, value)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			if iType ~= "axis" then return false end
			value = computeDeadzone(value, self.deadzoneMin, self.deadzoneMax)

			return value ~= 0
		end
	},

	-- vector -> vector
	vector = {
		inputType = "vector",
		outputType = "vector",
		requiredInputs = 1,

		deadzoneMinX = 0.1,
		deadzoneMaxX = 1,
		deadzoneMinY = 0.1,
		deadzoneMaxY = 1,

		init = function(self)
			self.state = createState(0, 0)
		end,

		handleInput = function(self, index, x, y)

			x = computeDeadzone(x, self.deadzoneMinX, self.deadzoneMaxX)
			y = computeDeadzone(y, self.deadzoneMinY, self.deadzoneMaxY)

			local old = self.state:set(x, y)
			if old then
				if old[1] == 0 and old[2] == 0 then
					self.action.started:fire(x, y)
				elseif x == 0 and y == 0 then
					self.action.stopped:fire(x, y)
				end
				self.action.changed:fire(x, y)
			end

		end,

		captureInput = function(self, fullName, x, y)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			if iType ~= "vector" then return false end
			x = computeDeadzone(x, self.deadzoneMinX, self.deadzoneMaxX)
			y = computeDeadzone(y, self.deadzoneMinY, self.deadzoneMaxY)
			return x ~= -0 or y ~= 0
		end
	},

	-- event -> event
	event = {
		inputType = "event",
		outputType = "event",
		requiredInputs = 1,

		init = function(self) end,

		handleInput = function(self, index, ...)
			self.action.started:fire(...)
		end,

		captureInput = function(self, fullName, ...)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			return iType == "event"
		end
	},

	-- button -> axis (signed; [-1, 1])
	button2axis = {
		inputType = "button",
		outputType = "axis",
		requiredInputs = 2,

		init = function(self)
			self.handler = createAxisHandler()
			self.state = createState(0)
			self.handler.output = function(newValue)
				local changed, oldValue = self.state:setSingle(1, newValue)
				if changed then
					if oldValue == 0 then
						self.action.started:fire(newValue)
					elseif newValue == 0 then
						self.action.stopped:fire(0)
					end
					self.action.changed:fire(newValue)
				end
			end
		end,

		handleInput = function(self, index, pressed)
			self.handler:handleInput(index, pressed)
		end,

		captureInput = function(self, fullName, pressed)
			
	},

	button2vector = {
		inputType = "button",
		outputType = "vector",
		requiredInputs = 4,

		init = function(self)
			self.handlerX = createAxisHandler()
			self.handlerY = createAxisHandler()

			self.state = createState(0, 0)
			local function handleAxis(x, y)

				local old = self.state:set(x, y)
				if old then
					if old[1] == 0 and old[2] == 0 then
						self.action.started:fire(x, y)
					elseif x == 0 and y == 0 then
						self.action.stopped:fire(x, y)
					end
					self.action.changed:fire(x, y)
				end

			end
			self.handlerX.output = function(value)
				handleAxis(value, self.state[2])
			end
			self.handlerY.output = function(value)
				handleAxis(self.state[1], value)
			end

		end,

		handleInput = function(self, index, pressed)

			if index <= 2 then
				self.handlerX:handleInput(index, pressed)
			else
				self.handlerY:handleInput(index-2, pressed)
			end

		end
	},

	button2event = {
		inputType = "button",
		outputType = "event",
		requiredInputs = 1,

		init = function(self)
			self.state = createState(false)
		end,

		handleInput = function(self, index, pressed)
			if self.state:set(pressed) and pressed then
				self.action.started:fire()
			end
		end
	},




	axis2button = {
		inputType = "axis",
		outputType = "button",
		requiredInputs = 1,

		deadzoneMin = 0.85,
		deadzoneMax = 1,
		positive = true,
		overridePositive = nil,

		init = function(self)
			self.state = createState(0)
		end,

		handleInput = function(self, index, value)
			value = computeDeadzone(value, self.deadzoneMin, self.deadzoneMax)
			local positive = value > 0
			local old = self.state:set(value)
			if old then
				if old[1] == 0 then
					self.action.started:fire(1)
				else
					self.action.stopped:fire(0)
				end
				self.action.changed:fire(value)
			end
		end

	}
}

---@class Action
---@field started Event
---@field changed Event
---@field stopped Event
local ACTION = {}


--[[
	Creates a `PlayerInput` object from a given table of the following structure:

	{
		["actionMapName"] = {
			["action1"] = {
				type = "button|axis|vector|event",
				bindings = {
					{
						method = "keymouse",
						type = "single|composite_1d|composite_2d"
						inputs = {...},
						overrideInputs = {...}, -- optional field
					}
				}
			}
		}
	}
]]
---@param player any
---@param actionTable any
---@return table
local function createPlayerInput(player, actionTable)

	local playerInput = setmetatable({
		maps = {},
		player = player
	}, {__index = PINPUT})



	return playerInput

end

---@class ActionMap
---@field enabled boolean
---@field event Event Event broadcaster for [Binding]s to listen to
---@field name string
local MAP = {}


local function createActionMap(name, enabled)

end

local function handleInput(fullName, player, ...)

	if rawInputState[player] == nil then
		rawInputState[player] = {}
	end
	local state = rawInputState[player]
	state[fullName] = {...}
	local iMethod, iName, iAxis = fullName:match("(.+)%.axis_(.+)_([x|y])$") -- see if this is an axis

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

event.joystickadded:connect(function(joystick)

	if joystick:isGamepad() then
		handleInput("gamepad.event_connect", joystick:getConnectedIndex())
	end

end)

event.joystickremoved:connect(function(joystick)

	if joystick:isGamepad() then
		handleInput("gamepad.event_disconnect", joystick:getConnectedIndex())
	end

end)

event.gamepadpressed:connect(function(joystick, button)

	local mapped = gamepadMap[button] or button
	local index = joystick:getConnectedIndex()

	handleInput("gamepad." .. mapped, index, true)

	local axisMapped = gamepadButtonAxisMap[button]
	if axisMapped then
		handleInput("gamepad." .. axisMapped[1], index, axisMapped[2])
	end

end)

event.gamepadreleased:connect(function(joystick, button)

	local mapped = gamepadMap[button] or button
	local index = joystick:getConnectedIndex()

	handleInput("gamepad." .. mapped, index, false)

	local axisMapped = gamepadButtonAxisMap[button]
	if axisMapped then
		handleInput("gamepad." .. axisMapped[1], index, 0)
	end

end)

event.gamepadaxis:connect(function(joystick, axis, value)

	local mapped = gamepadMap[axis] or axis
	local index = joystick:getConnectedIndex()

	handleInput("gamepad." .. mapped, index, value)

end)

event.preupdate:connect(function(dt)

	for vectorName, vector in pairs(vectorsThisFrame) do
		handleInput(vectorName, vector.player, vector.x, vector.y)
	end

	vectorsThisFrame = {}

end)


return input

