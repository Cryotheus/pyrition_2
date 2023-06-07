local model_methods = setmetatable({IsPyritionStreamModel = true}, {__index = PYRITION.NetStreamMethods})
local model_queue = PYRITION.NetStreamModelsQueued or {} --table[class] = rich list {Target, ... arguments}
local stream_model_classes = PYRITION.NetStreamModelClasses or {}
local stream_models = PYRITION.NetStreamModels or {} --table[class] = lite object
local stream_models_active = PYRITION.NetStreamModelsActive or {} --table[class][stream] = target

local model_class_meta = {
	__index = model_methods,
	__name = "PyritionStreamModel",

	__tostring = function(self)
		local uid = self.UID
		
		if uid then return "PyritionStreamModel [" .. self.Class .. ":" .. uid .. "]["  .. self:Size() ..  "][" .. self.Target .. self.Name .. "]" end
	
		return "PyritionStreamModel [" .. self.Class .. "]["  .. self:Size() ..  "][" .. self.Target .. self.Name .. "]"
	end
}

local function dequeue_model(model, ...)
	model(...)
	model:Complete()
end

debug.getregistry().PyritionStreamModel = model_class_meta
PYRITION._NetStreamDequeueModel = dequeue_model
PYRITION.NetStreamModelClasses = stream_model_classes
PYRITION.NetStreamModelMethods = model_methods
PYRITION.NetStreamModels = stream_models
PYRITION.NetStreamModelsActive = stream_models_active
PYRITION.NetStreamModelsQueued = model_queue

function model_methods:Complete()
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

function model_methods:Initialize() end
function model_methods:InitialSync(_ply) return false end
function model_methods:CleanUp() stream_models_active[self.Class][self] = nil end
function model_methods:OnComplete(_ply) self:CleanUp() end
function model_methods:PreventWrite() ErrorNoHaltWithStack("Attempt to call a write method after stream model has been marked complete.") end
function model_methods:Read(_ply) ErrorNoHaltWithStack("Stream model '" .. tostring(self) .. "' is missing a Read method.") end
function model_methods:SendFinished() self:CleanUp() end
function model_methods:Write(_ply) ErrorNoHaltWithStack("Stream model '" .. tostring(self) .. "' is missing a Write method.") end

function PYRITION:NetStreamModel(stream)
	if stream.IsPyritionStreamModel then return stream end

	local class = stream.Class
	local class_methods = stream_model_classes[class]

	assert(class_methods, "Attempt to convert stream model with non-existant class '" .. tostring(class) .. "'")
	setmetatable(stream, {__index = class_methods})

	stream:Initialize()

	return stream
end

function PYRITION:NetStreamModelCreate(class, ply)
	local stream = self:NetStreamCreate(class, ply)
	local class_methods = stream_model_classes[class]
	local stream_models = stream_models_active[class]

	--ply if we are the server
	stream_models[stream] = SERVER and ply or false

	assert(class_methods, "Attempt to create stream model with non-existant class '" .. tostring(class) .. "'")
	setmetatable(stream, {__index = class_methods})

	stream:Initialize()

	return stream
end

function PYRITION:NetStreamModelGet(class, ply) --get a model, or create it if it doesn't exist
	--please note the difference between Model and Models in NetStreamModelGet and NetStreamModelsGet
	return self:NetStreamModelGetExisting(class, ply) or self:NetStreamModelCreate(class, ply)
end

function PYRITION:NetStreamModelGetExisting(class, ply) --get an existing model or false if no writable models exist
	local models = self:NetStreamModelsGet(class, ply) --realm dependent

	if models then return select(2, next(models)) end

	return false
end

function PYRITION:HOOK_NetStreamModelRegister(class, realm, model)
	local enumerate = model.EnumerateClass
	model.Class = class

	self:NetStreamRegisterClass(class, realm, enumerate == nil or enumerate)

	stream_model_classes[class] = setmetatable(model, model_class_meta)
	stream_models_active[class] = stream_models_active[class] or {}

	return model
end

hook.Add("PyritionNetPlayerInitialized", "PyritionNetStreamModel", function(ply, emulated)
	--create all models that need to be synced when a player first connects
	for class, model_table in pairs(stream_model_classes) do
		if model_table.InitialSync and model_table:InitialSync(ply, emulated) then
			local model = PYRITION:NetStreamModelCreate(class, ply)
			model.IsInitialSync = true

			if model.WriteInitialSync then model:WriteInitialSync(ply)
			else model:Write(ply) end

			--print("init sync for model", model)

			--make sure the model is being sent
			if not model.Sending then model:Send() end
		end
	end
end)

PYRITION:GlobalHookCreate("NetStreamModelRegister")