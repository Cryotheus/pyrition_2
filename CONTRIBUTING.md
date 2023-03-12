# Issues
Use one of the issue templates [here](https://github.com/Cryotheus/pyrition_2/issues/new/choose). If none of them apply, try to provide as much information as possible. If you are reporting a bug, provide steps to reproduce the bug at the minimum. If you are requesting a feature, provide a detailed description of the feature and how it would be used.

# Pull Requests
Use the specified style as described below. If it's not perfect, the maintainers of this repository can make corrections.

# Code Style
Expect these to change as the project grows.
-	Don't use `some_function "text"` use `some_function("text")` instead (`ipairs{...}` and the like is acceptable)
-	EoLS (End of Line Sequence) must be CRLF
-	If applicable, make your text support localization and provide english localization phrases
-	Modules should avoid `package.seeall` unless the localizations are excessive or global access is frequently needed
-	Pure Lua only (no `!`, `!=`, `&&`, `||`, etc. unless there is no operation alternative eg. `%`)
-	Use a trailing command in tables if you are planning to expand the table
-	Use tabs for indentation (assume a tab is 4 spaces)
-	*Suggested but not necessary:* use `do end` blocks for panel scoping and organization

## Naming Convention
Avoid single letter variables, unless representing mathematical components (x y z, i j k, etc.)
| What                | Format                 | Example                                                                  | Exceptions                                    |
| ------------------- | ---------------------- | ------------------------------------------------------------------------ | --------------------------------------------- |
| Comment             | `passive journalism`   | `--this is a comment about bees`                                         | TODOs, word grammar (use "I did" not "i did") |
| Constant            | `SCREAMING_SNAKE_CASE` | `COLOR_INFANTRY = Color(48, 145, 194)`                                   |                                               |
| Files               | `lower_snake_case`     | `include("math/theoretical_calculus/quantum_tunneling_random_seed.lua")` |                                               |
| Function parameter  | `lower_snake_case`     | `function(first_parameter, something_else) end`                          |                                               |
| Global              | `UpperCamelCase`       | `AddonVariableName = true`                                               |                                               |
| Global method table | `SCREAMING_SNAKE_CASE` | `COOL_ADDON = COOL_ADDON or {Version = "1.0.0"}`                         |                                               |
| Identifier          | `UpperCamelCase`       | `hook.Add("Think", "CoolAddon") net.Receive("CoolAddon")`                | identifier is not externally accessible       |
| Key                 | `UpperCamelCase`       | `local some_table = {NiceKey = "bored value"}`                           | databases, files, purely local tables         |
| Local               | `lower_snake_case`     | `local variable_name = 0`                                                | localized functions                           |
| Localized functions | variable               | `local math_Round = math.Round` `local CurTime = CurTime`                |                                               |
| Localized values    | `lower_snake_case`     | `local pi = math.pi` `local banned_players = COOL_ADDON.BannedPlayers`   |                                               |
| Method              | `UpperCamelCase`       | `function COOL_ADDON:RudeMethod`                                         |                                               |

### Global Method Table
In Pyrition specifically, the global method table is `PYRITION` and any function prefixed with `Pyrition` is assumed to be a method that needs hooking. To use a method prefixed with `Pyrition`, you must use the `PYRITION` table. There are functions meant to be used as a localized function (eg. `local color_mix = PYRITION._ColorMix`) and I would like to move away from storing them in the global method table and start making modules instead.  
Methods should be named based on their location in the project. You should need to have `Client`, `Server`, or `Shared` in the name unless absolutely necessary.  

## Ordering
Compartmentalize and alphabetically sort your code when possible. Most of the time you will find files with simple comments that denote the sections of the file. These are not neccessary (originally used for a now-defunct visualizer script), but highly suggested.  
The order is as follows:

| Comment Tag                                        | Description                                                                                                      |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `--!dump me!`                                      | For preprocessors, should be removed in production                                                               |
| `--debug`                                          | Should be removed in production                                                                                  |
| `--autoreload`                                     | Code to properly reload the script                                                                               |
| `--pragma once`                                    | Usually immediately followed by `if <condition> then return end` and stops the file from being reloaded          |
| `--header` or ` `                                  | Uncommon, usually contains `include`, `require`, and sometimes calls to the `resource` and `util` libraries      |
| `--locals`                                         | Local variables sometimes including localized functions                                                          |
| `--localized functions` `----localized functions`  | Large list of localized functions for when there are too many to use in the locals section, may have indentation |
| `--` `----`                                        | Used to indicate the end of indented localized functions (hint to the IDE)                                       |
| `--local tables`                                   | Local tables that may contain localized values, rarely includes empty and one-liner tables                       |
| `--local functions`                                | Self explanatory, can be used to create a function for an already declared local                                 |
| `--post function setup`                            | Code for initializing tables, userdata, and whatever else needs to be done before the code below                 |
| `--globals`                                        | Global variables and values set in global tables                                                                 |
| `--global functions`                               | Global functions                                                                                                 |
| `--<addon name> methods` `--<addon name> function` | Methods for a `<ADDON_NAME>` global method table                                                                 |
| `--<addon name> hooks`                             | Methods prefixed by camel case `<AddonName>`                                                                     |
| `--commands`                                       | Calls to `concommand.Add`                                                                                        |
| `--convars`                                        | Convar change callbacks                                                                                          |
| `--hooks`                                          | Hooks create with `hook.Add`                                                                                     |
| `--net`                                            | `net.Receive` callbacks                                                                                          |
| `--post`                                           | Initialization code for the file                                                                                 |
| `--autoreload`                                     | Code to properly reload the script                                                                               |
| `--debug`                                          | Should be removed in production                                                                                  |
| `--returns`                                        | For scripts that need to return lots of values or large (using a lot of characters) table                        |

## Spacing
Don't worry too much about spacing rules. I tend to add more space around larger function and table declarations, and shrink space around one lines. I also try to group code that is similar together.  
It's generally based off how readable it is to me (Cryotheum) when by vision gets blurry from overdosing on caffeine.

Example of a file (this file would be of the path `lua/cool_addon/rude.lua` or `lua/cool_addon/rude/server.lua`)
```lua
include("includes/entity_proxy.lua")
util.AddNetworkString("CoolAddonRude")

--locals
local author = "Shamiah"
local local_variable = 0
local math_Round = math.Round
local something_else_local = 1

--local tables
local cool_stuff = {
	cool = "some values",
	keys_and = "some values"
	stuff = "some values",
}

local externally_available = {
	BoyzNoise = "GirlsNoize",
	MakeTheseKeysCamelCase = "since we can access them from externally",
}

--local functions
local function local_function() end
local function other_local_function() end

--globals
COOL_ADDON.RudeRegistry = externally_available

--cool addon methods
function COOL_ADDON:RudeLoad(file_name) --[[one liner method]] end
function COOL_ADDON:RudeRefresh(send_to_clients, ignore_list, delete) --[[one liner method]] end

function COOL_ADDON:RudeSetPoggonians()
	--imagine some code being here
	--I used to write --more!
	--when I plan on writing more code
	--I now write TODO: more!
end

function COOL_ADDON:RudeSetZettaFactor(object, indexing_value, some_number) --you can comment like this
	---triple dash for auto generated documentation
	---returns
	local existing = object[indexing_value]
	
	--create the table if it doesn't already exist (example of a normal comment)
	if not existing then object[indexing_value] = {some_number, Count = 1}
	else object.Count = table.insert(existing, some_number) end
	
	return object.Count
end

function COOL_ADDON:RudeZymurgy() --[[one liner method]] end

--cool addon hooks
function COOL_ADDON:CoolAddonRudeReload()
	--to run this code you would call COOL_ADDON:RudeReload(...)
	--this will run hook.Call("CoolAddonRudeReload", COOL_ADDON, ...)
	--to avoid issues with this, do not have anything prefixed with Post or CoolAddonPost
end

--hooks
hook.Add("InitPostEntity", "CoolAddonRude", function()
	--multiline code here!
	--notice the spacing
end)

hook.Add("Think", "CoolAddonRude" function() --[[one liner code]] end)
hook.Add("Tick", "CoolAddonRude" function() --[[more one liner code]] end)

hook.Add("ZettaModReloaded", "CoolAddonRude", function()
	--another hook
	--with multiline code!
end)

hook.Add("ZettaModSetRoof", "CoolAddonRude", function() --[[one liners again! x1]] end)
hook.Add("ZettaModSetRound", "CoolAddonRude", function() --[[one liners again! x2]] end)
hook.Add("ZettaModSetSoupMmmDelicious", "CoolAddonRude", function() --[[one liners again! x3]] end)

--net
net.Receive("CoolAddonRude", function(_length, ply)
	--prefix unused parameters with _ (for linter!)
end)

```