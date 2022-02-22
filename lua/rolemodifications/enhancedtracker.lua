if SERVER then AddCSLuaFile() end

if CLIENT then
    ------------
    -- CLIENT --
    ------------

    -- Tutorial
    hook.Add("TTTTutorialRoleTextExtra", "EnhancedTracker_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
        if role == ROLE_TRACKER then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]

            -- Blindness
            local blindTime = GetGlobalInt("ttt_tracker_blind_time", 5)
            if blindTime > 0 then
                htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>Anyone who kills the " .. ROLE_STRINGS[ROLE_TRACKER] .. " is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>blinded</span> by tears and cannot see for " .. tostring(blindTime) .. " second"
                if blindTime ~= 1 then
                    htmlData = htmlData .. "s"
                end
                htmlData = htmlData .. ".</span>"
            end

            return htmlData
        end
    end)

    -- Blindness
    hook.Add("HUDPaint", "EnhancedTracker_Blind_HUDPaint", function()
        local client = LocalPlayer()
        if IsValid(client) and client:Alive() and client:GetNWBool("blindedbytracker") then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end
    end)
else
    ------------
    -- SERVER --
    ------------

    -- ConVars
    local tracker_blind_time = CreateConVar("ttt_tracker_blind_time", "5", FCVAR_NONE, "The number of seconds to blind the Tracker's killer. Set to 0 to disable.", 0, 100)

    -- Globals
    hook.Add("TTTSyncGlobals", "EnhancedTracker_TTTSyncGlobals", function()
        SetGlobalInt("ttt_tracker_blind_time", tracker_blind_time:GetInt())
    end)

    -- Manage Death
    hook.Add( "PlayerDeath", "EnhancedTracker_PlayerDeath", function( victim, infl, attacker )
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
    end )

    -- Cleanup
    hook.Add("TTTEndRound", "EnhancedTracker_TTTEndRound", function()
        for _, v in pairs(player.GetAll()) do
            v:SetNWBool("blindedbytracker", false)
        end
    end)
end