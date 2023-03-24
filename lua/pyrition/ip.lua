--https://github.com/danielga/gmsv_serversecure/blob/71c584f175f03704d7892c1c0b38c0f351b106ec/includes/modules/serversecure.lua#L5-L29

--pyrition functions
function PYRITION._IPToString(numerical_ip)
	local a, b, c, d =
		bit.band(bit.rshift(numerical_ip, 24), 0xFF),
		bit.band(bit.rshift(numerical_ip, 16), 0xFF),
		bit.band(bit.rshift(numerical_ip, 8), 0xFF),
		bit.band(numerical_ip, 0xFF)
	return string.format("%d.%d.%d.%d", d, c, b, a)
end

function PYRITION._StringToIP(text)
	local alpha, bravo, charlie, delta = string.match(text, "^(%d+)%.(%d+)%.(%d+)%.(%d+)")

	if not delta then return end

	return ((d * 256 + charlie) * 256 + bravo) * 256 + alpha
end