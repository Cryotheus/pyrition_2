--locals
local MODEL = {Priority = 10}

--stream model functions
function MODEL:Initialize() if SERVER then self:Send() end end

function MODEL:Read()
	while self:ReadBool() do
		local option = self:ReadEnumeratedString("LanguageOptions")
		local phrases
		local key = self:ReadString()

		if self:ReadBool() then
			phrases = {}

			repeat
				local tag = self:ReadTerminatedString()

				if self:ReadBool() then --list
					if self:ReadBool() then phrases[tag] = self:ReadNullableTerminatedList(self.ReadPlayer)
					else phrases[tag] = self:ReadNullableTerminatedList(self.ReadString) end
				else --item
					if self:ReadBool() then phrases[tag] = self:ReadPlayer()
					else phrases[tag] = self:ReadString() end
				end
			until self:ReadBoolNot()
		end

		PYRITION:LanguageDisplay(option, key, phrases)
	end
end

function MODEL:Write(_ply, key, phrases, option)
	--flag that there is a message to read
	self:WriteBool(true)

	--write key and method of delivery
	self:WriteEnumeratedString("LanguageOptions", option)
	self:WriteString(key)

	if phrases then
		for tag, phrase in pairs(phrases) do
			self:WriteBool(true)
			self:WriteTerminatedString(tag)

			if istable(phrase) then --list of items
				self:WriteBool(true)

				if phrase.IsPlayerList then --players
					self:WriteBool(true)
					self:WriteNullableTerminatedList(phrase, self.WritePlayer)
				else --strings
					self:WriteBool(false)
					self:WriteNullableTerminatedList(phrase, self.WriteString)
				end
			else --single item, player or string
				self:WriteBool(false)

				if IsEntity(phrase) then
					self:WriteBool(true)
					self:WritePlayer(phrase)
				else
					self:WriteBool(false)
					self:WriteString(phrase)
				end
			end
		end

		return self:WriteBool(false)
	end

	self:WriteBool(false)
end

--post
PYRITION:NetStreamModelRegister("Language", CLIENT, MODEL)