AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local timer = timer

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local medium_respawn_health = CreateConVar("ttt_medium_respawn_health", "50", FCVAR_NONE, "The amount of health a medium will respawn with", 1, 100)
local medium_weaker_each_respawn = CreateConVar("ttt_medium_weaker_each_respawn", "0")
local medium_announce_death = CreateConVar("ttt_medium_announce_death", "0")
local medium_killer_footstep_time = CreateConVar("ttt_medium_killer_footstep_time", "0", FCVAR_NONE, "The amount of time a medium's killer's footsteps should show before fading. Set to 0 to disable", 1, 60)
local medium_killer_haunt_power_rate = CreateConVar("ttt_medium_killer_haunt_power_rate", "10", FCVAR_NONE, "The amount of power to regain per second when a medium is haunting their killer", 1, 25)
local medium_killer_haunt_without_body = CreateConVar("ttt_medium_killer_haunt_without_body", "1")
local medium_haunt_saves_lover = CreateConVar("ttt_medium_haunt_saves_lover", "1", FCVAR_NONE, "Whether the medium's lover should survive if the medium is haunting a player", 0, 1)

local medium_killer_haunt = GetConVar("ttt_medium_killer_haunt")
local medium_killer_haunt_power_max = GetConVar("ttt_medium_killer_haunt_power_max")
local medium_killer_haunt_move_cost = GetConVar("ttt_medium_killer_haunt_move_cost")
local medium_killer_haunt_jump_cost = GetConVar("ttt_medium_killer_haunt_jump_cost")
local medium_killer_haunt_drop_cost = GetConVar("ttt_medium_killer_haunt_drop_cost")
local medium_killer_haunt_attack_cost = GetConVar("ttt_medium_killer_haunt_attack_cost")

local cured = Sound("items/smallmedkit1.wav")

--------------
-- HAUNTING --
--------------

local deadMediums = {}
hook.Add("TTTPrepareRound", "EnhancedMedium_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("MediumHaunted", false)
        v:SetNWBool("MediumHaunting", false)
        v:SetNWString("MediumHauntingTarget", nil)
        v:SetNWBool("MediumPossessing", false)
        v:SetNWInt("MediumPossessingPower", 0)
        timer.Remove(v:Nick() .. "MediumPossessingPower")
        timer.Remove(v:Nick() .. "MediumPossessingSpectate")
    end
    deadMediums = {}
end)

local function ResetPlayer(ply)
    -- If this player is haunting someone else, make sure to clear them of the haunt too
    if ply:GetNWBool("MediumHaunting", false) then
        local sid = ply:GetNWString("MediumHauntingTarget", nil)
        if sid then
            local target = player.GetBySteamID64(sid)
            if IsPlayer(target) then
                target:SetNWBool("MediumHaunted", false)
            end
        end
    end
    ply:SetNWBool("MediumHaunting", false)
    ply:SetNWString("MediumHauntingTarget", nil)
    ply:SetNWBool("MediumPossessing", false)
    ply:SetNWInt("MediumPossessingPower", 0)
    timer.Remove(ply:Nick() .. "MediumPossessingPower")
    timer.Remove(ply:Nick() .. "MediumPossessingSpectate")
end

hook.Add("TTTPlayerRoleChanged", "EnhancedMedium_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_MEDIUM and oldRole ~= newRole then
        ResetPlayer(ply)
    end
end)

hook.Add("TTTPlayerSpawnForRound", "EnhancedMedium_TTTPlayerSpawnForRound", function(ply, dead_only)
    ResetPlayer(ply)
end)

-- Un-haunt the device owner if they used their device on the medium
hook.Add("TTTPlayerRoleChangedByItem", "EnhancedMedium_TTTPlayerRoleChangedByItem", function(ply, tgt, itme)
    if tgt:IsMedium() and tgt:GetNWString("MediumHauntingTarget", nil) == ply:SteamID64() then
        ply:SetNWBool("MediumHaunted", false)
    end
end)

-- Hide the role of the player that killed the medium if haunting is enabled
hook.Add("TTTDeathNotifyOverride", "EnhancedMedium_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(inflictor) or not IsValid(attacker) then return end
    if not attacker:IsPlayer() then return end
    if victim == attacker then return end
    if not victim:IsMedium() then return end
    if not medium_killer_haunt:GetBool() then return end

    return reason, killerName, ROLE_NONE
end)

