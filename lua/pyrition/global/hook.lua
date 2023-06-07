--[[-# How to use the GlobalHook component
Somewhere in your code do `PYRITION:GlobalHookInstall("AddonNamespace", METHODS)` where `METHODS` is your methods table,
and `AddonNamespace` is the prefix all the hook calls will use. This preferrably should be your addon's name in CamelCase.
It is a good idea to call this before you start defining your functions in your methods table.  

Make a function with in your methods table prefixed by `HOOK_`.
```
function METHODS:HOOK_SomethingCool(paramater, another_parameter)
	--some code...
	return paramater * 2 + another_parameter
end
```

Somewhere at the end of your load order after all methods have been defined you should run `METHODS:GlobalHookRefresh()`.  

When you need to run `METHODS:HOOK_SomeFunction` call `METHODS:SomeFunction` instead.
```
function METHODS:Foo(fibonachi)
	--some code...
	self:SomeFunction(fibonachi, some_variable)
	--some more code...
end
```

To make a hook for the function, use your prefix provided in $$PYRITION:GlobalHookInstall followed by the function name (without `HOOK_`).
```
hook.Add("SomethingCool", "ThirdPartyAddon", function(paramater, another_parameter)
	--returns are supported
	--typical hook behavior: the `HOOK_SomethingCool` code will not be ran as the hook module will block it
	if paramater > 5 then return 0 end
end)
```
The hook above will be run everytime `METHODS:SomeFunction` is called.
If you want to run the hooked function directly without the automatically calling "hook.Call" use `METHODS:HOOK_SomeFunction`.
Do not call `METHODS:AddonNamespaceSomethingCool` - this is forbidden behavior as this funcion should only ever be run by the hook module.  

If you are calling your function that needs to be hooked before `METHODS:GlobalHookRefresh()` is called,
you can do `METHODS:GlobalHookCreate("SomethingCool")` to create the hooked functions instantly.]]


local function create(method_table, short_key, post_hook)
	--[[-ARGUMENTS:
		table "The table which contains your methods with and without the `HOOK_` prefix.",
		string "The function's name in your method table without the `HOOK_`",
		boolean=nil "Set to `true` to create a function prefixed by your global hook"]]
	---SEE: PYRITION:GlobalHookCreate
	---Immediately converts the function in your $method_table.

	--keep track of the hook's post status
	if post_hook == nil then post_hook = method_table["_GlobalHookPost_" .. short_key]
	else method_table["_GlobalHookPost_" .. short_key] = post_hook end

	local hook_event = method_table.GlobalHookPrefix .. short_key
	local true_key = "HOOK_" .. short_key
	local true_method = method_table[true_key]

	if true_method then method_table[hook_event] = method_table[true_key]
	else
		true_method = method_table[hook_event] or method_table[short_key]
		method_table[true_key] = true_method
	end

	assert(true_method, "Failed to find source method for GlobalHookCreate with key " .. short_key)

	if post_hook then
		local hook_event_post = method_table.GlobalHookPrefix .. "Post" .. short_key

		method_table[short_key] = function(self, ...)
			local returns = {hook.Call(hook_event, self, ...)}

			hook.Call(hook_event_post, self, ...)

			return unpack(returns)
		end
	else method_table[short_key] = function(self, ...) return hook.Call(hook_event, self, ...) end end
end

local function refresh(method_table)
	---ARGUMENTS: table "The table which contains your methods with and without the `HOOK_` prefix."
	---SEE: PYRITION:GlobalHookRefresh
	---Sets up hooking for all of your $[method table's](method_table) functions.
	---Internally just calls GlobalHookCreate for every function prefixed by `HOOK_`.
	local queued = {}

	for key, value in pairs(method_table) do
		if isstring(key) and isfunction(value) and string.StartsWith(key, "HOOK_") then
			table.insert(queued, key)
		end
	end

	for index, key in ipairs(queued) do
		local short_key = string.sub(key, 6)

		if not method_table[short_key] then create(method_table, short_key) end
	end
end

function PYRITION:GlobalHookInstall(prefix, method_table)
	--[[-ARGUMENTS:
		string "The text to prefix the hook calls with.",
		table "The table which contains your methods with and without the `HOOK_` prefix."]]
	---Installs the GlobalHookCreate and GlobalHookRefresh functions for easily creating methods that call hooks.
	---If you prefix a function in the $method_table with `HOOK_`, a function will be created without the prefix.
	---This version of the function can be called to also run a `hook.Call` where the event is the name of the function with your $prefix.
	method_table.GlobalHookCreate = create
	method_table.GlobalHookPrefix = prefix
	method_table.GlobalHookRefresh = refresh
end

PYRITION:GlobalHookInstall("Pyrition", PYRITION)