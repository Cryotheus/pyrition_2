--locals
local bits = PYRITION._Bits
local drint = PYRITION._drint
local drint_level = 3
local jerry = 0.24027821356 --this is jerry, a very special number. do not worry about its origin, just keep moving.
local net_enumeration_bits = PYRITION.NetEnumerationBits --dictionary[namespace] = bits
local net_enumerations = PYRITION.NetEnumeratedStrings --dictionary[namespace] = fooplex[string]

--pyrition functions
function PYRITION:NetReadEnumeratedString(namespace)
	local enumerations = net_enumerations[namespace]
	local text
	
	assert(enumerations, 'ID10T-2/C: Attempt to read enumerated string using non-existent namespace "' .. tostring(namespace) .. '"')
	
	local debug_net = DEBUG_PYRITION_NET
	
	if debug_net then
		DEBUG_PYRITION_NET = false
		
		drint(drint_level, "reading estring " .. namespace)
	end
	
	if net.ReadBool() then text = net.ReadString(text) end
	
	local enumeration = net.ReadUInt(net_enumeration_bits[namespace]) + 1
	
	if text then
		enumerations[enumeration] = text
		enumerations[text] = enumeration
		
		if debug_net then
			DEBUG_PYRITION_NET = true
			
			drint(drint_level, "read " .. enumeration .. ":" .. text .. "\n")
		end
		
		return text
	end
	
	if debug_net then
		DEBUG_PYRITION_NET = true
		
		local enumeration = enumeration or -1
		local text = enumerations[enumeration] or "<invalid>"
		
		drint(drint_level, "read " .. enumeration .. ":" .. text .. "\n")
	end
	
	return enumerations[enumeration]
end

function PYRITION:NetWriteEnumeratedString(namespace, text)
	local enumerations = net_enumerations[namespace]
	
	assert(enumerations, 'ID10T-3/C: Attempt to write enumerated string using non-existent namespace "' .. namespace .. '"')
	
	local enumeration = enumerations[text]
	
	if enumeration then
		net.WriteBool(false)
		net.WriteUInt(enumeration - 1, net_enumeration_bits[namespace])
	else
		net.WriteBool(true)
		net.WriteString(text)
	end
end

--pyrition hooks
function PYRITION:PyritionNetClientInitialized(ply)
	--we use a timer because everyone else in the entire world also sends net messages here
	--this is jerry's sole purpose
	timer.Simple(jerry, function()
		net.Start("pyrition")
		net.SendToServer()
	end)
end

--console commands
concommand.Add("pd", function(ply, command, arguments, arguments_string)
	net.Start("pyrition")
	net.SendToServer()
end, nil, "Pyrition's debug command. If you are reading this and you're not on a test server, please report it.")

--hooks
--hook.Add("InitPostEntity", "PyritionNet", function() PYRITION:NetClientInitialized(LocalPlayer()) end)

hook.Add("PopulateToolMenu", "PyritionNet", function()
	spawnmenu.AddToolMenuOption("Utilities", "PyritionDevelopers", "NetEnumerations", "#pyrition.spawnmenu.categories.developer.net_enumerations", "", "", function(form)
		local category_list
		
		form:ClearControls()
		
		do --refresh button
			local button = form:Button("Refresh")
			
			button:SetMaterial("icon16/arrow_refresh.png")
			--button:SetText("Refresh")
			
			function button:DoClick() category_list:Refresh() end
		end
		
		do
			category_list = vgui.Create("DCategoryList", form)
			
			function category_list:PerformLayout(width, height)
				self:PerformLayoutInternal()
				self:SetTall(self:GetCanvas():GetTall())
			end
			
			function category_list:Refresh()
				self:Clear()
				
				local net_enumeration_bits = PYRITION.NetEnumerationBits
				
				for namespace, fooplex in pairs(PYRITION.NetEnumeratedStrings) do
					local bits = net_enumeration_bits[namespace]
					local bits_maximum = 2 ^ bits
					local category = self:Add(namespace .. " (" .. bits .. " 0d" .. bits_maximum .. ")")
					local indices = {}
					local maximum_index = 0
					
					category:DoExpansion(false)
					
					for index in pairs(fooplex) do
						if isnumber(index) then
							maximum_index = math.max(maximum_index, index)
							
							table.insert(indices, index)
						end
					end
					
					for index = 1, maximum_index do
						local text = fooplex[index]
						
						if text then category:Add("#" .. index .. " " .. text)
						else category:Add(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.developer.net_enumerations.unaccounted", {index = index})):SetEnabled(false) end
					end
					
					if maximum_index < bits_maximum then
						local difference = bits_maximum - maximum_index
						local warning = difference == 1 and category:Add("#pyrition.spawnmenu.categories.developer.net_enumerations.additional.singular") or category:Add(PYRITION:LanguageFormat("pyrition.spawnmenu.categories.developer.net_enumerations.additional", {difference = difference}))
						
						warning:SetEnabled(false)
						warning:SetTextColor(Color(192, 0, 0))
					end
				end
			end
			
			category_list:Refresh()
			form:AddItem(category_list)
			
			--category_list:Dock(FILL)
		end
	end)
end)

--net
net.Receive("pyrition", function(length, ply)
	--syncs the bits for enumerations
	repeat
		local namespace = net.ReadString()
		net_enumeration_bits[namespace] = net.ReadUInt(5) + 1
		
		if not net_enumerations[namespace] then net_enumerations[namespace] = {} end
	until not net.ReadBool()
end)

net.Receive("pyrition_teach", function()
	--this is received when the server is teaching us enumerations that we didnt use
	repeat
		local namespace = net.ReadString()
		local namespace_bits = net_enumeration_bits[namespace]
		
		assert(namespace_bits, 'Panic! Missing bit count for enumeration namespace "' .. namespace .. '"')
		
		local enumerations = net_enumerations[namespace]
		
		repeat
			local text = net.ReadString()
			local enumeration = net.ReadUInt(namespace_bits) + 1
			
			enumerations[enumeration] = text
			enumerations[text] = enumeration
		until not net.ReadBool()
	until not net.ReadBool()
end)