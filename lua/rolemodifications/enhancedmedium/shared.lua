AddCSLuaFile()

-- Should show spectator hud
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_MEDIUM] = function(ply)
    if ply:GetNWBool("MediumHaunting") then
        return true
    end
end