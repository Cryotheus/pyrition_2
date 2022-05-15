local net_enumerations = PYRITION.NetEnumeratedStrings or {} --dictionary[namespace] = duplex[string]
local net_enumeration_bits = PYRITION.NetEnumerationBits or {} --dictionary[namespace] = bits

--local functions
local function bits(number) return number == 1 and 1 or math.ceil(math.log(number, 2)) end

--globals
PYRITION.NetEnumeratedStrings = net_enumerations
PYRITION.NetEnumerationBits = net_enumeration_bits
PYRITION._Bits = bits --internal