-- Tutorial
hook.Add("TTTTutorialRoleTextExtra", "EnhancedMedium_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
    if role == ROLE_MEDIUM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        -- Respawn
        htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is killed, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"

        -- Smoke
        if GetGlobalBool("ttt_medium_killer_smoke", false) then
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>Before the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is respawned, their killer is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>, revealing themselves as the " .. ROLE_STRINGS[ROLE_PHANTOM] .. "'s killer to other players.</span>"
        end

        -- Haunting
        if GetGlobalBool("ttt_medium_killer_haunt", true) then
            local max = GetGlobalInt("ttt_medium_killer_haunt_power_max", 100)
            local move_cost = GetGlobalInt("ttt_medium_killer_haunt_move_cost", 25)
            local jump_cost = GetGlobalInt("ttt_medium_killer_haunt_jump_cost", 50)
            local drop_cost = GetGlobalInt("ttt_medium_killer_haunt_drop_cost", 75)
            local attack_cost = GetGlobalInt("ttt_medium_killer_haunt_attack_cost", 100)

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

-- Haunting HUD
hook.Add("TTTSpectatorShowHUD", "EnhancedMedium_Haunting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsMedium() then return end

    local L = LANG.GetUnsafeLanguageTable()
    local willpower_colors = {
        border = COLOR_WHITE,
        background = Color(17, 115, 135, 222),
        fill = Color(82, 226, 255, 255)
    }
    local powers = {
        [L.haunt_move] = GetGlobalInt("ttt_medium_killer_haunt_move_cost", 25),
        [L.haunt_jump] = GetGlobalInt("ttt_medium_killer_haunt_jump_cost", 50),
        [L.haunt_drop] = GetGlobalInt("ttt_medium_killer_haunt_drop_cost", 75),
        [L.haunt_attack] = GetGlobalInt("ttt_medium_killer_haunt_attack_cost", 100)
    }
    local max_power = GetGlobalInt("ttt_medium_killer_haunt_power_max", 100)
    local current_power = cli:GetNWInt("MediumHauntingPower", 0)

    HUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
end)

-- Haunting Smoke
hook.Add("TTTShouldPlayerSmoke", "EnhancedMedium_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("MediumHaunted", false) and GetGlobalBool("ttt_medium_killer_smoke", false) then
        return true
    end
end)