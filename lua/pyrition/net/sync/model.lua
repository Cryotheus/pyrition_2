--locals
local sync_models = PYRITION.NetSyncModels or {}
local _R = debug.getregistry()

--local tables
local model_indexing = {
	CanWrite = function(self, march) return select(2, net.BytesWritten()) < self.MaximumBits end,
	EnumerateClass = true,
	FinishRead = function() end,
	FinishWrite = function() end,
	Initialize = function() return true end,
	IsPyritionSyncModel = true,
	MetaName = "PyritionSyncModel",
	Priority = 0,
	Read = function(self, ...) return false, self .. " is missing a Read method override. Please report this to the developer." end,
	Write = function(self, ply, ...) return true end,
}

local model_meta = {
	__index = model_indexing,
	__name = "PyritionSyncModel"
}

--local functions
local function is_pyrition_sync_model(object) return istable(object) and object.IsPyritionSyncModel or false end

--globals
_R.PyritionSyncModel = model_meta
PYRITION.NetSyncModels = sync_models
PYRITION._IsPyritionSyncModel = is_pyrition_sync_model

--model meta functions
--ply, ...
if SERVER then function model_meta:__call(...) return self:Write(...) end
else function model_meta:__call(...) return self:Read(...) end end

function model_meta:__concat(alpha)
	local flip
	
	if is_pyrition_sync_model(alpha) then self, alpha, flip = alpha, self, true end
	if isnumber(alpha) then alpha = tostring(alpha) end
	
	assert(isstring(alpha), "attempt to concatenate a PyritionSyncModel with a non-string (" .. type(is_pyrition_sync_model(self) and self or alpha) .. ") value")
	
	return flip and alpha .. tostring(self) or tostring(self) .. alpha
end

function model_meta:__tostring() return "PyritionSyncModel [" .. self.Class .. "]" end

--pyrition functions
function PYRITION:NetSyncModelCreate(class, ply)
	local model = sync_models[class]
	
	assert(model, "ID10T-6: Attempted to create non-existent sync model class " .. tostring(class))
	
	model = table.Copy(model)
	model.Player = ply
	
	--inherit all needed members
	table.Inherit(model, model_indexing)
	setmetatable(model, model_meta)
	
	model:Initialize()
	
	return model
end

--pyrition hooks
function PYRITION:PyritionNetSyncModelRegister(class, model, base_class)
	local base = base_class and sync_models[base_class]
	
	model.Class = class
	model.Parents = parents
	
	if base then
		local base_initialize = base.Initialize
		local model_initialize = model.Initialize
		
		--modifications to the table being registered
		model.BaseParents = base_parents
		model.BaseInitialize = base_initialize
		
		--merge initialize functions
		if base_initialize and model_initialize then
			model.InitializeX = model_initialize
			
			function model:Initialize(...)
				self:BaseInitialize(...)
				
				return self:InitializeX(...)
			end
		end
		
		--finally merge
		model = table.Merge(table.Copy(base), model)
	end
	
	if SERVER then
		local enumerate = model.EnumerateClass
		
		if enumerate ~= false then self:NetAddEnumeratedString("sync_model", class) end
	end
	
	sync_models[class] = model
	
	return model
end

--post
PYRITION:GlobalHookCreate("NetSyncModelRegister")