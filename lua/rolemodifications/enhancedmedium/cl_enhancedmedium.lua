local hook = hook

-------------
-- CONVARS --
-------------

local medium_killer_smoke = GetConVar("ttt_medium_killer_smoke")
local medium_killer_haunt = GetConVar("ttt_medium_killer_haunt")
local medium_killer_haunt_power_max = GetConVar("ttt_medium_killer_haunt_power_max")
local medium_killer_haunt_move_cost = GetConVar("ttt_medium_killer_haunt_move_cost")
local medium_killer_haunt_jump_cost = GetConVar("ttt_medium_killer_haunt_jump_cost")
local medium_killer_haunt_drop_cost = GetConVar("ttt_medium_killer_haunt_drop_cost")
local medium_killer_haunt_attack_cost = GetConVar("ttt_medium_killer_haunt_attack_cost")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "EnhancedMedium_Translations_Initialize", function()
    -- Target ID
    LANG.AddToLanguage("english", "target_haunted_medium", "HAUNTED BY MEDIUM")
end)

------------------
-- CUPID LOVERS --
------------------

local function IsLoverHaunting(cli, target)
    local loverSID = cli:GetNWString("TTTCupidLover", "")
    local lover = player.GetBySteamID64(loverSID)
    return IsPlayer(target) and IsPlayer(lover) and target:GetNWBool("MediumHaunted", false) and lover:GetNWString("MediumHauntingTarget", "") == target:SteamID64()
end

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerText", "EnhancedMedium_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if IsLoverHaunting(cli, ent) then
        return LANG.GetTranslation("target_haunted_medium"), ROLE_COLORS_RADAR[ROLE_MEDIUM]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_MEDIUM] = function(ply, target)
    if not IsPlayer(target) then return end
    if not IsLoverHaunting(ply, target) then return end

    ------ icon,  ring,  text
    return false, false, target:GetNWBool("MediumHaunted", false)
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "EnhancedMedium_TTTScoreboardPlayerRole", function(ply, client, c, roleStr)
    if IsLoverHaunting(client, ply) then
        return c, roleStr, ROLE_MEDIUM
    end
end)

hook.Add("TTTScoreboardPlayerName", "EnhancedMedium_TTTScoreboardPlayerName", function(ply, cli, text)

    if IsLoverHaunting(cli, ply) then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_haunted_medium") .. ")"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_MEDIUM] = function(ply, target)
    if not IsPlayer(target) then return end
    if not IsLoverHaunting(ply, target) then return end

    ------ name, role
    return true, true
end

--------------
-- HAUNTING --
--------------

hook.Add("TTTSpectatorShowHUD", "EnhancedMedium_Haunting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsMedium() then return end

    local L = LANG.GetUnsafeLanguageTable()
    local willpower_colors = {
        border = COLOR_WHITE,
        background = Color(17, 115, 135, 222),
        fill = Color(82, 226, 255, 255)
    }
    local powers = {
        [L.haunt_move] = medium_killer_haunt_move_cost:GetInt(),
        [L.haunt_jump] = medium_killer_haunt_jump_cost:GetInt(),
        [L.haunt_drop] = medium_killer_haunt_drop_cost:GetInt(),
        [L.haunt_attack] = medium_killer_haunt_attack_cost:GetInt()
    }
    local max_power = medium_killer_haunt_power_max:GetInt()
    local current_power = cli:GetNWInt("MediumPossessingPower", 0)

    CRHUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
end)

hook.Add("TTTShouldPlayerSmoke", "EnhancedMedium_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("MediumHaunted", false) and medium_killer_smoke:GetBool() then
        return true
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleTextExtra", "EnhancedMedium_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
    if role == ROLE_MEDIUM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        -- Respawn
        htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"

        -- Smoke
        if medium_killer_smoke:GetBool() then
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>Before the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is respawned, their killer is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>, revealing themselves as the " .. ROLE_STRINGS[ROLE_PHANTOM] .. "'s killer to other players.</span>"
        end

        -- Haunting
        if medium_killer_haunt:GetBool() then
            local max = medium_killer_haunt_power_max:GetInt()
            local move_cost = medium_killer_haunt_move_cost:GetInt()
            local jump_cost = medium_killer_haunt_jump_cost:GetInt()
            local drop_cost = medium_killer_haunt_drop_cost:GetInt()
            local attack_cost = medium_killer_haunt_attack_cost:GetInt()

            -- Haunting powers
            if move_cost > 0 or jump_cost > 0 or drop_cost > 0 or attack_cost > 0 then
                htmlData = htmlData .. "<span style='display: block; margin-top: 10px'>While dead, the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " will haunt their killer, generating up to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. max .. " haunting power</span> over time. This haunting power can be used on the following actions:</span>"

                htmlData = htmlData .. "<ul style='margin-top: 0'>"
                if move_cost > 0 then
                    htmlData = htmlData .. "<li>Move Target (Cost: " .. move_cost .. ") - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Move the target</span> in the direction you choose using your movement keys</li>"
                end
                if jump_cost > 0 then
                    htmlData = htmlData .. "<li>Jump (Cost: " .. jump_cost .. ") - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Make the target jump</span> using your jump key</li>"
                end
                if drop_cost > 0 then
                    htmlData = htmlData .. "<li>Drop Weapon (Cost: " .. drop_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>drop their weapon</span> using your weapon drop key</li>"
                end
                if attack_cost > 0 then
                    htmlData = htmlData .. "<li>Attack (Cost: " .. attack_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>attack with their current weapon</span> using your primary attack key</li>"
                end
                htmlData = htmlData .. "</ul>"
            end
        end

        return htmlData
    end
end)