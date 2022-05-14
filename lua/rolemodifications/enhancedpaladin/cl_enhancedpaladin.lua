local hook = hook
local math = math

local MathCos = math.cos
local MathSin = math.sin

-- Damage aura
net.Receive("EnhancedPaladin_ShowDamageAura", function()
    local client = LocalPlayer()
    local paladin = net.ReadEntity()
    local paladinPos = paladin:GetPos()
    local pos = paladinPos + Vector(0, 0, 30)
    if client:GetPos():Distance(pos) > 3000 then return end

    local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
    local auraEmitter = ParticleEmitter(paladinPos)
    auraEmitter:SetPos(pos)

    for auraDir = 0, 6, 0.05 do
        local vec = Vector(MathSin(auraDir) * radius, MathCos(auraDir) * radius, 10)
        local particle = auraEmitter:Add("particle/shield.vmt", paladinPos + vec)
        particle:SetVelocity(Vector(0, 0, 20))
        particle:SetDieTime(1)
        particle:SetStartAlpha(200)
        particle:SetEndAlpha(0)
        particle:SetStartSize(3)
        particle:SetEndSize(2)
        particle:SetRoll(0)
        particle:SetRollDelta(0)
        particle:SetColor(ROLE_COLORS[ROLE_PALADIN].r, ROLE_COLORS[ROLE_PALADIN].g, ROLE_COLORS[ROLE_PALADIN].b)
    end

    auraEmitter:Finish()
end)

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