hook.Add("PlayerDeath", "EnhancedMedium_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if valid_kill and victim:IsMedium() then
        local attacker_alive = attacker:Alive() and not attacker:IsSpec()
        local will_posses = medium_killer_haunt:GetBool() and not victim:IsZombifying() and attacker_alive

        local loverSID = ""
        if medium_haunt_saves_lover:GetBool() and will_posses then
            loverSID = victim:GetNWString("TTTCupidLover", "")
        end

        if medium_announce_death:GetBool() then
            for _, v in PlayerIterator() do
                if v ~= attacker and v:IsDetectiveLike() and v:Alive() and not v:IsSpec() and v:SteamID64() ~= loverSID then
                    v:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " has been killed.")
                end
            end
        end

        if victim:IsZombifying() then return end

        if not attacker_alive then
            victim:QueueMessage(MSG_PRINTBOTH, "Your attacker is already dead so you have nobody to haunt.")
            return
        end

        attacker:SetNWBool("MediumHaunted", true)
        victim:SetNWBool("MediumHaunting", true)
        victim:SetNWString("MediumHauntingTarget", attacker:SteamID64())

        if will_posses then
            victim:SetNWBool("MediumPossessing", true)
            victim:SetNWInt("MediumPossessingPower", 0)
            timer.Create(victim:Nick() .. "MediumPossessingPower", 1, 0, function()
                -- If haunting without a body is disabled, check to make sure the body exists still
                if not medium_killer_haunt_without_body:GetBool() then
                    local mediumBody = victim.server_ragdoll or victim:GetRagdollEntity()
                    if not IsValid(mediumBody) then
                        timer.Remove(victim:Nick() .. "MediumPossessingPower")
                        timer.Remove(victim:Nick() .. "MediumPossessingSpectate")
                        attacker:SetNWBool("MediumHaunted", false)
                        victim:SetNWBool("MediumHaunting", false)
                        victim:SetNWString("MediumHauntingTarget", nil)
                        victim:SetNWBool("MediumPossessing", false)
                        victim:SetNWInt("MediumPossessingPower", 0)

                        victim:QueueMessage(MSG_PRINTBOTH, "Your body has been destroyed, removing your tether to the world.")

                        if medium_haunt_saves_lover:GetBool() and loverSID ~= "" then
                            local lover = player.GetBySteamID64(loverSID)
                            lover:PrintMessage(HUD_PRINTTALK, "Your lover's body was destroyed!")
                        end
                        return
                    end
                end

                -- Make sure the victim is still in the correct spectate mode
                local spec_mode = victim:GetObserverMode()
                if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                    victim:Spectate(OBS_MODE_CHASE)
                end

                local power = victim:GetNWInt("MediumPossessingPower", 0)
                local power_rate = medium_killer_haunt_power_rate:GetInt()
                local new_power = math.Clamp(power + power_rate, 0, medium_killer_haunt_power_max:GetInt())
                victim:SetNWInt("MediumPossessingPower", new_power)
            end)

            -- Lock the victim's view on their attacker
            timer.Create(victim:Nick() .. "MediumPossessingSpectate", 1, 1, function()
                victim:SetRagdollSpec(false)
                victim:Spectate(OBS_MODE_CHASE)
                victim:SpectateEntity(attacker)
            end)
        end

        attacker:QueueMessage(MSG_PRINTCENTER, "You have been haunted.")
        victim:QueueMessage(MSG_PRINTCENTER, "Your attacker has been haunted.")

        if loverSID ~= "" then
            local lover = player.GetBySteamID64(loverSID)
            lover:QueueMessage(MSG_PRINTCENTER, "Your lover has died... but they are haunting someone!")
        end

        local sid = victim:SteamID64()
        -- Keep track of how many times this Medium has been killed and by who
        if not deadMediums[sid] then
            deadMediums[sid] = {times = 1, player = victim, attacker = attacker:SteamID64()}
        else
            deadMediums[sid] = {times = deadMediums[sid].times + 1, player = victim, attacker = attacker:SteamID64()}
        end

        net.Start("TTT_PhantomHaunt") -- This is only used for the haunt event which never mentions the phantom by name so we can re-use it
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end
end)

