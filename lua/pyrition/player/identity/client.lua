local chat_filter = {
	chat = false, --(Obsolete?) Player chat? Seems to trigger when server console uses the say command
	joinleave = true, --Player join and leave messages
	namechange = false, --Player name change messages
	none = false, --fallback
	servermsg = false, --Server messages such as convar changes
	teamchange = false, --Team changes?
}

hook.Add("ChatText", "PyritionPlayerIdentity", function(_index, _name, _text, id)
	if chat_filter[id] then return true end
end)