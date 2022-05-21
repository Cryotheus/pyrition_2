--TODO: add this script to load order!
--locals
local MODEL = {IsLanguageSyncModel = true}
local read_player = PYRITION._ReadPlayer
local write_player = PYRITION._WritePlayer

--sync model functions
function MODEL:AddMessage(key, phrases, option)
	table.insert(self.Keys, key)
	table.insert(self.Options, option or "chat")
	table.insert(self.Phrases, phrases or false)
end

function MODEL:Initialize() if SERVER then self.Keys, self.Options, self.Phrases = {}, {}, {} end end

function MODEL:Read()
	repeat
		local option = PYRITION:NetReadEnumeratedString("language_options")
		local key = net.ReadBool() and PYRITION:NetReadEnumeratedString("language") or net.ReadString()
		local phrases
		
		if net.ReadBool() then --we have text to use for substitution
			phrases = {}
			
			repeat
				local tag = net.ReadString()
				
				if net.ReadBool() then --read lists
					local items = {}
					local is_player_list = net.ReadBool()
					local read_function = is_player_list and read_player or net.ReadString
					
					repeat table.insert(items, read_function())
					until not net.ReadBool()
					
					if is_player_list then phrases[tag] = #items == 1 and items[1] or PYRITION:LanguageListPlayers(items)
					else phrases[tag] = PYRITION:LanguageList(items) end
				else --read players and strings
					if net.ReadBool() then phrases[tag] = read_player()
					else
						local phrase = net.ReadString()
						
						--if prefixed with #, localize the string
						--if the # is wanted, a backslash can be used to escape like "\\#pyrition.commands.heal" weirdo
						if string.StartWith(phrase, "\\#") then phrases[tag] = string.sub(phrase, 2)
						elseif string.StartWith(phrase, "#") then phrases[tag] = language.GetPhrase(string.sub(phrase, 2))
						else phrases[tag] = phrase end
					end
				end
			until not net.ReadBool()
		end
		
		PYRITION:LanguageDisplay(option, key, phrases)
	until not net.ReadBool()
end

function MODEL:Write(ply)
	local items = self.Keys
	local key = table.remove(items, 1)
	local phrases = table.remove(self.Phrases, 1)
	
	PYRITION:NetWriteEnumeratedString("language_options", table.remove(self.Options, 1), ply)
	
	if PYRITION:NetIsEnumerated("language", key) then --write the localization key or entire message
		net.WriteBool(true)
		PYRITION:NetWriteEnumeratedString("language", key, ply)
	else
		net.WriteBool(false)
		net.WriteString(key)
	end
	
	if phrases then --write phrases and tags
		for tag, phrase in pairs(phrases) do
			net.WriteBool(true)
			net.WriteString(tag)
			
			if istable(phrase) then --write a list that will replace a single tag
				local passed = false
				
				net.WriteBool(true)
				
				if phrase.IsPlayerList then
					net.WriteBool(true)
					
					for index, ply in ipairs(phrase) do
						if IsEntity(ply) then
							if passed then net.WriteBool(true)
							else passed = true end
							
							write_player(ply)
						else ErrorNoHaltWithStack("ID10T-11: Attempt to write a non-entity " .. type(ply) .. " value. Should be a player or the world entity.") end
					end
					
					if not passed then net.WriteEntity() end
				else
					net.WriteBool(false)
					
					for index, item in ipairs(phrase) do
						if isstring(item) then
							if passed then net.WriteBool(true)
							else passed = true end
							
							net.WriteString(item)
						else ErrorNoHaltWithStack("ID10T-5: Attempt to write a non-string " .. type(item) .. " value.") end
					end
				end
				
				net.WriteBool(false)
			else --write a player or string
				net.WriteBool(false)
				
				if IsEntity(phrase) then
					net.WriteBool(true)
					write_player(phrase)
				else
					net.WriteBool(false)
					net.WriteString(tostring(phrase))
				end
			end
		end
		
		net.WriteBool(false)
	else net.WriteBool(false) end
	
	if not items[1] then --done with this model, discard it
		net.WriteBool(false)
		
		return true
	end
	
	net.WriteBool(true)
end

--post
PYRITION:NetSyncModelRegister("language", MODEL)