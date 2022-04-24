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

---Returns a percentage (0-1) of how far through a given time is through a specified range
---@param time number
---@param from number Start of range
---@param to number End of range
---@param clamp boolean Whether to clamp result to 0 - 1
---@return number Fraction
function timeFrac(time, from, to, clamp)
	
	if clamp then
		return math.max(0, math.min(1, (time - from) / (to - from)))
	else
		return (time - from) / (to - from)
	end

end

function lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end
