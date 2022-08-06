AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs
local player = player
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("EnhancedPaladin_ShowDamageAura")

-- ConVars
local paladin_explosion_immune = CreateConVar("ttt_paladin_explosion_immune", "1")
local paladin_explosion_protect_self = CreateConVar("ttt_paladin_explosion_protect_self", "1")

-- Globals
hook.Add("TTTSyncGlobals", "EnhancedPaladin_TTTSyncGlobals", function()
    SetGlobalBool("ttt_paladin_explosion_protect_self", paladin_explosion_protect_self:GetBool())
end)

-- Explosion damage reduction
hook.Add("EntityTakeDamage", "EnhancedPaladin_EntityTakeDamage", function(ent, dmginfo)
    if not IsValid(ent) then return end

    if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() and paladin_explosion_immune:GetBool() and dmginfo:IsExplosionDamage() then
        if not ent:IsPaladin() or paladin_explosion_protect_self:GetBool() then
            local paladin = nil
            local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
            for _, v in pairs(GetAllPlayers()) do
                if v:IsActivePaladin() and v:GetPos():Distance(ent:GetPos()) <= radius then
                    paladin = v
                    break
                end
            end
            if IsPlayer(paladin) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)

                net.Start("EnhancedPaladin_ShowDamageAura")
                net.WriteEntity(paladin)
                net.Broadcast()
            end
        end
    end
end)