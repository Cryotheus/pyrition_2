--credits:
--	Nak2 for showing a better way to handle floats
--	https://github.com/Nak2/NikNaks/blob/6269e40979ff8e51177eacab4b853c0ec01889cc/lua/niknaks/modules/sh_bytebuffer.lua#L596-L643

--1st class function nation :D
local block_convar
local drint = PYRITION._drint
local read_enumerated_string = PYRITION._ReadEnumeratedString
local wordless
local write_enumerated_string = PYRITION._WriteEnumeratedString

--local globals
local active_streams = PYRITION.NetStreamsActive or {} --table[ply][class][uid] = stream, but on CLIENT its table[class][uid]
local max_players_bits = PYRITION.NetMaxPlayerBits
local max_clients_bits = PYRITION.NetMaxClientBits
local net_enumeration_bits = PYRITION.NetEnumerationBits
local stream_classes = PYRITION.NetStreamClasses or {} --table[class] = bool: should we recieve it?
local stream_counters = PYRITION.NetStreamCounters or {} --table[class] = uid
local stream_send_queue = PYRITION.NetStreamQueue or {} --list of streams, on server its table[ply] = list
local _R = debug.getregistry()

--convars
local convar_flags = bit.bor(SERVER and FCVAR_ARCHIVE or 0, FCVAR_REPLICATED)
local pyrition_net_stream_bytes = CreateConVar("pyrition_net_stream_bytes", "64000", convar_flags, "string helptext", 1024, 64000)
local pyrition_net_stream_channels = CreateConVar("pyrition_net_stream_channels", "8", convar_flags, "string helptext", 1)
local pyrition_net_stream_size = CreateConVar("pyrition_net_stream_size", "16000", convar_flags, "string helptext", 1024, 16000)

--cached convars
local maximum_bytes_sent = pyrition_net_stream_bytes:GetInt()
local maximum_layer_size = pyrition_net_stream_channels:GetInt()
local maximum_stream_size = pyrition_net_stream_size:GetInt() * 1024

--local tables
local stream_meta = {
	BitsWritten = 0,
	Byte = 0,
	Class = "none",
	EnumerateClass = true,
	IsPyritionStream = true,
	Pointer = 1,
	PointerBit = 0,
	Priority = 0,
	Sending = false
}

local stream_public = {__index = stream_meta, __name = "PyritionStream"}

----constants
	local char_limit = 0x320 --0d8000, the limit for string_byte and string_char
	local char_offset = char_limit - 1
	local char_start = char_limit + 1
	local drint_level = 1
	local float_exponent = 0x800000 --2 ^ 23
	local float_nan = 0x7FFFFFFF --2 ^ 31 - 1
	local float_mask = 0x007FFFFF --one less than float_exponent
	local float_sign = 0x80000000 --2 ^ 31
	local long_mask = 0xFFFFFFFF
	local one_byte, zero_byte = string.byte("10", 1)
	local short_mask = 0xFFFF

----localized functions
	local Angle = Angle
	local bit_lshift = bit.lshift
	local bit_rshift = bit.rshift
	local bit_band = bit.band
	local bit_bor = bit.bor
	local ipairs = ipairs
	local math_ldexp = math.ldexp
	local math_floor = math.floor
	local math_frexp = math.frexp
	local math_huge = math.huge
	local math_min = math.min
	local math_random = math.random
	local net = net
	local net_ReadBool = net.ReadBool
	local net_ReadData = net.ReadData
	local net_ReadString = net.ReadString
	local net_ReadUInt = net.ReadUInt
	local net_WriteBool = net.WriteBool
	local net_WriteData = net.WriteData
	local net_WriteString = net.WriteString
	local net_WriteUInt = net.WriteUInt
	local string_byte = string.byte
	local string_char = string.char
	local string_sub = string.sub
	local SysTime = SysTime
	local table_Add = table.Add
	local table_insert = table.insert
	local table_remove = table.remove
	local table_sort = table.sort
	local tostring = tostring
	local unpack = unpack
	local Vector = Vector
----

--local functions
local function benchmark(key, samples, max_tries, try, generation)
	local stream = setmetatable({
		Data = "",
		Name = string.Replace(tostring(SysTime()), ".", "_"),
		Target = target
	}, stream_public)
	
	local generated = {}
	local method = stream[key]
	
	for index = 1, samples do table_insert(generated, {generation(stream, index)}) end
	
	local start_time = SysTime()
	
	for index = 1, samples do method(stream, unpack(generated[index])) end
	
	local duration = SysTime() - start_time
	
	if try < max_tries then duration = duration + benchmark(key, samples, max_tries, try + 1, generation) end
	
	if try == 1 then
		--MsgC(Color(255, 255, 0), key, color_white, " took ", Color(0, 0, 255), string.Comma(duration / max_tries * 1000000), color_white, " microseconds\n")
		MsgC(Color(255, 255, 0), key, color_white, " took ", Color(0, 0, 255), string.Comma(duration / max_tries * 1000), color_white, " milliseconds\n")
		--MsgC(Color(255, 255, 0), key, color_white, " took ", Color(0, 0, 255), string.Comma(duration / max_tries), color_white, " seconds\n")
	end
	
	return duration
