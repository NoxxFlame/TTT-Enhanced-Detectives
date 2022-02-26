AddCSLuaFile()

local hook = hook
local pairs = pairs
local player = player
local timer = timer

local GetAllPlayers = player.GetAll

-- ConVars
local tracker_blind_time = CreateConVar("ttt_tracker_blind_time", "5", FCVAR_NONE, "The number of seconds to blind the Tracker's killer. Set to 0 to disable.", 0, 100)

-- Globals
hook.Add("TTTSyncGlobals", "EnhancedTracker_TTTSyncGlobals", function()
    SetGlobalInt("ttt_tracker_blind_time", tracker_blind_time:GetInt())
end)

-- Manage Death
hook.Add("PlayerDeath", "EnhancedTracker_PlayerDeath", function( victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE

    if valid_kill and victim:IsTracker() and not victim:GetNWBool("IsZombifying", false) then
        local duration = tracker_blind_time:GetInt()

        if duration > 0 then
            attacker:SetNWBool("blindedbytracker", true)

            timer.Create("EnhancedTrackerBlindTimer", duration, 1, function()
                attacker:SetNWBool("blindedbytracker", false)
            end)

            attacker:PrintMessage(HUD_PRINTCENTER, "You have killed the " .. ROLE_STRINGS[ROLE_TRACKER] .. "! You are blinded by guilt for " .. duration .. " seconds")
        end
    end
end)

-- Cleanup
hook.Add("TTTEndRound", "EnhancedTracker_TTTEndRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("blindedbytracker", false)
    end
    timer.Remove("EnhancedTrackerBlindTimer")
end)