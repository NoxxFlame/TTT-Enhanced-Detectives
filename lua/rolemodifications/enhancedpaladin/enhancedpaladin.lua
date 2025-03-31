AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local player = player
local util = util

local PlayerIterator = player.Iterator

util.AddNetworkString("EnhancedPaladin_ShowDamageAura")

-------------
-- CONVARS --
-------------

local paladin_explosion_immune = CreateConVar("ttt_paladin_explosion_immune", "1")

local paladin_explosion_protect_self = GetConVar("ttt_paladin_explosion_protect_self")

-- Explosion damage reduction
hook.Add("EntityTakeDamage", "EnhancedPaladin_EntityTakeDamage", function(ent, dmginfo)
    if not IsValid(ent) then return end

    if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() and paladin_explosion_immune:GetBool() and dmginfo:IsExplosionDamage() then
        if not ent:IsPaladin() or paladin_explosion_protect_self:GetBool() then
            local paladin = nil
            local radius = GetConVar("ttt_paladin_aura_radius"):GetInt() * UNITS_PER_METER
            for _, v in PlayerIterator() do
                if v:IsActivePaladin() and v:GetPos():Distance(ent:GetPos()) <= radius then
                    paladin = v
                    break
                end
            end
            if IsPlayer(paladin) and (not paladin.IsRoleAbilityDisabled or not paladin:IsRoleAbilityDisabled()) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)

                net.Start("EnhancedPaladin_ShowDamageAura")
                    net.WritePlayer(paladin)
                net.Broadcast()
            end
        end
    end
end)