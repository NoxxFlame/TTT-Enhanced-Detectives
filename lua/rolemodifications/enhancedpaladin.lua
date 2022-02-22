if SERVER then AddCSLuaFile() end

if CLIENT then
    ------------
    -- CLIENT --
    ------------

    -- Tutorial
    hook.Add("TTTTutorialRoleTextExtra", "EnhancedPaladin_TTTTutorialRoleTextExtra", function(role, titleLabel, roleIcon, htmlData)
        if role == ROLE_PALADIN then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]

            -- Explosion Reduction
            htmlData = htmlData .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PALADIN] .. "'s aura also gives players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>explosion immunity</span> "
            if GetGlobalBool("paladin_explosion_protect_self", false) then
                htmlData = htmlData .. "which applies to the " .. ROLE_STRINGS[ROLE_PALADIN] .. " as well"
            else
                htmlData = htmlData .. "however this does NOT apply to the " .. ROLE_STRINGS[ROLE_PALADIN] .. "."
            end
            htmlData = htmlData .. ".</span>"

            return htmlData
        end
    end)
    
else
    ------------
    -- SERVER --
    ------------

    -- ConVars
    local paladin_explosion_immune = CreateConVar("paladin_explosion_immune", "1")
    local paladin_explosion_protect_self = CreateConVar("ttt_paladin_explosion_protect_self", "1")

    -- Globals
    hook.Add("TTTSyncGlobals", "EnhancedPaladin_TTTSyncGlobals", function()
        SetGlobalBool("paladin_explosion_protect_self", paladin_explosion_protect_self:GetBool())
    end)

    -- Explosion damage reduction
    hook.Add("EntityTakeDamage", "EnhancedPaladin_EntityTakeDamage", function(ent, dmginfo)
        if not IsValid(ent) then return end

        if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() and paladin_explosion_immune:GetBool() and dmginfo:IsExplosionDamage() then
            if not ent:IsPaladin() or paladin_explosion_protect_self:GetBool() then
                local withPaladin = false
                local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
                for _, v in pairs(player.GetAll()) do
                    if v:IsPaladin() and v:GetPos():Distance(ent:GetPos()) <= radius then
                        withPaladin = true
                        break
                    end
                end
                if withPaladin then
                    dmginfo:ScaleDamage(0)
                    dmginfo:SetDamage(0)
                end
            end
        end
    end)
end