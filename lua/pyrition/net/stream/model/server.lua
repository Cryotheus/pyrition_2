--locals
local dequeue_model = PYRITION.__DequeueModel
local model_queue = PYRITION.NetStreamModelsQueued
local recipient_iterable = PYRITION._RecipientIterable
local stream_model_methods = PYRITION.NetStreamModelMethods
local stream_models_active = PYRITION.NetStreamModelsActive

--pyrition functions
function PYRITION:NetStreamModelAdd(class, target, post, ...) --create stream models for recipients
	if target and not IsEntity(target) then
		local targets = recipient_iterable(target)
		
		if targets then
			for index, indexed_target in ipairs(targets) do self:NetStreamModelAdd(class, indexed_target, post) end
			
			return
		end
	end
	
	if post then post(self:NetStreamModelCreate(class, target), ...)
	else self:NetStreamModelCreate(class, target) end
end

function PYRITION:NetStreamModelsGet(class, ply) --get a list of writable models
	local models = {}
	
	--find models that match the ply
	for stream, record in pairs(stream_models_active[class] or {}) do
		--models with Completed can't be written to, and for NetSendFinished it would be meaningless to write
		if record == ply and not (stream.Completed or stream.NetSendFinished) then table.insert(models, stream) end
	end
	
	return models[1] and models or false
end

function PYRITION:NetStreamModelQueue(class, target, ...) --prepare a model to sync to multiple targets on the next think
	--varargs are parameters to call the Write method with, and are inherited not merged
	--so if you need a table, make modifications to the returned table not the argument table
	local queued = model_queue[class]
	
	if queued then
		local queued_target = queued.Target
		
		for index, value in pairs{...} do if queued[index] == nil then queued[index] = value end end
		if queued_target == true then return unpack(queued) end
		
		duplex_insert(queued.Target)
		
		return unpack(queued)
	end
	
	model_queue[class] = {Target = target == true and target or {target}, ...}
	
	return ...
end

function PYRITION:NetStreamModelThink() --only called if model_queue has values
	for class, model_arguments in pairs(model_queue) do
		if stream_model_methods[class].CopyOptimization then
			local players = recipient_iterable(model_arguments.Target)
			local target = table.remove(players)
			local source_model = self:NetStreamModelCreate(class, target)
			
			dequeue_model(source_model, unpack(model_arguments))
			
			--essentially ctrl+c this first model
			local source_data = source_model.Data
			
			--then ctrl+v it on all the other models
			for index, ply in ipairs(players) do
				local model = self:NetStreamModelCreate(class, target)
				model.Data = source_data
				
				model:Complete()
			end
		else self:NetStreamModelAdd(class, model_arguments.Target, dequeue_model) end
	end
	
	table.Empty(model_queue)
end