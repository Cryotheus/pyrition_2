local max_clients_bits = game.MaxPlayers()
local max_players_bits = max_clients_bits + 1 --we add 1 because 0 is used for the world/console
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

local function read_client() return Entity(net.ReadUInt(max_clients_bits) + 1) end
local function read_player() return Entity(net.ReadUInt(max_players_bits)) end
local function write_client(ply) net.WriteUInt(ply:EntIndex() - 1, max_clients_bits) end --just writes players
local function write_player(ply) net.WriteUInt(ply:EntIndex(), max_players_bits) end --also writes the world entity to represent the server/console

--post function setup
max_clients_bits = bits(max_clients_bits)
max_players_bits = bits(max_players_bits)

--globals
PYRITION.NetEnumeratedStrings = net_enumerations
PYRITION.NetEnumerationBits = net_enumeration_bits
PYRITION.NetMaxClientBits = max_clients_bits
PYRITION.NetMaxPlayerBits = max_players_bits
PYRITION._Bits = bits --internal
PYRITION._MaybeRead = maybe_read
PYRITION._MaybeWrite = maybe_write
PYRITION._ReadClient = read_client
PYRITION._ReadPlayer = read_player
PYRITION._WriteClient = write_client
PYRITION._WritePlayer = write_player

--pyrition functions
function PYRITION:NetThink()
	if SERVER then self:NetThinkServer() end
	if next(self.NetStreamModelsQueued) then self:NetStreamModelThink() end
	if next(self.NetStreamQueue) then self:NetStreamThink() end
end

--hooks
hook.Add("Think", "PyritionNet", function() PYRITION:NetThink() end)