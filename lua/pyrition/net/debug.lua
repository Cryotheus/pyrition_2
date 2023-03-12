local drint = PYRITION._drint
local drint_level = 3
local originals = PYRITION.NetDebugOriginals or {}

--globals
PYRITION.NetDebugOriginals = originals

--post
if true then
	for key, value in pairs(net) do
		if isfunction(value) and key ~= "ReadBit" and (string.StartWith(key, "Read") or string.StartWith(key, "Write")) then
			local original = originals[key] or net[key]
			originals[key] = original
			
			net[key] = function(...)
				local returns = {original(...)}
				
				drint(drint_level, key, ...)
				
				if next(returns) then
					drint(drint_level, "returns", unpack(returns))
					drint(drint_level, "")
					
					return unpack(returns)
				end
				
				drint(drint_level, "")
			end
		end
	end
end

resource.AddSingleFile("resource/localization/en/pyrition.properties")
resource.AddSingleFile("resource/localization/de/pyrition.properties")