--commands
if SERVER then
	concommand.Add("sv_pyrition_restart", function(ply)
		if ply:IsValid() then return end
		
		include("pyrition/loader.lua")
	end)
	
	concommand.Add("pyrition_restart", function()
		for index, ply in ipairs(player.GetHumans()) do ply:ConCommand("cl_pyrition_restart") end
		
		include("pyrition/loader.lua")
	end)
else
	concommand.Add("cl_pyrition_restart", function() include("pyrition/loader.lua") end)
	concommand.Add("pyrition_restart", function() include("pyrition/loader.lua") end)
end


include("pyrition/loader.lua")