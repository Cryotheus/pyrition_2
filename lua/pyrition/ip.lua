--https://github.com/danielga/gmsv_serversecure/blob/71c584f175f03704d7892c1c0b38c0f351b106ec/includes/modules/serversecure.lua#L5-L29

--pyrition functions
function PYRITION._IPToString(numerical_ip)
	---ARGUMENTS: number "32 bit unsigned integer"
	---RETURNS: string
	---SEE: PYRITION._StringToIP
	return
		bit.band(bit.rshift(numerical_ip, 24), 0xFF) .. "." ..
		bit.band(bit.rshift(numerical_ip, 16), 0xFF) .. "." ..
		bit.band(bit.rshift(numerical_ip, 8), 0xFF) .. "." ..
		bit.band(numerical_ip, 0xFF)
end

function PYRITION._StringToIP(text)
	---ARGUMENTS: string "IP address"
	---RETURNS: number
	---SEE: PYRITION._IPToString
	local first, second, third, fourth = string.match(text, "^(%d+)%.(%d+)%.(%d+)%.(%d+)")

	if not fourth then return end

	return ((fourth * 0x100 + third) * 0x100 + second) * 0x100 + first
end