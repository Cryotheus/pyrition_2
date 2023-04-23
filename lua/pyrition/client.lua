--locals
local vgui_Register = PYRITION.VGUIRegister or vgui.Register

--globals
PYRITION.VGUIRegisterOriginal = vgui_Register

--global functions
function vgui.Register(class_name, ...)
	PYRITION:VGUIRegister(class_name, ...)
	hook.Call("PyritionVGUIRegister_" .. class_name, PYRITION, ...)

	return vgui_Register(class_name, ...)
end

--pyrition functions
function PYRITION:PyritionVGUIRegister(_class_name, _panel_table, _base_name)
	---Called before vgui.Register, used to modify registered panels.
	---To modify a specific panel by class_name, make a hook with the event `PyritionVGUIRegister_Jeff` where `Jeff` is what the class_name is.
	---This version of the hook is called after PyritionVGUIRegister and is not called with the class_name parameter.
end