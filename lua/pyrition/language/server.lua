--pyrition functions
function PYRITION:LanguageQueue(ply, key, phrases, option)
	assert(not option or self.NetEnumeratedStrings.language_options[option], 'ID10T-4/S:  ')
	
	--having ply = true means to broadcast to everyone
	if ply == true then
		for index, ply in ipairs(player.GetHumans()) do self:LanguageQueue(ply, key, phrases, option) end
		
		return
	end
	
	local model
	local models = self:NetSyncGetModels(class, ply)
	
	if models then model = next(models)
	else model = self:NetSyncAdd("language", ply) end
	
	model:AddMessage(key, phrases, option)
end

function PYRITION:LanguageRegister(key) self:NetAddEnumeratedString("language", key) end
function PYRITION:LanguageTranslate(key, fallback, phrases) return self:LanguageFormatTranslated(fallback, phrases) end

--post
PYRITION:NetAddEnumeratedString("language")