include("pyrition/loader.lua")

--commands
concommand.Add(SERVER and "sv_pyrition_restart" or "cl_pyrition_restart", function(ply, command, arguments, arguments_string) include("pyrition/loader.lua") end, nil, "Reload Pyrition with auto-reload enabled.")

if SERVER then
	concommand.Add("pyrition_restart", function(ply, command, arguments, arguments_string)
		if ply:IsValid() or not ply:IsSuperAdmin() then return end
		
		RunConsoleCommand("sv_pyrition_restart")
		
		for index, ply in ipairs(player.GetAll()) do ply:ConCommand("cl_pyrition_restart") end
	end, nil, "Reload Pyrition with auto-reload enabled.")
end