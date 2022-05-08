local sync_models = PYRITION.NetSyncModels or {}
local active_models = PYRITION.NetSyncActiveModels or {}

--globals
PYRITION.NetSyncActiveModels = active_models

--pyrition functions
function PYRITION:NetSyncGetModel(class, identifier)
	local models = active_models[class]
	
	if models then
		local model = models[identifier]
		
		if model then return model end
	else
		models = {}
		active_models[class] = models
	end
	
	local model = self:NetSyncModelCreate(class, LocalPlayer())
	
	model.Created = CurTime()
	model.Identifier = identifier
	models[identifier] = model
	
	return model
end

--hooks
hook.Add("PopulateToolMenu", "PyritionNetSync", function()
	spawnmenu.AddToolMenuOption("Utilities", "PyritionDevelopers", "NetModels", "Networking Models", "", "", function(form)
		local list_view
		
		form:ClearControls()
		
		do --refresh button
			local button = form:Button("Refresh")
			
			button:SetMaterial("icon16/arrow_refresh.png")
			button:SetText("Refresh")
			
			function button:DoClick() list_view:Refresh() end
		end
		
		do
			list_view = vgui.Create("DCategoryList", form)
			list_view.PerformLayoutX = list_view.PerformLayout
			
			list_view:Add("Class")
			list_view:Add("ID")
			list_view:SetHeight(512)
			
			function list_view:Refresh()
				local model_data = {}
				
				for name, models in pairs(PYRITION.NetSyncActiveModels) do
					for index, model in pairs(models) do
						table.insert(model_data, {model.Created or 0, model.Identifier, name})
					end
				end
				
				table.sort(model_data, function(alpha, bravo) return alpha[1] < bravo[1] end)
				
				for index, datum in ipairs(model_data) do self:AddLine(select(2, unpack(datum))) end
			end
			
			function list_view:PerformLayout(width, height)
				self:PerformLayoutX(width, height)
				
				--self:SizeToChildren(false, true)
			end
			
			list_view:Refresh()
			form:AddItem(list_view)
		end
	end)
end)

--net
net.Receive("pyrition_sync", function()
	repeat
		local class
		
		if net.ReadBool() then class = PYRITION:NetReadEnumeratedString("sync_model")
		else class = net.ReadString() end
		
		local debugging = DEBUG_PYRITION_NET
		local identifier = net.ReadUInt(32)
		
		DEBUG_PYRITION_NET = class == debug_class
		
		PYRITION:NetSyncGetModel(class, identifier)()
		
		DEBUG_PYRITION_NET = debugging
		
		local complete = net.ReadBool()
		
		if complete then active_models[class][identifier] = nil end
	until not net.ReadBool()
end)