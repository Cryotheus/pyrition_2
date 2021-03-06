--locals
local MODEL = {Priority = 10}

--stream model functions
function MODEL:Initialize() if SERVER then self:Send() end end

function MODEL:Read()
	while self:ReadBool() do
		local option = self:ReadEnumeratedString("language_options")
		local phrases
		local key = self:ReadString()
		
		if self:ReadBool() then
			phrases = {}
			
			repeat
				local tag = self:ReadTerminatedString()
				
				if self:ReadBool() then --list
					if self:ReadBool() then
						local players = {}
						phrases[tag] = players
						
						repeat table.insert(players, self:ReadPlayer())
						until self:ReadBoolNot()
					else
						local items = {}
						phrases[tag] = items
						
						repeat table.insert(items, self:ReadString())
						until self:ReadBoolNot()
					end
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
	self:WriteEnumeratedString("language_options", option)
	self:WriteString(key)
	
	if phrases then
		for tag, phrase in pairs(phrases) do
			self:WriteBool(true)
			self:WriteTerminatedString(tag)
			
			if istable(phrase) then --list of items
				self:WriteBool(true)
				
				if phrase.IsPlayerList then --players
					for index, ply in ipairs(phrase) do
						self:WriteBool(true)
						self:WritePlayer(ply)
					end
					
					self:WriteBool(false)
				else --strings
					local passed = false
					
					self:WriteBool(false)
					
					for index, text in ipairs(phrase) do
						if passed then self:WriteBool(true)
						else passed = true end
						
						self:WriteString(text)
					end
					
					self:WriteBool(false)
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
		
		self:WriteBool(false)
	else self:WriteBool(false) end
end

--post
PYRITION:NetStreamModelRegister("language", CLIENT, MODEL)