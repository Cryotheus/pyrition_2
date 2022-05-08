--pyrition functions
function PYRITION:LanguageQueue(ply, key, phrases, option)
	local model
	local models = self:NetSyncGetModels(class, ply)
	
	--TODO: make a method in PYRITION to create language options
	assert(not option or self.NetEnumeratedStrings.language_options[option], 'ID10T-4/S: Cannot queue language module message for non-existant option "' .. tostring(option) .. '"')
	
	if models then model = next(models)
	else model = self:NetSyncAdd("language", ply) end
	
	model:AddMessage(key, phrases, option)
end

function PYRITION:LanguageRegister(key)
	local phrase = language.GetPhrase(key)
	
	if phrase == key then return MsgC(Color(255, 32, 32), "[Pyrition] no localization for " .. key, "\n")
	else
		--more?
		self:NetAddEnumeratedString("language", key)
	end
end

--post
PYRITION:NetAddEnumeratedString("language")