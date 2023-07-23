--locals
local PANEL = {}
local volumes = {"volume-low", "volume-medium", "volume-high"}
local volumes_count = #volumes

--panel functions
function PANEL:SetVolume(volume) self:SetIcon(volume == 0 and "volume-off" or volumes[math.Round(math.Remap(volume, 0, 1, 1, volumes_count))]) end

--post
derma.DefineControl("PyritionMaterialDesignIconVolume", "An icon made with a material design icon vector graphic.", PANEL, "PyritionMaterialDesignIcon")