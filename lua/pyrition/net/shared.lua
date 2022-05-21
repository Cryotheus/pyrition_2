local max_players_bits = game.MaxPlayers() + 1 --we add 1 because 0 is used for the world/console
local net_enumerations = PYRITION.NetEnumeratedStrings or {} --dictionary[namespace] = duplex[string]
local net_enumeration_bits = PYRITION.NetEnumerationBits or {} --dictionary[namespace] = bits

--local functions
local function bits(number) return number == 1 and 1 or math.ceil(math.log(number, 2)) end
local function maybe_read(net_function, ...) if net.ReadBool() then return net_function(...) end end

local function maybe_write(net_function, value, ...)
	if value == nil then return net.WriteBool(false) end
	
	net.WriteBool(true)
	net_function(value, ...)
end

local function read_player() return Entity(net.ReadUInt(max_players_bits)) end
local function write_player(ply) print("writing", ply) net.WriteUInt(ply:EntIndex(), max_players_bits) end

--globals
max_players_bits = bits(max_players_bits)

PYRITION.NetEnumeratedStrings = net_enumerations
PYRITION.NetEnumerationBits = net_enumeration_bits
PYRITION.NetMaxPlayerBits = max_players_bits
PYRITION._Bits = bits --internal
PYRITION._MaybeRead = maybe_read
PYRITION._MaybeWrite = maybe_write
PYRITION._ReadPlayer = read_player
PYRITION._WritePlayer = write_player