--translate a rgba color into a "digital" color (32 bit unsigned integer of the color)
--calling it digital because it faintly reminds me of digital screens from Wire
function PYRITION._DigitalColor(digital_color)
	local color_r = math.floor(digital_color / 0x1000000)
	local color_g = math.floor(digital_color / 0x10000) % 0x100
	local color_b = math.floor(digital_color / 0x100) % 0x100
	local color_a = digital_color % 0x100
	
	return color_r, color_g, color_b, color_a
end

function PYRITION._ToDigitalColor(r, g, b, a)
	if g then a = a or 255
	else r, g, b, a = r:Unpack() end
	
	local digital_color = r * 0x1000000 + g * 0x10000 + b * 0x100 + a
	
	return digital_color
end