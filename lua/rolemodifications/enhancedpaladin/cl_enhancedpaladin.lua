-- Tutorial
hook.Add("TTTTutorialRoleTextExtra", "EnhancedPaladin_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
    if role == ROLE_PALADIN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        -- Explosion Reduction
        htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PALADIN] .. "'s aura also gives players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>explosion immunity</span> "
        if GetGlobalBool("ttt_paladin_explosion_protect_self", false) then
            htmlData = htmlData .. "which applies to the " .. ROLE_STRINGS[ROLE_PALADIN] .. " as well"
        else
            htmlData = htmlData .. "however this does NOT apply to the " .. ROLE_STRINGS[ROLE_PALADIN] .. "."
        end
        htmlData = htmlData .. ".</span>"

        return htmlData
    end
end)