hook.Add("TTTSpectatorHUDKeyPress", "EnhancedMedium_TTTSpectatorHUDKeyPress", function(ply, tgt, powers)
    if ply:GetNWBool("MediumHaunting", false) and IsValid(tgt) and tgt:Alive() and not tgt:IsSpec() then
        powers[IN_ATTACK] = {
            start_command = "+attack",
            end_command = "-attack",
            time = 0.5,
            cost = medium_killer_haunt_attack_cost:GetInt()
        }
        powers[IN_ATTACK2] = {
            start_command = "+menu",
            end_command = "-menu",
            time = 0.2,
            cost = medium_killer_haunt_drop_cost:GetInt()
        }
        powers[IN_FORWARD] = {
            start_command = "+forward",
            end_command = "-forward",
            time = 0.5,
            cost = medium_killer_haunt_move_cost:GetInt()
        }
        powers[IN_BACK] = {
            start_command = "+back",
            end_command = "-back",
            time = 0.5,
            cost = medium_killer_haunt_move_cost:GetInt()
        }
        powers[IN_MOVELEFT] = {
            start_command = "+moveleft",
            end_command = "-moveleft",
            time = 0.5,
            cost = medium_killer_haunt_move_cost:GetInt()
        }
        powers[IN_MOVERIGHT] = {
            start_command = "+moveright",
            end_command = "-moveright",
            time = 0.5,
            cost = medium_killer_haunt_move_cost:GetInt()
        }
        powers[IN_JUMP] = {
            start_command = "+jump",
            end_command = "-jump",
            time = 0.2,
            cost = medium_killer_haunt_jump_cost:GetInt()
        }

        return true, "MediumPossessingPower"
    end
end)

-------------
-- RESPAWN --
-------------

hook.Add("DoPlayerDeath", "EnhancedMedium_DoPlayerDeath", function(ply, attacker, dmginfo)
    if ply:IsSpec() then return end

    if ply:GetNWBool("MediumHaunted", false) then
        local respawning = {}
        local mediumUsers = table.GetKeys(deadMediums)
        for _, key in pairs(mediumUsers) do
            local medium = deadMediums[key]
            if medium.attacker == ply:SteamID64() and IsValid(medium.player) then
                local deadMedium = medium.player
                deadMedium:SetNWBool("MediumHaunting", false)
                deadMedium:SetNWString("MediumHauntingTarget", nil)
                deadMedium:SetNWBool("MediumPossessing", false)
                deadMedium:SetNWInt("MediumPossessingPower", 0)
                timer.Remove(deadMedium:Nick() .. "MediumPossessingPower")
                timer.Remove(deadMedium:Nick() .. "MediumPossessingSpectate")
                if deadMedium:IsMedium() and not deadMedium:Alive() then
                    -- Find the Medium's corpse
                    local mediumBody = deadMedium.server_ragdoll or deadMedium:GetRagdollEntity()
                    if IsValid(mediumBody) then
                        deadMedium:SpawnForRound(true)
                        deadMedium:SetPos(FindRespawnLocation(mediumBody:GetPos()) or mediumBody:GetPos())
                        deadMedium:SetEyeAngles(Angle(0, mediumBody:GetAngles().y, 0))

                        local health = medium_respawn_health:GetInt()
                        if medium_weaker_each_respawn:GetBool() then
                            -- Don't reduce them the first time since 50 is already reduced
                            for _ = 1, medium.times - 1 do
                                health = health / 2
                            end
                            health = math.max(1, math.Round(health))
                        end
                        deadMedium:SetHealth(health)
                        mediumBody:Remove()
                        deadMedium:QueueMessage(MSG_PRINTBOTH, "Your attacker died and you have been respawned.")
                        respawning[deadMedium:SteamID64()] = true
                    else
                        deadMedium:QueueMessage(MSG_PRINTBOTH, "Your attacker died but your body has been destroyed.")
                    end
                end
            end
        end

        local respawnCount = table.Count(respawning)
        if respawnCount > 0 and medium_announce_death:GetBool() then
            for _, v in PlayerIterator() do
                if v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                    if not respawning[v:SteamID64()] then
                        v:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " has been respawned.")
                    elseif respawnCount > 1 then
                        timer.Simple(3, function()
                            v:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " has been respawned.")
                        end)
                    end
                end
            end
        end

        ply:SetNWBool("MediumHaunted", false)
        SendFullStateUpdate()
    end
end)

---------------
-- FOOTSTEPS --
---------------

