--TODO: add this script to load order!
--locals
local MODEL = {IsLanguageSyncModel = true}

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
		
		if net.ReadBool() then
			phrases = {}
			
			repeat
				local tag = net.ReadString()
				
				if net.ReadBool() then --is this a list of strings?
					local is_player_list = net.ReadBool()
					local items = {}
					
					repeat table.insert(items, net.ReadString())
					until not net.ReadBool()
					
					if is_player_list then phrases[tag] = PYRITION:LanguageListPlayers(items)
					else phrases[tag] = PYRITION:LanguageList(items) end
				else
					local phrase = net.ReadString()
					
					--if prefixed with #, localize the string
					--if the # is wanted, a backslash can be used to escape like "\\#pyrition.commands.heal" weirdo
					if string.StartWith(phrase, "\\#") then print("drug escaped", phrase) phrases[tag] = string.sub(phrase, 2)
					elseif string.StartWith(phrase, "#") then print("drug localized", phrase) phrases[tag] = language.GetPhrase(string.sub(phrase, 2))
					else print("drug raw", phrase) phrases[tag] = phrase end
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
			
			if istable(phrase) then --write a list of strings that will replace a single tag
				local passed = false
				
				net.WriteBool(true)
				net.WriteBool(phrase.IsPlayerList or false)
				
				for index, item in ipairs(phrase) do
					if IsEntity(item) and item:IsPlayer() then item = item:Name() end
					
					if isstring(item) then
						if passed then net.WriteBool(true)
						else passed = true end
						
						net.WriteString(item)
					else ErrorNoHaltWithStack("ID10T-5: Attempt to write a non-string " .. type(item) .. " value.") end
				end
				
				net.WriteBool(false)
			else
				net.WriteBool(false)
				net.WriteString(tostring(phrase))
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