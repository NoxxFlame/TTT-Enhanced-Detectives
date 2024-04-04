AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local tracker_blind_time = GetConVar("ttt_tracker_blind_time")

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

            attacker:QueueMessage(MSG_PRINTCENTER, "You have killed the " .. ROLE_STRINGS[ROLE_TRACKER] .. "! You are blinded by guilt for " .. duration .. " seconds")
        end
    end
end)

-- Cleanup
hook.Add("TTTEndRound", "EnhancedTracker_TTTEndRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("blindedbytracker", false)
    end
    timer.Remove("EnhancedTrackerBlindTimer")
end)