hook.Add("PlayerFootstep", "EnhancedMedium_PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
    if ply:WaterLevel() ~= 0 then return end
    if not ply:GetNWBool("MediumHaunted", false) then return end

    local killer_footstep_time = medium_killer_footstep_time:GetInt()
    if killer_footstep_time <= 0 then return end

    -- This player killed a Medium. Tell everyone where their foot steps should go
    net.Start("TTT_PlayerFootstep")
        net.WritePlayer(ply)
        net.WriteVector(pos)
        net.WriteAngle(ply:GetAimVector():Angle())
        net.WriteBit(foot)
        net.WriteTable(Color(138, 4, 4))
        net.WriteUInt(killer_footstep_time, 8)
        net.WriteFloat(1) -- Scale
    net.Broadcast()
end)

------------------
-- CUPID LOVERS --
------------------

local function IsMediumHaunting(ply)
    return ply:GetNWBool("MediumHaunting", false) and ply:IsMedium() and not ply:Alive()
end

hook.Add("TTTCupidShouldLoverSurvive", "EnhancedMedium_TTTCupidShouldLoverSurvive", function(ply, lover)
    if medium_haunt_saves_lover:GetBool() and (IsMediumHaunting(ply) or IsMediumHaunting(lover)) then
        return true
    end
end)

hook.Add("PostPlayerDeath", "EnhancedMedium_Lovers_PostPlayerDeath", function(ply)
    local loverSID = ply:GetNWString("TTTCupidLover", "")
    if loverSID == "" then return end

    local lover = player.GetBySteamID64(loverSID)
    if not IsPlayer(lover) then return end

    if IsMediumHaunting(lover) then
        lover:QueueMessage(MSG_PRINTBOTH, "Your lover has died and so you will not survive if you respawn!")
    end
end)

------------------------------
-- EXORCISM DEVICE OVERRIDE --
------------------------------

hook.Add("PreRegisterSWEP", "EnhancedMedium_PreRegisterSWEP", function(SWEP, class)
    if class == "weapon_pha_exorcism" then
        SWEP.DoCleanse = function(weap, ply)
            local owner = weap:GetOwner()
            if IsPlayer(ply) and ply:Alive() and not ply:IsSpec() then
                ply:EmitSound(cured)

                if ply:GetNWBool("PhantomHaunted", false) then
                    for _, v in PlayerIterator() do
                        if v:GetNWString("PhantomHauntingTarget", "") == ply:SteamID64() then
                            ply:SetNWBool("PhantomHaunted", false)
                            v:SetNWBool("PhantomHaunting", false)
                            v:SetNWString("PhantomHauntingTarget", nil)
                            v:SetNWBool("PhantomPossessing", false)
                            v:SetNWInt("PhantomPossessingPower", 0)
                            timer.Remove(v:Nick() .. "PhantomPossessingPower")
                            timer.Remove(v:Nick() .. "PhantomPossessingSpectate")
                            v:QueueMessage(MSG_PRINTCENTER, "Your spirit has been cleansed from your target.")

                            if GetConVar("ttt_phantom_haunt_saves_lover"):GetBool() then
                                local loverSID = v:GetNWString("TTTCupidLover", "")
                                if loverSID ~= "" then
                                    local lover = player.GetBySteamID64(loverSID)
                                    lover:QueueMessage(MSG_PRINTTALK, "Your lover was exorcised from their host!")
                                end
                            end
                        end
                    end
                end

                if ply:GetNWBool("MediumHaunted", false) then
                    for _, v in PlayerIterator() do
                        if v:GetNWString("MediumHauntingTarget", "") == ply:SteamID64() then
                            ply:SetNWBool("MediumHaunted", false)
                            v:SetNWBool("MediumHaunting", false)
                            v:SetNWString("MediumHauntingTarget", nil)
                            v:SetNWBool("MediumPossessing", false)
                            v:SetNWInt("MediumPossessingPower", 0)
                            timer.Remove(v:Nick() .. "MediumPossessingPower")
                            timer.Remove(v:Nick() .. "MediumPossessingSpectate")
                            v:QueueMessage(MSG_PRINTCENTER, "Your spirit has been cleansed from your target.")

                            if medium_haunt_saves_lover:GetBool() then
                                local loverSID = v:GetNWString("TTTCupidLover", "")
                                if loverSID ~= "" then
                                    local lover = player.GetBySteamID64(loverSID)
                                    lover:QueueMessage(MSG_PRINTTALK, "Your lover was exorcised from their host!")
                                end
                            end
                        end
                    end
                end

                weap:Remove()
            else
                if ply == owner then
                    weap:SetNextSecondaryFire(CurTime() + 1)
                else
                    weap:SetNextPrimaryFire(CurTime() + 1)
                end
            end
        end
    end
end)