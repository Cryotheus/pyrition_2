--locals
local recipient_iterable = PYRITION._RecipientIterable
local stream_models = PYRITION.NetStreamModels or {} --table[stream] = ply (on server) or false
local stream_models_active = PYRITION.NetStreamModelsActive or {}

--local tables
local model_meta = {
	IsPyritionStreamModel = true,
	ModelCompleted = false
}

--globals
PYRITION.NetStreamModels = stream_models
PYRITION.NetStreamModelsActive = stream_models_active

--meta functions
function model_meta:Call(...) return self:Write(self.Player, ...) end

function model_meta:Complete()
	local prevent_write = self.PreventWrite
	local targets = {}
	
	self.Completed = true
	
	self:WriteFooter()
	
	--create a list of methods to remove
	for key, value in pairs(self) do if isfunction(value) and string.StartWith(key, "Write") then table.insert(targets, key) end end
	
	--then replace those functions with a function that spits out an error
	for index, key in ipairs(targets) do self[key] = prevent_write end
	
	--it's ok call WriteFooter
	function self:WriteFooter() return false end
	
	--finally, if we're not already sending the model, send it!
	if self.Sending then return end
	
	self:Send()
end

function model_meta:Initialize() end
function model_meta:InitialSync(ply) return false end
function model_meta:PreventWrite() ErrorNoHaltWithStack("ID10T-15: Attempt to call a write method after stream model has been marked complete.") end
function model_meta:Read(ply) ErrorNoHaltWithStack("ID10T-17.1: Stream model '" .. tostring(self) .. "' is missing a Read method.") end
function model_meta:Write(ply) ErrorNoHaltWithStack("ID10T-17.2: Stream model '" .. tostring(self) .. "' is missing a Write method.") end

--pyrition functions
function PYRITION:NetStreamModel(stream)
	if stream.IsPyritionStreamModel then return stream end
	
	local class = stream.Class
	local model_methods = stream_models[class]
	
	assert(model_methods, "ID10T-18.2: Attempt to convert stream model with non-existant class '" .. tostring(class) .. "'")
	table.Merge(stream, model_meta)
	table.Merge(stream, model_methods)
	
	stream:Initialize()
	
	return stream
end

function PYRITION:NetStreamModelAdd(class, target)
	if SERVER and target and not IsEntity(target) then
		local targets = recipient_iterable(target)
		
		if targets then
			for index, target in ipairs(targets) do self:NetStreamModelAdd(target) end
			
			return
		end
	end
	
	self:NetStreamModelCreate(class, CLIENT and game.GetWorld() or target)
end

function PYRITION:NetStreamModelGet(class, ply)
	--get a model, or create it if it doesn't exist
	return self:NetStreamModelGetExisting(class, ply) or self:NetStreamModelCreate(class, ply)
end

function PYRITION:NetStreamModelGetExisting(class, ply)
	--get an existing model or false if no writable models exist
	local models = self:NetStreamModelsGet(class, ply)

	if models then return select(2, next(models)) end

	return false
end

function PYRITION:NetStreamModelsGet(class, ply)
	--get a list of writable models
	local models = {}
	local ply = SERVER and ply or false
	
	--find models that match the ply
	for stream, record in pairs(stream_models_active[class] or {}) do
		--models with Completed can't be written to, and for NetSendFinished it would be meaningless to write
		if record == ply and not (stream.Completed or stream.NetSendFinished) then table.insert(models, stream) end
	end
	
	return models[1] and models or false
end

function PYRITION:NetStreamModelCreate(class, ply)
	local stream = self:NetStreamCreate(class, ply)
	local model_methods = stream_models[class]
	local stream_models = stream_models_active[class]
	
	stream_models[stream] = SERVER and ply or false
	
	assert(model_methods, "ID10T-18.1: Attempt to create stream model with non-existant class '" .. tostring(class) .. "'")
	table.Merge(stream, model_meta)
	table.Merge(stream, model_methods)
	
	stream:Initialize()
	
	return stream
end

--pyrition hooks
function PYRITION:PyritionNetStreamModelRegister(class, realm, model, base_class)
	local base = base_class and stream_models[base_class]
	
	model.Class = class
	
	if base then
		local base_initialize = base.Initialize
		local model_initialize = model.Initialize
		
		--modifications to the table being registered
		model.BaseClass = base_class
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
	
	self:NetStreamRegisterClass(class, realm, model.EnumerateClass)
	
	stream_models[class] = model
	stream_models_active[class] = stream_models_active[class] or {}
	
	return model
end

--hooks
hook.Add("PyritionNetPlayerInitialized", "PyritionNetStreamModel", function(ply, emulated)
	--create all models that need to be synced when a player first connects
	for class, model_table in pairs(stream_models) do
		if model_table.InitialSync and model_table:InitialSync(ply, emulated) then
			local model = PYRITION:NetStreamModelCreate(class, ply)
			
			model()
			
			if not model.Sending then model:Send() end
		end
	end
end)

--post
PYRITION:GlobalHookCreate("NetStreamModelRegister")