local hook = hook
local IsValid = IsValid
local surface = surface

-------------
-- CONVARS --
-------------

local tracker_blind_time = GetConVar("ttt_tracker_blind_time")

-- Tutorial
hook.Add("TTTTutorialRoleTextExtra", "EnhancedTracker_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
    if role == ROLE_TRACKER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        -- Blindness
        if tracker_blind_time:GetInt() > 0 then
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