local dequeue_model = PYRITION._NetStreamDequeueModel
local model_queue = PYRITION.NetStreamModelsQueued
local stream_models_active = PYRITION.NetStreamModelsActive

function PYRITION:NetStreamModelAdd(class, _target, post, ...) --here for shared safety
	if post then post(self:NetStreamModelCreate(class), ...)
	else self:NetStreamModelCreate(class) end
end

function PYRITION:NetStreamModelsGet(class) --get a list of writable models
	local models = {}

	--find models that match the ply
	for stream, record in pairs(stream_models_active[class] or {}) do
		--models with Completed can't be written to, and for NetSendFinished it would be meaningless to write
		if not (stream.Completed or stream.NetSendFinished) then table.insert(models, stream) end
	end

	return models[1] and models or false
end

function PYRITION:NetStreamModelQueue(class, _target, ...) --prepare a model to sync to server on the next think
	--varargs are parameters to call the Write method with, and are inherited not merged
	--so if you need a table, make modifications to the returned table not the parameter table
	--target parameter is to make this function shared safe, as server requires targets
	--on CLIENT the server is the implied target
	local queued = model_queue[class]

	if queued then
		for index, value in pairs{...} do if queued[index] == nil then queued[index] = value end end

		return unpack(queued)
	end

	model_queue[class] = {...}

	return ...
end

function PYRITION:NetStreamModelThink() --only called if model_queue has values
	for class, model_arguments in pairs(model_queue) do self:NetStreamModelCreate(class, nil, dequeue_model) end

	table.Empty(model_queue)
end