end

local function byte_safe(text, index) return string_byte(text, index) or 0 end

local function bytes_safe(text, start, finish)
	local bytes = {string_byte(text, start, finish)}
	
	for index = #bytes + 1, finish do table_insert(bytes, 0) end
	
	return unpack(bytes)
end

local function descending_sort(sorted)
	table_sort(sorted, function(alpha, bravo) return alpha > bravo end)
	
	return sorted
end

local function get_left_mask(left_bits) return bit_band(bit_lshift(0xFF, 8 - left_bits), 0xFF) end
local function get_right_mask(right_bits) return 2 ^ right_bits - 1 end

local function get_uid(class)
	local uid = stream_counters[class] or 0
	
	uid = uid >= long_mask and 1 or uid + 1
	stream_counters[class or 1] = uid
	
	return uid
end

local function random_string(minimum, maximum)
	local bytes = {}
	
	for index = 1, math_random(minimum, maximum) do bytes[index] = math_random(65, 90) end
	
	return string_char(unpack(bytes))
end

local function read_float(long)
	local sign = bit_band(long, float_sign) == 0 and 1 or -1
	local exponential = wordless(bit_rshift(long, 23))
	local fractional = bit_band(long, float_mask) / float_exponent
	
	if exponential == 0 and fractional == 0 then return 0 * sign --zero and negative zero
	elseif exponential == 0xFF and fractional == 0 then return math_huge * sign --inf
	elseif exponential == 0xFF and fractional ~= 0 then return math_huge / math_huge end --nan
	
	return math_ldexp(1 + fractional, exponential - 0x7F) * sign
end

function wordless(oversized) return bit_band(oversized, 0xFF) end

local function write_bits(self, characters, integer, bits) --used for the WriteUInt method
	local bit_modulo = bits % 8
	
	for shift = bits - 8, 0, -8 do table_insert(characters, wordless(bit_rshift(integer, shift))) end
	
	self.Data = self.Data .. string_char(unpack(characters))
	
	--if we don't have any remaining bits to write, don't update Byte
	if bit_modulo == 0 then return end
	
	local written = 8 - bit_modulo
	
	self.BitsWritten = bit_modulo
	self.Byte = wordless(bit_lshift(integer, written))
end

local function write_float(float)
	local sign = 0 --1 bit sign of the float
	local fractional = 0 --23 bit fraction portion of float
	local exponential = 0 --8 bit exponent portion of float
	
	if float < 0 then sign, float = float_sign, -float end --store sign bit
	
	if float ~= float then return float_nan --nan
	elseif float == math_huge then exponential, fractional = 0xFF, 0 --inf
	elseif float ~= 0 then --non-zero
		fractional, exponential = math_frexp(float)
		exponential = exponential + 0x7F
		
		if exponential <= 0 then
			fractional = math_ldexp(fractional, exponential - 1)
			exponential = 0
		elseif exponential >= 0xFF then --became inf
			exponential = 0xFF
			fractional = 0
		elseif exponential == 1 then exponential = 0
		else fractional, exponential = fractional * 2 - 1, exponential - 1 end
	elseif tostring(float) == "-0" then sign = float_sign end --negative zero
	
	return bit_bor(sign,
		bit_lshift(wordless(exponential), 23),
		math_floor(math_ldexp(fractional, 23) + 0.5)
	)
end

--sided local functions
if CLIENT then function block_convar() return false end
else
	function block_convar(convar, internal, new)
		if new == internal then return end
		
		if player.GetCount() > 0 then
			convar:SetInt(internal)
			PYRITION:LanguageDisplay("convar", "pyrition.convar.fail.awake", nil, false)
			
			return true
		end
	end
end

--globals
PYRITION.NetStreamsActive = active_streams
PYRITION.NetStreamClasses = stream_classes
PYRITION.NetStreamCounters = stream_counters
PYRITION.NetStreamQueue = stream_send_queue
_R.PyritionStream = stream_public

--meta functions
function stream_public:__call(...) return self:Call(...) end

function stream_public:__tostring()
	local uid = self.UID
	
	if uid then return "PyritionStream [" .. self.Class .. ":" .. uid .. "]["  .. self:Size() ..  "][" .. self.Target .. self.Name .. "]" end
	
	return "PyritionStream [" .. self.Class .. "]["  .. self:Size() ..  "][" .. self.Target .. self.Name .. "]"
