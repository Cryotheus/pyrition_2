--locals
local model_queue = PYRITION.NetStreamModelsQueued or {} --table[class] = rich list {Target, ... arguments}
local stream_model_methods = PYRITION.NetStreamModelMethods or {}
local stream_models = PYRITION.NetStreamModels or {} --table[class] = lite object
local stream_models_active = PYRITION.NetStreamModelsActive or {} --table[class][stream] = target

--local tables
local model_meta = {
	IsPyritionStreamModel = true,
	ModelCompleted = false
}

--local functions
local function dequeue_model(model, ...)
	model(...)
	model:Complete()
end

--globals
PYRITION.NetStreamModelMerger = model_meta
PYRITION.NetStreamModelMethods = stream_model_methods
PYRITION.NetStreamModels = stream_models
PYRITION.NetStreamModelsActive = stream_models_active
PYRITION.NetStreamModelsQueued = model_queue
PYRITION.__DequeueModel = dequeue_model

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
function model_meta:InitialSync(_ply) return false end
function model_meta:CleanUp() stream_models_active[self.Class][self] = nil end
function model_meta:OnComplete(_ply) self:CleanUp() end
function model_meta:PreventWrite() ErrorNoHaltWithStack("Attempt to call a write method after stream model has been marked complete.") end
function model_meta:Read(_ply) ErrorNoHaltWithStack("Stream model '" .. tostring(self) .. "' is missing a Read method.") end
function model_meta:SendFinished() self:CleanUp() end
function model_meta:Write(_ply) ErrorNoHaltWithStack("Stream model '" .. tostring(self) .. "' is missing a Write method.") end

--pyrition functions
function PYRITION:NetStreamModel(stream)
	if stream.IsPyritionStreamModel then return stream end

	local class = stream.Class
	local model_methods = stream_model_methods[class]

	assert(model_methods, "Attempt to convert stream model with non-existant class '" .. tostring(class) .. "'")
	table.Merge(stream, model_meta)
	table.Merge(stream, model_methods)

	stream:Initialize()

	return stream
end

function PYRITION:NetStreamModelCreate(class, ply)
	local stream = self:NetStreamCreate(class, ply)
	local model_methods = stream_model_methods[class]
	local stream_models = stream_models_active[class]

	stream_models[stream] = SERVER and ply or false

	assert(model_methods, "Attempt to create stream model with non-existant class '" .. tostring(class) .. "'")
	table.Merge(stream, model_meta) --default methods
	table.Merge(stream, model_methods) --class custom methods

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

--pyrition hooks
function PYRITION:PyritionNetStreamModelRegister(class, realm, model, base_class)
	local base = base_class and stream_model_methods[base_class]
	local enumerate = model.EnumerateClass

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

	self:NetStreamRegisterClass(class, realm, enumerate == nil or enumerate)

	stream_model_methods[class] = model
	stream_models_active[class] = stream_models_active[class] or {}

	return model
end

--hooks
hook.Add("PyritionNetPlayerInitialized", "PyritionNetStreamModel", function(ply, emulated)
	--create all models that need to be synced when a player first connects
	for class, model_table in pairs(stream_model_methods) do
		if model_table.InitialSync and model_table:InitialSync(ply, emulated) then
			local model = PYRITION:NetStreamModelCreate(class, ply)
			model.IsInitialSync = true

			if model.WriteInitialSync then model:WriteInitialSync(ply)
			else model() end

			--print("init sync for model", model)

			--make sure the model is being sent
			if not model.Sending then model:Send() end
		end
	end
end)

--post
PYRITION:GlobalHookCreate("NetStreamModelRegister")