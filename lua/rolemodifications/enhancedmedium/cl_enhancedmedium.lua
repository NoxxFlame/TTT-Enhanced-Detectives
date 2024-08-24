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
local medium_weaker_each_respawn = GetConVar("ttt_medium_weaker_each_respawn")
local medium_announce_death = GetConVar("ttt_medium_announce_death")
local medium_killer_footstep_time = GetConVar("ttt_medium_killer_footstep_time")
local medium_respawn = GetConVar("ttt_medium_respawn")

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

    local current_power = cli:GetNWInt("MediumPossessingPower", 0)
    local max_power = medium_killer_haunt_power_max:GetInt()

    if CRVersion("2.2.1") then
        local powers = {}
        local killer_haunt_move_cost = medium_killer_haunt_move_cost:GetInt()
        if killer_haunt_move_cost > 0 then
            table.insert(powers, {name = L.haunt_move, key = "arrows", cost = killer_haunt_move_cost, desc = string.Interp(L.haunt_move_desc, {target = tgt:Nick()})})
        end
        local killer_haunt_jump_cost = medium_killer_haunt_jump_cost:GetInt()
        if killer_haunt_jump_cost > 0 then
            table.insert(powers, {name = L.haunt_jump, key = "space", cost = killer_haunt_jump_cost, desc = string.Interp(L.haunt_jump_desc, {target = tgt:Nick()})})
        end
        local killer_haunt_drop_cost = medium_killer_haunt_drop_cost:GetInt()
        if killer_haunt_drop_cost > 0 then
            table.insert(powers, {name = L.haunt_drop, key = "rmb", cost = killer_haunt_drop_cost, desc = string.Interp(L.haunt_drop_desc, {target = tgt:Nick()})})
        end
        local killer_haunt_attack_cost = medium_killer_haunt_attack_cost:GetInt()
        if killer_haunt_attack_cost > 0 then
            table.insert(powers, {name = L.haunt_attack, key = "lmb", cost = killer_haunt_attack_cost, desc = string.Interp(L.haunt_attack_desc, {target = tgt:Nick()})})
        end

        if #powers == 0 then return end

        table.sort(powers, function(a, b)
            if a.cost == b.cost then
                return a.name < b.name
            else
                return a.cost < b.cost
            end
        end)

        CRHUD:PaintPowersHUD(cli, powers, max_power, current_power, willpower_colors, L.haunt_title)
    else
        local powers = {
            [L.haunt_move] = medium_killer_haunt_move_cost:GetInt(),
            [L.haunt_jump] = medium_killer_haunt_jump_cost:GetInt(),
            [L.haunt_drop] = medium_killer_haunt_drop_cost:GetInt(),
            [L.haunt_attack] = medium_killer_haunt_attack_cost:GetInt()
        }

        CRHUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
    end
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
        if medium_respawn:GetBool() then
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"

            -- Weaker each respawn
            if medium_weaker_each_respawn:GetBool() then
                htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>Each time the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, they will respawn with <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>half as much health</span>, down to a minimum of 1hp.</span>"
            end
        end

        -- Announce death
        if medium_announce_death:GetBool() then
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, all " .. LANG.GetTranslation("detectives") .. " (and promoted " .. LANG.GetTranslation("detective") .. "-like roles) <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified</span>.<span>"
        end

        local has_smoke = medium_killer_smoke:GetBool()
        local has_footsteps = medium_killer_footstep_time:GetInt() > 0
        -- Smoke and Killer footsteps
        if has_smoke or has_footsteps then
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>After the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, their killer "
            if has_smoke then
                htmlData = htmlData .. "is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>"
            end

            if has_smoke and has_footsteps then
                htmlData = htmlData .. " and "
            end

            if has_footsteps then
                htmlData = htmlData .. "leaves behind <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bloody footprints</span>"
            end

            htmlData = htmlData .. ", revealing themselves as the " .. ROLE_STRINGS[ROLE_MEDIUM] .. "'s killer to other players.</span>"
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