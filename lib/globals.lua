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
