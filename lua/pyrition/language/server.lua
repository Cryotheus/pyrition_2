local color_broadcast = Color(255, 255, 0)
local color_silent = Color(0, 0, 255)
local log_filter = PYRITION.LanguageLogFilter or {}

--globals
PYRITION.LanguageLogFilter = log_filter

--pyrition functions
function PYRITION:LanguageDisplay(log, key, phrases, broadcast)
	if isstring(log) then log = log_filter[log] and true or false end
	
	--if prefixed with #, localize the string
	--if the # is wanted, a backslash can be used to escape like "\\#pyrition.commands.heal" weirdo
	if phrases then
		for tag, phrase in pairs(phrases) do
			if isstring(phrase) then
				if string.StartWith(phrase, "\\#") then phrases[tag] = string.sub(phrase, 2)
				elseif string.StartWith(phrase, "#") then phrases[tag] = language.GetPhrase(string.sub(phrase, 2))
				else phrases[tag] = phrase end
			end
		end
	end
	
	if log then ServerLog(language.GetPhrase("pyrition.language.log") .. self:LanguageFormat(key, phrases) .. "\n")
	else
		if broadcast then MsgC(color_broadcast, language.GetPhrase("pyrition.language.broadcast"))
		else MsgC(color_silent, language.GetPhrase("pyrition.language")) end
		
		MsgC(unpack(self:LanguageFormatColor(key, phrases)))
		MsgC("\n")
	end
end

function PYRITION:LanguageQueue(ply, key, phrases, option)
	assert(not option or self.NetEnumeratedStrings.language_options[option], "ID10T-4/S: Cannot queue language module message for non-existent option '" .. tostring(option) .. "'")
	
	--having ply = true means to broadcast to everyone
	if ply == true then
		for index, ply in ipairs(player.GetHumans()) do self:LanguageQueue(ply, key, phrases, option) end
		
		return self:LanguageDisplay(false, key, phrases, true)
	end
	
	if ply == nil or ply == game.GetWorld() then return self:LanguageDisplay(false, key, phrases) end
	
	local model
	local models = self:NetSyncGetModels(class, ply)
	
	if models then model = next(models)
	else model = self:NetSyncAdd("language", ply) end
	
	model:AddMessage(key, phrases, option)
end

function PYRITION:LanguageRegister(key) self:NetAddEnumeratedString("language", key) end
function PYRITION:LanguageRegisterLogFilter(key, enabled) log_filter[key] = enabled end

--post
PYRITION:NetAddEnumeratedString("language")