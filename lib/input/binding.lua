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

local event = require "lib.event"
local binding = {}

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







---@class Processor
---@field funcs table<function>
local PROC = {}
function PROC:call(...)
	local args = {...}
	for _, func in ipairs(self.funcs) do
		args = {func(unpack(args))}
		if #args == 0 then return end
	end
	return unpack(args)
end
local function createProcessor()

	return setmetatable({
		funcs = {}
	}, {__index = PROC})

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
---@return any output Resulting output value
function BAXISHANDLER:handleInput(index, pressed)

	local state = self.state
	if state:setSingle(index, pressed) then
		if not state[1] and not state[2] then
			-- idle
			return self.output(0)
		else
			if pressed then
				return self.output(index == 1 and 1 or -1)
			else
				return self.output(index == 1 and -1 or 1)
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
		
]]
local BindingTypes = {

	-- button -> button
	button = {
		inputType = "button",
		outputType = "button",
		requiredInputs = 1,

		init = function(self) end,

		handleInput = function(self, index, pressed)
			
			return self.processor:call(pressed)

		end,

		--[[captureInput = function(self, fullName, pressed)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			return iType == "button" and pressed
		end,]]
	},

	-- axis -> axis
	axis = {
		
		inputType = "axis",
		outputType = "axis",
		requiredInputs = 1,

		--[[deadzoneMin = 0.1,
		deadzoneMax = 1,]]

		init = function(self) end,

		handleInput = function(self, index, value)

			return self.processor:call(value)

		end,

		--[[captureInput = function(self, fullName, value)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			if iType ~= "axis" then return false end
			value = computeDeadzone(value, self.deadzoneMin, self.deadzoneMax)

			return value ~= 0
		end]]
	},

	-- vector -> vector
	vector = {
		inputType = "vector",
		outputType = "vector",
		requiredInputs = 1,

		--[[deadzoneMinX = 0.1,
		deadzoneMaxX = 1,
		deadzoneMinY = 0.1,
		deadzoneMaxY = 1,]]

		init = function(self) end,

		handleInput = function(self, index, x, y)

			return self.processor:call(x, y)

		end,

		--[[captureInput = function(self, fullName, x, y)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			if iType ~= "vector" then return false end
			x = computeDeadzone(x, self.deadzoneMinX, self.deadzoneMaxX)
			y = computeDeadzone(y, self.deadzoneMinY, self.deadzoneMaxY)
			return x ~= -0 or y ~= 0
		end]]
	},

	-- event -> event
	event = {
		inputType = "event",
		outputType = "event",
		requiredInputs = 1,

		init = function(self) end,

		handleInput = function(self, index, ...)
			return self.processor:call(...)
		end,

		--[[captureInput = function(self, fullName, ...)
			local iDevice, iType, iName = fullName:match("(.+)%.(.+)_(.+)$")
			return iType == "event"
		end]]
	},

	-- button -> axis (signed; [-1, 1])
	button2axis = {
		inputType = "button",
		outputType = "axis",
		requiredInputs = 2,

		init = function(self)
			self.handler = createAxisHandler()
			self.handler.output = function(newValue)
				return self.processor:call(newValue)
			end
		end,

		handleInput = function(self, index, pressed)
			return self.handler:handleInput(index, pressed)
		end,

		--[[captureInput = function(self, fullName, pressed)
			-- TODO FIX ;)
		end]]
			
	},

	button2vector = {
		inputType = "button",
		outputType = "vector",
		requiredInputs = 4,

		init = function(self)
			self.handlerX = createAxisHandler()
			self.handlerY = createAxisHandler()

			self._x = 0
			self._y = 0
			local function handleAxis(x, y)

				self._x = x
				self._y = y
				return self.processor:call(x, y)

			end
			self.handlerX.output = function(value)
				return handleAxis(value, self._y)
			end
			self.handlerY.output = function(value)
				return handleAxis(self._x, value)
			end

		end,

		handleInput = function(self, index, pressed)

			print("handleInput button2vector", index, pressed)
			if index <= 2 then
				return self.handlerX:handleInput(index, pressed)
			else
				return self.handlerY:handleInput(index-2, pressed)
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
				return true
			end
		end
	},




	axis2button = {
		inputType = "axis",
		outputType = "button",
		requiredInputs = 1,

		--[[deadzoneMin = 0.85,
		deadzoneMax = 1,]]
		positive = true,

		init = function(self)
			self.state = createState(0)
		end,

		handleInput = function(self, index, value)
			return self.processor:call(value)
		end

	}
}

---@class Action
---@field started Event
---@field changed Event
---@field stopped Event
---@field type string
---@field bindings table<Binding>
---@field processor Processor
---@field _inputCount number
---@field _state State
local ACTION = {}