end

function stream_meta:Distance() return self.Pointer * 8 + self.PointerBit - 8 end

function stream_meta:Dump(zeros)
	local data = self.Data
	local dump = {}
	local target = self.Target
	
	if self.BitsWritten > 0 then data = data .. string_char(self.Byte) end
	
	local bytes = {string_byte(data, 1, #data)}
	
	MsgC(color_white, "dump\n")
	
	for index, byte in ipairs(bytes) do
		for shift = 7, 0, -1 do
			local char = bit_rshift(byte, shift) % 2 == 1 and one_byte or zero_byte
			MsgC(color_white, char == one_byte and "1" or "0")
			table_insert(dump, char)
		end
		
		MsgC(color_white, " ")
		table_insert(dump, 32)
	end
	
	MsgC(color_white, " done\n")
	file.CreateDir(target)
	
	if zeros then file.Write(target .. self.Name .. ".dmp.dat", string_char(unpack(dump)))
	else file.Write(target .. self.Name .. ".dmp.dat", data) end
end

function stream_meta:NetRead()
	local length = net_ReadUInt(16) + 1
	local received_length = (self.ReceivedLength or 0) + length
	
	if received_length > maximum_stream_size then
		if self.Oversized then return end
		
		self.Data = ""
		self.Oversized = true
		
		return
	end
	
	self.Data = self.Data .. net_ReadData(length)
	self.ReceivedLength = received_length
	
	return net_ReadBool()
end

function stream_meta:NetWrite(length)
	local bytes_sent = self.BytesSent
	local segment = string_sub(self.Data, bytes_sent + 1)
	local segment_length = #segment
	
	if self.EnumerateClass and false then --TODO: remove this debug false
		net_WriteBool(true)
		PYRITION:NetWriteEnumeratedString("stream", self, self.Class, self.Player)
	else
		--print("writing that stream class", self, self.Class, self.Player)
		
		net_WriteBool(false)
		net_WriteString(self.Class)
	end
	
	net_WriteUInt(self.UID - 1, 32)
	
	--are we done writing all this?
	if length >= segment_length then
		if self:WriteFooter() then
			segment = string_sub(self.Data, bytes_sent + 1)
			segment_length = #segment
		end
		
		net_WriteUInt(segment_length - 1, 16)
		net_WriteData(segment, segment_length)
		net_WriteBool(true)
		
		self.NetSendFinished = true
		
		self:SendFinished()
		
		return true, segment_length
	end
	
	local write_length = math_min(length, segment_length)
	
	net_WriteUInt(write_length - 1, 16)
	net_WriteData(segment, write_length)
	net_WriteBool(false)
	
	self.BytesSent = bytes_sent + write_length
	
	return false, write_length
end

function stream_meta:Read(_ply) end

function stream_meta:ReadAlign() --adjusts the read pointer to the next byte
	if self.PointerBit == 0 then return end
	
	self.Pointer = self.Pointer + 1
	self.PointerBit = 0
end

function stream_meta:ReadAngle() return Angle(self:ReadFloat(), self:ReadFloat(), self:ReadFloat()) end

function stream_meta:ReadBit()
	local read_bit = self.PointerBit
	
	if read_bit == 7 then
		local read_byte = self.Pointer
		
		self.Pointer = read_byte + 1
		self.PointerBit = 0
		
		return byte_safe(self.Data, read_byte) % 2
	else
		self.PointerBit = read_bit + 1
		
		return bit_rshift(byte_safe(self.Data, self.Pointer), 7 - read_bit) % 2
	end
end

function stream_meta:ReadBits(bits) --for reading less than a byte
	local bit_pointer = self.PointerBit
	local byte_pointer = self.Pointer
	local new_bits = bit_pointer + bits
	local remaining_bits = 8 - bit_pointer
	
	if new_bits > 8 then
		local current_byte, next_byte = string_byte(self.Data, byte_pointer, byte_pointer + 1)
		local next_bits = bits - remaining_bits
		
		self.Pointer = byte_pointer + 1
		self.PointerBit = next_bits
		
		return bit_lshift(bit_band(current_byte, get_right_mask(remaining_bits)), next_bits) + bit_rshift(bit_band(next_byte or 0, get_left_mask(next_bits)), 8 - next_bits)
	end
	
	if new_bits == 8 then
		self.Pointer = byte_pointer + 1
		self.PointerBit = 0
	else self.PointerBit = new_bits end
	
	return bit_rshift(bit_band(byte_safe(self.Data, byte_pointer), get_right_mask(remaining_bits)), remaining_bits - bits)
end

function stream_meta:ReadBool() return self:ReadBit() == 1 end
function stream_meta:ReadBoolNot() return self:ReadBit() == 0 end --because "repeat ... until not ReadBool" is done a lot, this eliminates an op

function stream_meta:ReadByte()
	local bit_pointer = self.PointerBit
	local byte_pointer = self.Pointer
	
	self.Pointer = byte_pointer + 1
	
	if bit_pointer == 0 then return byte_safe(self.Data, byte_pointer)
	else
		local data = self.Data
		local byte, next_byte = bytes_safe(data, byte_pointer, byte_pointer + 1)
		
		return wordless(bit_lshift(byte, bit_pointer)) + bit_rshift(next_byte, 8 - bit_pointer)
	end
end

function stream_meta:ReadCharacter() return string_char(self:ReadByte()) end
function stream_meta:ReadClient() return Entity(self:ReadUInt(max_clients_bits) + 1) end

function stream_meta:ReadEnumeratedString(namespace, ply)
	return read_enumerated_string(
		namespace,
		ply or self.Player,
		self:ReadBool() and self:ReadString(),
		self:ReadUInt(net_enumeration_bits[namespace]) + 1
	)
end

function stream_meta:ReadFloat() return read_float(self:ReadULong()) end

function stream_meta:ReadInt(bits)
	if self:ReadBool() then return -self:ReadUInt(bits) end
	
	return self:ReadUInt(bits)
end

function stream_meta:ReadList(bits, method, ...)
	local items = {}
	
	for index = 0, self:ReadUInt(bits) do table_insert(items, method(self, ...)) end
	
	return items
end

function stream_meta:ReadLong()
	if self:ReadBool() then return -self:ReadULong() end
	
	return self:ReadULong()
end

function stream_meta:ReadMaybe(method, ...) if self:ReadBool() then return method(self, ...) end end
function stream_meta:ReadNullableTerminatedList(method, ...) return self:ReadBool() and self:ReadTerminatedList(method, ...) or {} end
function stream_meta:ReadPlayer() return Entity(self:ReadUInt(max_players_bits)) end

function stream_meta:ReadShort()
	if self:ReadBool() then return -self:ReadUShort() end
	
	return self:ReadUShort()
end

function stream_meta:ReadSignedByte()
	if self:ReadBool() then return -self:ReadByte() end
	
	return self:ReadByte()
end

function stream_meta:ReadString() return self:ReadStringRaw(self:ReadUShort()) end

function stream_meta:ReadStringRaw(length)
	local bytes_to_read = length
	local output = ""
	
	repeat
		local segment_length = math_min(bytes_to_read, 8000)
		bytes_to_read = bytes_to_read - segment_length
		output = output .. self:ReadStringRawInternal(segment_length)
	until bytes_to_read <= 0
end

function stream_meta:ReadStringRawInternal(length)
	local read_bit = self.PointerBit
	local read_byte = self.Pointer
	local read_target = read_byte + length
	
	self.Pointer = read_target
	
	if read_bit == 0 then return string_sub(self.Data, read_byte, read_target - 1)
	else
		local data = self.Data
		local bytes = {bytes_safe(data, read_byte, math_min(read_target, read_byte + char_offset))}
		local characters = {}
		
		--for oversized strings
		for index = char_start, length, char_limit do table_Add(bytes, {bytes_safe(data, index, index + 1)}) end
		
		for index = 1, length do
			table_insert(
				characters,
				wordless(bit_lshift(bytes[index], read_bit)) + bit_rshift(bytes[index + 1], 8 - read_bit)
			)
		end
		
		return string_char(unpack(characters))
	end
end

function stream_meta:ReadTerminatedList(method, ...)
	local items = {}
	
	repeat table_insert(items, method(self, ...))
	until self:ReadBoolNot()
	
	return items
end

function stream_meta:ReadTerminatedString()
	local byte
	local characters = {}
	
	repeat
		byte = self:ReadByte()
		
		table_insert(characters, byte)
	until byte == 0
	
	table_remove(characters)
	
	local rete = string_char(unpack(characters))
	
	return rete
end

function stream_meta:ReadUInt(bits)
	local bits_modulo = bits % 8
	local integer = 0
	
	for shift = bits, 8, -8 do
		local byte = self:ReadByte()
		
		integer = integer + bit_lshift(byte, shift - 8)
	end
	
	if bits_modulo == 0 then return integer end
	
	return integer + self:ReadBits(bits_modulo)
end

function stream_meta:ReadULong()
	local first, second, third, fourth
	local read_bit = self.PointerBit
	local read_byte = self.Pointer
	
	self.Pointer = read_byte + 4
	
	if read_bit == 0 then first, second, third, fourth = bytes_safe(self.Data, read_byte, read_byte + 3)
	else
		local alpha, bravo, charlie, delta, echo = bytes_safe(self.Data, read_byte, read_byte + 4)
		local remaining_bits = 8 - read_bit
		
		first = wordless(bit_lshift(alpha, read_bit)) + bit_rshift(bravo, remaining_bits)
		second = wordless(bit_lshift(bravo, read_bit)) + bit_rshift(charlie, remaining_bits)
		third = wordless(bit_lshift(charlie, read_bit)) + bit_rshift(delta, remaining_bits)
		fourth = wordless(bit_lshift(delta, read_bit)) + bit_rshift(echo, remaining_bits)
	end
	
	return bit_lshift(first, 24) + bit_lshift(second, 16) + bit_lshift(third, 8) + fourth
end

function stream_meta:ReadUShort()
	local first, second
	local read_bit = self.PointerBit
	local read_byte = self.Pointer
	
	self.Pointer = read_byte + 2
	
	if read_bit == 0 then first, second = string_byte(self.Data, read_byte, read_byte + 1)
	else
		local alpha, bravo, charlie = string_byte(self.Data, read_byte, read_byte + 2)
		local remaining_bits = 8 - read_bit
		
		first = wordless(bit_lshift(alpha, read_bit)) + bit_rshift(bravo, remaining_bits)
		second = wordless(bit_lshift(bravo, read_bit)) + bit_rshift(charlie, remaining_bits)
	end
	
	return second and bit_lshift(first, 8) + second or 0
end

function stream_meta:ReadVector() return Vector(self:ReadFloat(), self:ReadFloat(), self:ReadFloat()) end
function stream_meta:Size() return #self.Data * 8 + self.BitsWritten end
function stream_meta:Send() PYRITION:NetStreamSend(self) end
function stream_meta:SendFinished() end

function stream_meta:WriteAngle(angle)
	self:WriteFloat(angle.p)
	self:WriteFloat(angle.y)
	self:WriteFloat(angle.r)
end

function stream_meta:WriteBit(digit)
	local bits_written = self.BitsWritten
	
	if bits_written == 7 then
		self.Data = self.Data .. string_char(self.Byte + digit)
		
		--reset
		self.BitsWritten = 0
		self.Byte = 0
	else
		local binary = bit_lshift(digit, 7 - bits_written)
		
		self.BitsWritten = bits_written + 1
		self.Byte = self.Byte + binary
	end
end

function stream_meta:WriteBool(boolean) self:WriteBit(boolean and 1 or 0) end

function stream_meta:WriteByte(byte)
	local bits_written = self.BitsWritten
	
	if bits_written == 0 then
		self.Data = self.Data .. string_char(byte)
		
		return
	end
	
	self.Data = self.Data .. string_char(self.Byte + bit_rshift(byte, bits_written))
	
	--putting this comment here so I don't sort this operation, because if I do, it will break everything
	self.Byte = wordless(bit_lshift(byte, 8 - bits_written))
end

function stream_meta:WriteCharacter(character) self:WriteByte(string_byte(character)) end
function stream_meta:WriteClient(ply) self:WriteUInt(ply:EntIndex() - 1, max_clients_bits) end

function stream_meta:WriteEndBits() --write 0 for the remaining bits, completing the current byte
	if self.BitsWritten == 0 then return end
	
	self.Data = self.Data .. string_char(self.Byte)
	
	self.BitsWritten = 0
	self.Byte = 0
	
	return true
end

function stream_meta:WriteEnumeratedString(namespace, text, recipients)
	local send_raw, text, enumeration, enumeration_bits = write_enumerated_string(namespace, text, recipients or self.Player)
	
	if send_raw then
		self:WriteBool(true)
		self:WriteString(text)
		
		--the client can't write the enumeration if they're sending raw
		--because if they're sending raw it means we don't know it
		if CLIENT then return end
	else self:WriteBool(false) end
	
	self:WriteUInt(enumeration - 1, enumeration_bits)
end

function stream_meta:WriteFloat(float) self:WriteULong(write_float(float)) end

function stream_meta:WriteInt(integer, bits) --maximum effort
	self:WriteBool(integer < 0)
	self:WriteUInt(math.abs(integer), bits)
end

function stream_meta:WriteList(items, bits, method, ...)
	if not istable(items) then items = {items} end
	
	self:WriteUInt(#items - 1, bits)
	
	for index, item in ipairs(items) do method(self, item, ...) end
end

function stream_meta:WriteLong(long)
	self:WriteBool(long < 0)
	self:WriteULong(math.abs(long))
end

function stream_meta:WriteMaybe(method, value, ...)
	if value == nil then return self:WriteBool(false) end
	
	self:WriteBool(true)
	
	return method(self, value, ...)
end

function stream_meta:WriteNullableTerminatedList(items, ...)
	if table.IsEmpty(items) then return self:WriteBool(false) end
	
	self:WriteBool(true)
	self:WriteTerminatedList(items, ...)
end

function stream_meta:WritePlayer(ply) self:WriteUInt(ply:EntIndex(), max_players_bits) end

function stream_meta:WriteShort(short)
	self:WriteBool(short < 0)
	self:WriteUShort(math.abs(short))
end

function stream_meta:WriteSignedByte(byte)
	self:WriteBool(byte < 0)
	self:WriteByte(math.abs(byte))
end

function stream_meta:WriteString(text)
	self:WriteUShort(#text)
	self:WriteStringRaw(text)
end

function stream_meta:WriteStringRaw(text)
	local text_count = #text
	
	if self.BitsWritten == 0 then self.Data = self.Data .. text
	elseif text_count == 1 then self:WriteCharacter(text)
	else
		local bits_written = self.BitsWritten
		local bits_remaining = 8 - bits_written
		local previous_byte = string_byte(text)
		
		local bytes = {self.Byte + bit_rshift(previous_byte, bits_written)}
		
		for start = 2, text_count, char_limit do
			for _, byte in ipairs{string_byte(text, start, start + char_limit)} do
				table_insert(bytes, wordless(bit_lshift(previous_byte, bits_remaining)) + bit_rshift(byte, bits_written))
				
				previous_byte = byte
			end
		end
		
		self.Byte = wordless(bit_lshift(previous_byte, bits_remaining))
		self.Data = self.Data .. string_char(unpack(bytes))
	end
end

function stream_meta:WriteTerminatedList(items, method, ...)
	local passed = false
	
	for index, item in ipairs(items) do
		if passed then self:WriteBool(true)
		else passed = true end
		
		method(self, item, ...)
	end
	
	self:WriteBool(false)
end

function stream_meta:WriteTerminatedString(text)
	self:WriteStringRaw(text)
	self:WriteByte(0)
end

function stream_meta:WriteUInt(integer, bits)
	local bits_written = self.BitsWritten
	
	if bits_written == 0 then write_bits(self, {}, integer, bits)
	else
		local bits_empty = 8 - bits_written
		--110_____
		--bits			9
		--bits_written	3
		--bits_empty	5
		--bits_after	4
		if bits == bits_empty then
			self.Data = self.Data .. string_char(self.Byte + integer)
			
			self.BitsWritten = 0
			self.Byte = 0
		elseif bits < bits_empty then
			self.BitsWritten = bits_written + bits
			self.Byte = self.Byte + bit_lshift(integer, bits_empty - bits)
		else
			local bits_after = bits - bits_empty
			
			local characters = {self.Byte + bit_rshift(integer, bits_after)}
			
			self.BitsWritten = 0
			self.Byte = 0
			
			write_bits(
				self,
				characters,
				bit_band(integer, 2 ^ bits - 1),
				bits_after
			)
		end
	end 
end

function stream_meta:WriteULong(long)
	local bits_written = self.BitsWritten
	
	if bits_written == 0 then
		self.Data = self.Data .. string_char(
			bit_rshift(long, 24),
			wordless(bit_rshift(long, 16)),
			wordless(bit_rshift(long, 8)),
			wordless(long)
		)
	else
		self.Data = self.Data .. string_char(
			self.Byte + bit_rshift(long, 24 + bits_written),
			wordless(bit_rshift(long, 16 + bits_written)),
			wordless(bit_rshift(long, 8 + bits_written)),
			wordless(bit_rshift(long, bits_written))
		)
		
		self.Byte = wordless(bit_lshift(long, 8 - bits_written))
	end
end

function stream_meta:WriteUShort(short)
	local bits_written = self.BitsWritten
	
	if bits_written == 0 then
		self.Data = self.Data .. string_char(
			bit_rshift(short, 8),
			wordless(short)
		)
	else
		self.Data = self.Data .. string_char(
			self.Byte + bit_rshift(short, 8 + bits_written),
			wordless(bit_rshift(short, bits_written))
		)
		
		self.Byte = wordless(bit_lshift(short, 8 - bits_written))
	end
end

function stream_meta:WriteVector(vector)
	self:WriteFloat(vector.x)
	self:WriteFloat(vector.y)
	self:WriteFloat(vector.z)
end

stream_meta.ReadDouble = stream_meta.ReadFloat
stream_meta.ReadEndBits = stream_meta.ReadAlign
stream_meta.WriteDouble = stream_meta.WriteFloat --this is our little secret
stream_meta.WriteFooter = stream_meta.WriteEndBits

--pyrition functions
function PYRITION:NetStreamBenchmark()
	local max_tries = 5
	local samples = 10000
	
	local string_minimum = 10
	local string_maximum = 10
	
	MsgC(color_white, "\n\nbeginning benchmark with ", Color(0, 0, 255), max_tries .. "x " .. samples, color_white, " samples\n\n")
	
	for index, parameters in ipairs{
		{"WriteAngle", samples, max_tries, 1, function() return Angle(math.Rand(-math_huge, math_huge), math.Rand(-math_huge, math_huge), math.Rand(-math_huge, math_huge)) end},
		{"WriteBit", samples, max_tries, 1, function() return math.random(0, 1) end},
		{"WriteBool", samples, max_tries, 1, function() return math.random(0, 1) == 1 end},
		{"WriteByte", samples, max_tries, 1, function() return math.random(0, 0xFF) end},
		{"WriteDouble", samples, max_tries, 1, function() return math.Rand(-math_huge, math_huge) end},
		{"WriteFloat", samples, max_tries, 1, function() return math.Rand(-math_huge, math_huge) end},
		
		{
			"WriteInt", samples, max_tries, 1, function()
				local bits = math.random(8, 32)
				
				return math.random(0, 2 ^ bits - 1), bits
			end
		},
		
		{"WriteLong", samples, max_tries, 1, function() return math.random(0, long_mask) end},
		{"WriteShort", samples, max_tries, 1, function() return math.random(0, short_mask) end},
		{"WriteSignedByte", samples, max_tries, 1, function() return math.random(0, 0xFF) end},
		{"WriteString", samples, max_tries, 1, function() return random_string(string_minimum, string_maximum) end},
		{"WriteTerminatedString", samples, max_tries, 1, function() return random_string(string_minimum, string_maximum) end},
		
		{
			"WriteUInt", samples, max_tries, 1, function()
				local bits = math.random(8, 32)
				
				return math.random(0, 2 ^ bits - 1), bits
			end
		},
		
		{"WriteULong", samples, max_tries, 1, function() return math.random(0, long_mask) end},
		{"WriteUShort", samples, max_tries, 1, function() return math.random(0, short_mask) end},
		{"WriteVector", samples, max_tries, 1, function() return Vector(math.Rand(-math_huge, math_huge), math.Rand(-math_huge, math_huge), math.Rand(-math_huge, math_huge)) end},
	} do benchmark(unpack(parameters)) end
	
	MsgC(color_white, "\nbenchmark complete\n")
end

function PYRITION:NetStreamBuildOrder(stream_queue) --returns an ordered list of sync models by priorities
	local priorities = {} --list = priority
	local priority_layers = {} --table[priority] = list = stream
	
	for index, stream in ipairs(stream_queue) do
		local priority = stream.Priority
		local priority_layer = priority_layers[priority]
		
		stream.StreamQueueIndex = index
		
		if priority_layer then table_insert(priority_layer, stream)
		else
			table.insert(priorities, priority)
			
			priority_layers[priority] = {stream}
		end
	end
	
	return descending_sort(priorities), priority_layers
end

function PYRITION:NetStreamCreate(class, ply)
	local target = "pyrition/net_stream/uplink/"
	
	if SERVER then
		if not ply or ply:IsWorld() then target = "pyrition/net_stream/debug/"
		else target = "pyrition/net_stream/" .. ply:UserID() .. "/" end
	end
	
	local stream = setmetatable({
		Data = "",
		Name = string.Replace(tostring(SysTime()), ".", "_"),
		Player = SERVER and ply or game.GetWorld,
		Target = target
	}, stream_public)
	
	if class then stream.Class = class end
	
	return stream
end

function PYRITION:NetStreamIncoming(class, uid, ply)
	local realm = stream_classes[class]
	
	if realm then
		local active_streams_classed
		
		--setup missing active streams table
		if ply then
			local player_streams = active_streams[ply]
				
			if player_streams then
				active_streams_classed = player_streams[class]
				
				if not active_streams_classed then
					active_streams_classed = {}
					player_streams[class] = active_streams_classed
				end
			else
				active_streams_classed = {}
				active_streams[ply] = {[class] = active_streams_classed}
			end
		else
			active_streams_classed = active_streams[class]
			
			if not active_streams_classed then
				active_streams_classed = {}
				active_streams[class] = active_streams_classed
			end
		end
		
		local stream = active_streams_classed[uid]
		
		if not stream then
			stream = self:NetStreamCreate(class, ply)
			stream.Incoming = true
			stream.UID = uid
			active_streams_classed[uid] = stream
			
			if self.NetStreamModelMethods[class] then self:NetStreamModel(stream) end
		end
		
		if stream:NetRead() then
			active_streams_classed[uid] = nil
			
			return stream
		end
		
		return false
	else
		if CLIENT then
			if realm == nil then ErrorNoHalt("ID10T-16.1: Received stream with unregistered class '" .. tostring(class) .. "'")
			else ErrorNoHalt("ID10T-16.2: Received class '" .. tostring(class) .. "' stream in the wrong realm.") end
		end
		
		--read the data anyways so following streams are not butchered
		net_ReadData(net_ReadUInt(16) + 1)
		net_ReadBool()
	end
end

function PYRITION:NetStreamSend(stream)
	stream.BytesSent = 0
	stream.Sending = true
	stream.UID = get_uid(stream.Class)
	
	local stream_queue = stream_send_queue
	
	if SERVER then
		local ply = stream.Player
		stream_queue = stream_queue[ply]
		
		if not stream_queue then
			stream_send_queue[ply] = {stream}
			
			return
		end
	end
	
	table.insert(stream_queue, stream)
end

function PYRITION:NetStreamWrite(stream_queue)
	local bytes_sent = 0
	local completed = {}
	local passed = false
	local priorities, priority_layers = self:NetStreamBuildOrder(stream_queue)
	
	for index, priority in ipairs(priorities) do
		local priority_layer = priority_layers[priority]
		local reserved = math_floor(maximum_bytes_sent / math_min(#priority_layer, maximum_layer_size))
		
		for layer_index, stream in ipairs(priority_layer) do
			if passed then net_WriteBool(true)
			else passed = true end
			
			local complete, written = stream:NetWrite(reserved - 16)
			
			bytes_sent = bytes_sent + written
			
			--we will need to remove them in a specific order to prevent skipping
			if complete then table_insert(completed, stream.StreamQueueIndex) end
		end
	end
	
	if next(completed) then
		--clean up the table in reverse so we don't skip indices
		for index, stream_index in ipairs(descending_sort(completed)) do table_remove(stream_queue, stream_index) end
	end
	
	net_WriteBool(false)
end

--pyrition hooks
function PYRITION:PyritionNetStreamRegisterClass(class, realm, _enumerated) stream_classes[class] = realm end

--cvars
cvars.AddChangeCallback("pyrition_net_stream_bytes", function(_name, _old, _new)
	local new = pyrition_net_stream_bytes:GetInt()
	
	if block_convar(pyrition_net_stream_bytes, maximum_bytes_sent, new) then return end
	
	maximum_bytes_sent = new
end, "PyritionNetStream")

cvars.AddChangeCallback("pyrition_net_stream_channels", function(_name, _old, _new)
	local new = pyrition_net_stream_channels:GetInt()
	
	if block_convar(pyrition_net_stream_channels, maximum_layer_size, new) then return end
	
	maximum_layer_size = new
end, "PyritionNetStream")

cvars.AddChangeCallback("pyrition_net_stream_size", function(_name, _old, _new)
	local new = pyrition_net_stream_size:GetInt() * 1024
	
	if block_convar(pyrition_net_stream_size, maximum_stream_size, new) then return end
	
	maximum_stream_size = new
end, "PyritionNetStream")

--hook
hook.Add("Think", "PyritionNetStream", function() if next(stream_send_queue) then PYRITION:NetStreamThink() end end)

--net
net.Receive("pyrition_stream", function(_length, ply)
	local streams_completed = {}
	
	repeat
		local stream = PYRITION:NetStreamIncoming(
			net_ReadBool() and PYRITION:NetReadEnumeratedString("stream", ply) or net_ReadString(),
			net_ReadUInt(32) + 1,
			ply
		)
		
		if stream then table_insert(streams_completed, stream) end
	until not net_ReadBool()
	
	for index, stream in ipairs(streams_completed) do
		if stream.OnComplete then stream:OnComplete(ply) end
		
		stream:Read(ply)
	end
end)

--post
PYRITION:GlobalHookCreate("NetStreamRegisterClass")

--debug
if false then
	local banned = {
		ReadBit = true,
		ReadByte = true,
		ReadMaybe = true,
		ReadStringRaw = true,
		WriteBit = true,
		WriteByte = true,
		WriteMaybe = true,
		WriteStringRaw = true,
	}
	
	for key, method in pairs(stream_meta) do
		if banned[key] then drint(drint_level, " ignoring", key)
		elseif isfunction(method) and (string.StartWith(key, "Write") or string.StartWith(key, "Read")) then
			local original = stream_meta[key]
			
			drint(drint_level, "debugging", key)
			stream_meta[key] = function(self, ...)
				local returns = {original(self, ...)}
				
				drint(drint_level, key, ...)
				drint(drint_level, "returns", unpack(returns))
				drint(drint_level, "")
				
				return unpack(returns)
			end
		end
	end
end