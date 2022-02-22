if SERVER then AddCSLuaFile() end

if CLIENT then
    ------------
    -- CLIENT --
    ------------

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
        local current_power = cli:GetNWInt("HauntingPower", 0)

        HUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
    end)

    -- Haunting Smoke
    hook.Add("TTTShouldPlayerSmoke", "EnhancedMedium_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
        if v:GetNWBool("Haunted", false) and GetGlobalBool("ttt_medium_killer_smoke", false) then
            return true
        end
    end)
else
    ------------
    -- SERVER --
    ------------

    -- ConVars
    local medium_respawn_health = CreateConVar("ttt_medium_respawn_health", "50")
    local medium_weaker_each_respawn = CreateConVar("ttt_medium_weaker_each_respawn", "0")
    local medium_announce_death = CreateConVar("ttt_medium_announce_death", "0")
    local medium_killer_smoke = CreateConVar("ttt_medium_killer_smoke", "0")
    local medium_killer_footstep_time = CreateConVar("ttt_medium_killer_footstep_time", "0")
    local medium_killer_haunt = CreateConVar("ttt_medium_killer_haunt", "1")
    local medium_killer_haunt_power_max = CreateConVar("ttt_medium_killer_haunt_power_max", "100")
    local medium_killer_haunt_power_rate = CreateConVar("ttt_medium_killer_haunt_power_rate", "10")
    local medium_killer_haunt_move_cost = CreateConVar("ttt_medium_killer_haunt_move_cost", "25")
    local medium_killer_haunt_jump_cost = CreateConVar("ttt_medium_killer_haunt_jump_cost", "50")
    local medium_killer_haunt_drop_cost = CreateConVar("ttt_medium_killer_haunt_drop_cost", "75")
    local medium_killer_haunt_attack_cost = CreateConVar("ttt_medium_killer_haunt_attack_cost", "100")
    local medium_killer_haunt_without_body = CreateConVar("ttt_medium_killer_haunt_without_body", "1")

    -- Globals
    hook.Add("TTTSyncGlobals", "EnhancedMedium_TTTSyncGlobals", function()
        SetGlobalBool("ttt_medium_killer_smoke", medium_killer_smoke:GetBool())
        SetGlobalBool("ttt_medium_killer_haunt", medium_killer_haunt:GetBool())
        SetGlobalInt("ttt_medium_killer_haunt_power_max", medium_killer_haunt_power_max:GetInt())
        SetGlobalInt("ttt_medium_killer_haunt_move_cost", medium_killer_haunt_move_cost:GetInt())
        SetGlobalInt("ttt_medium_killer_haunt_attack_cost", medium_killer_haunt_attack_cost:GetInt())
        SetGlobalInt("ttt_medium_killer_haunt_jump_cost", medium_killer_haunt_jump_cost:GetInt())
        SetGlobalInt("ttt_medium_killer_haunt_drop_cost", medium_killer_haunt_drop_cost:GetInt())
    end)

    -- Haunting
    local deadMediums = {}
    hook.Add("TTTPrepareRound", "EnhancedMedium_TTTPrepareRound", function()
        for _, v in pairs(player.GetAll()) do
            v:SetNWBool("Haunted", false)
            v:SetNWBool("Haunting", false)
            v:SetNWString("HauntingTarget", nil)
            v:SetNWInt("HauntingPower", 0)
            timer.Remove(v:Nick() .. "HauntingPower")
            timer.Remove(v:Nick() .. "HauntingSpectate")
        end
        deadMediums = {}
    end)

    local function ResetPlayer(ply)
        -- If this player is haunting someone else, make sure to clear them of the haunt too
        if ply:GetNWBool("Haunting", false) then
            local sid = ply:GetNWString("HauntingTarget", nil)
            if sid then
                local target = player.GetBySteamID64(sid)
                if IsPlayer(target) then
                    target:SetNWBool("Haunted", false)
                end
            end
        end
        ply:SetNWBool("Haunting", false)
        ply:SetNWString("HauntingTarget", nil)
        ply:SetNWInt("HauntingPower", 0)
        timer.Remove(ply:Nick() .. "HauntingPower")
        timer.Remove(ply:Nick() .. "HauntingSpectate")
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
    hook.Add("TTTPlayerDefibRoleChange", "EnhancedMedium_TTTPlayerDefibRoleChange", function(ply, tgt)
        if tgt:IsMedium() and tgt:GetNWString("HauntingTarget", nil) == ply:SteamID64() then
            ply:SetNWBool("Haunted", false)
        end
    end)

    hook.Add("PlayerDeath", "EnhancedMedium_PlayerDeath", function(victim, infl, attacker)
        local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
        if valid_kill and victim:IsMedium() and not victim:GetNWBool("IsZombifying", false) then
            attacker:SetNWBool("Haunted", true)

            if medium_killer_haunt:GetBool() then
                victim:SetNWBool("Haunting", true)
                victim:SetNWString("HauntingTarget", attacker:SteamID64())
                victim:SetNWInt("HauntingPower", 0)
                timer.Create(victim:Nick() .. "HauntingPower", 1, 0, function()
                    -- If haunting without a body is disabled, check to make sure the body exists still
                    if not medium_killer_haunt_without_body:GetBool() then
                        local mediumBody = victim.server_ragdoll or victim:GetRagdollEntity()
                        if not IsValid(mediumBody) then
                            timer.Remove(victim:Nick() .. "HauntingPower")
                            timer.Remove(victim:Nick() .. "HauntingSpectate")
                            attacker:SetNWBool("Haunted", false)
                            victim:SetNWBool("Haunting", false)
                            victim:SetNWString("HauntingTarget", nil)
                            victim:SetNWInt("HauntingPower", 0)

                            victim:PrintMessage(HUD_PRINTCENTER, "Your body has been destroyed, removing your tether to the world.")
                            victim:PrintMessage(HUD_PRINTTALK, "Your body has been destroyed, removing your tether to the world.")
                            return
                        end
                    end

                    -- Make sure the victim is still in the correct spectate mode
                    local spec_mode = victim:GetObserverMode()
                    if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                        victim:Spectate(OBS_MODE_CHASE)
                    end

                    local power = victim:GetNWInt("HauntingPower", 0)
                    local power_rate = medium_killer_haunt_power_rate:GetInt()
                    local new_power = math.Clamp(power + power_rate, 0, medium_killer_haunt_power_max:GetInt())
                    victim:SetNWInt("HauntingPower", new_power)
                end)

                -- Lock the victim's view on their attacker
                timer.Create(victim:Nick() .. "HauntingSpectate", 1, 1, function()
                    victim:SetRagdollSpec(false)
                    victim:Spectate(OBS_MODE_CHASE)
                    victim:SpectateEntity(attacker)
                end)
            end

            -- Delay this message so the player can see the target update message
            if attacker:ShouldDelayAnnouncements() then
                timer.Simple(3, function()
                    attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
                end)
            else
                attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
            end
            victim:PrintMessage(HUD_PRINTCENTER, "Your attacker has been haunted.")
            if medium_announce_death:GetBool() then
                for _, v in pairs(player.GetAll()) do
                    if v ~= attacker and v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                        v:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " has been killed.")
                    end
                end
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
        if ply:GetNWBool("Haunting", false) and IsValid(tgt) and tgt:Alive() and not tgt:IsSpec() then
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

            return true, "HauntingPower"
        end
    end)
    
    -- Respawn
    hook.Add("DoPlayerDeath", "EnhancedMedium_DoPlayerDeath", function(ply, attacker, dmginfo)
        if ply:IsSpec() then return end

        if ply:GetNWBool("Haunted", false) then
            local respawn = false
            local mediumUsers = table.GetKeys(deadMediums)
            for _, key in pairs(mediumUsers) do
                local medium = deadMediums[key]
                if medium.attacker == ply:SteamID64() and IsValid(medium.player) then
                    local deadMedium = medium.player
                    deadMedium:SetNWBool("Haunting", false)
                    deadMedium:SetNWString("HauntingTarget", nil)
                    deadMedium:SetNWInt("HauntingPower", 0)
                    timer.Remove(deadMedium:Nick() .. "HauntingPower")
                    timer.Remove(deadMedium:Nick() .. "HauntingSpectate")
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
                            deadMedium:PrintMessage(HUD_PRINTCENTER, "Your attacker died and you have been respawned.")
                            deadMedium:PrintMessage(HUD_PRINTTALK, "Your attacker died and you have been respawned.")
                            respawn = true
                        else
                            deadMedium:PrintMessage(HUD_PRINTCENTER, "Your attacker died but your body has been destroyed.")
                            deadMedium:PrintMessage(HUD_PRINTTALK, "Your attacker died but your body has been destroyed.")
                        end
                    end
                end
            end

            if respawn and medium_announce_death:GetBool() then
                for _, v in pairs(GetAllPlayers()) do
                    if v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                        v:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " has been respawned.")
                    end
                end
            end

            ply:SetNWBool("Haunted", false)
            SendFullStateUpdate()
        end
    end)
    
    -- Footsteps
    hook.Add("PlayerFootstep", "EnhancedMedium_PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
        if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
        if ply:WaterLevel() ~= 0 then return end
        if not ply:GetNWBool("Haunted", false) then return end

        local killer_footstep_time = medium_killer_footstep_time:GetInt()
        if killer_footstep_time <= 0 then return end

        -- This player killed a Medium. Tell everyone where their foot steps should go
        net.Start("TTT_PlayerFootstep")
        net.WriteEntity(ply)
        net.WriteVector(pos)
        net.WriteAngle(ply:GetAimVector():Angle())
        net.WriteBit(foot)
        net.WriteTable(Color(138, 4, 4))
        net.WriteUInt(killer_footstep_time, 8)
        net.Broadcast()
    end)
end

------------
-- SHARED --
------------

-- Should show spectator hud
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_MEDIUM] = function(ply)
    if ply:GetNWBool("Haunting") then
        return true
    end
end