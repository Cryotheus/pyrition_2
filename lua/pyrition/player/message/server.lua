--locals
local blocks = {}
local replace_unsafe = PYRITION._StringReplaceUnsafe

--local functions
local function messaging_blocked(ply, target)
	local blocks = blocks[target]

	return blocks and blocks[ply]
end

local function messaging_disabled(ply) return ply:GetInfoNum("pyrition_messaging_enabled", 2) == 0 end

--pyrition functions
function PYRITION:PlayerMessage(ply, targets, message) --send a private message to another player
	if messaging_disabled(ply) then return false, "pyrition.player.message.disabled.self" end

	local start_count = #targets

	do --filter targets who don't have messaging enabled
		--remove indices in reverse so we don't skip entries
		for index = start_count, 1, -1 do if messaging_disabled(targets[index]) then table.remove(targets, index) end end

		--we can't use table.IsEmpty as this is a rich list and has the IsPlayerList field
		if not targets[1] then return false, start_count == 1 and "pyrition.player.message.disabled" or "pyrition.player.message.disabled.multiple" end
	end

	do --filter targets who blocked the sender
		local targets_count = #targets --yes, we have to recount

		for index = targets_count, 1, -1 do if messaging_blocked(ply, targets[index]) then table.remove(targets, index) end end

		if not targets[1] then
			if start_count ~= targets_count then return false, "pyrition.player.message.blocked_disabled"
			else return false, targets_count == 1 and "pyrition.player.message.blocked" or "pyrition.player.message.blocked.multiple" end
		end
	end

	message = replace_unsafe(message)

	if #targets == 1 then --recount, YET AGAIN
		local target = targets[1]

		self:LanguageQueue(
			target,
			"pyrition.player.message",
			{
				executor = ply,
				message = message,
				target = target
			}
		)

		return true, "pyrition.player.message", {message = message, target = target}
	end

	self:LanguageQueue(
		targets,
		"pyrition.player.message.multiple",
		{
			executor = ply,
			message = message,
			targets = targets
		}
	)

	return true, "pyrition.player.message.multiple", {message = message, targets = targets}
end