function ACTION:fire(...)

	local args = {...}
	if self.type == "event" then
		args = {self.processor:call(...)}
		if #args ~= 0 then
			self.started:fire(unpack(args))
		end
		return
	end

	local len = #args
	if len ~= self._inputCount then
		error("Action fired with unexpected number of args (expected " .. self._inputCount .. ", got " .. len .. "). Does the Binding have the correct output type?")
	end

	args = {self.processor:call(...)}
	if #args == 0 then return end

	local old = self._state:set(unpack(args))
	if old then

		if self.type == "button" then
			if args[1] then
				self.started:fire(args[1])
			else
				self.stopped:fire(args[1])
			end
			self.changed:fire(args[1])
		
		elseif self.type == "axis" then
			if old[1] == 0 then
				self.started:fire(args[1])
			else
				self.stopped:fire(args[1])
			end

			self.changed:fire(args[1])

		elseif self.type == "vector" then
			if old[1] == 0 and old[2] == 0 then
				self.started:fire(args[1], args[2])
			elseif args[1] == 0 and args[2] == 0 then
				self.stopped:fire(args[1], args[2])
			end

			self.changed:fire(args[1], args[2])

		else
			error("Action was fired, but action has invalid type \"" .. tostring(self.type) .. "\"")
		end

	end


end

local BindingTypeMap = {
	button = {
		button = BindingTypes.button,
		axis = BindingTypes.button2axis,
		vector = BindingTypes.button2vector,
		event = BindingTypes.button2vector
	},
	axis = {
		button = BindingTypes.axis2button,
		axis = BindingTypes.axis,
	},
	vector = {
		vector = BindingTypes.vector
	},
	event = {
		event = BindingTypes.event
	}
}



---@class Binding
---@field action Action
---@field inputs table<string>
---@field processor Processor
---@field requiredInputs number
local BINDING = {}

function BINDING:disconnect()

end

--- To be overridden by interface
function BINDING:init()
	error(":init() on binding that hasn't been set up")
end

--- To be overridden by interface
---@param index number Which input this is (in table BINDING.inputs)
---@vararg any 
---@return any Result The resulting input value to be passed to the Action
function BINDING:handleInput(index, ...)
	error(":handleInput() on binding that hasn't been set up")
end

---Creates a Binding to map certain rawinput events to the output of an Action
---@param action Action Action to link to
---@param inputType string button|axis|vector|event
---@param scheme string desktop|gamepad
local function createBinding(action, inputType, scheme, ...)

	assert(action ~= nil, "Action is nil")

	local interface = BindingTypeMap[inputType]
	assert(interface ~= nil, "Binding input type \"" .. tostring(inputType) .. "\" does not exist.")
	interface = interface[action.type]
	assert(interface ~= nil, "Binding input from type \"" .. tostring(inputType) .. "\" to \"" .. tostring(action.type) .. "\" does not exist.")

	print("found interface " .. tostring(interface.inputType) .. "." .. tostring(interface.outputType))

	local bindingObj = setmetatable({
		action = action,
		inputType = inputType,
		requiredInputs = interface.requiredInputs,
		processor = createProcessor(),
		init = interface.init,
		handleInput = interface.handleInput,
		inputs = {}

	}, {__index = BINDING})

	bindingObj:init()

	return bindingObj

end

binding.createBinding = createBinding

local function createAction(type)

	local action = setmetatable({
		started = event.create(),
		changed = event.create(),
		stopped = event.create(),

		type = type,
		bindings = {},
		processor = createProcessor()
	}, {__index = ACTION})

	if type == "button" then
		action._inputCount = 1
		action._state = createState(false)
	elseif type == "axis" then
		action._inputCount = 1
		action._state = createState(0)
	elseif type == "vector" then
		action._inputCount = 2
		action._state = createState(0, 0)
	elseif type == "event" then
		action._inputCount = -1
	else
		error("Cannot create Action of bad type \"" .. tostring(type) .. "\"")
	end

	return action
end

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
---@field bindings table<any>
local MAP = {}

--[[
	Here's the structure definition of the `bindings` table. It maps any input to a Binding that is listening.
	If a binding is added, modified, or removed, this table must be updated/refreshed.

	bindings = {
		["inputName"] = {Binding1, Binding2}
	}
]]

local function createActionMap(name, enabled)

	local actionMap

end



--[[



	STRUCTURE REFACTORING

	Action
		<ABSTRACT>: Links one or more binding(s) to a certain action (movement, reload, etc.)
		input: {binding1, binding2, ...}
		output: button|axis|vector|event
		processors: {}

	Binding
		<ABSTRACT>:	Defines which input(s) to listen to before passing the information to the linked Action.
					Output information must match expected input of the Action
		type: button|button2axis|axis2button|...
			Input conversion type
		action: <Action>
			Linked action to fire
		inputs: {inputName1, inputName2, ...}
			Inputs to listen to.
		processors: {}
			An ordered list of modifier functions for this input.
		


	PlayerInput (player 1)
		ActionMap (map1; e.g. menu controls)
		ActionMap (map2; e.g. movement controls)

]]

binding.createAction = createAction
return binding
