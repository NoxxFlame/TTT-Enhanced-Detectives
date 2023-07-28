AddCSLuaFile()

-- Should show spectator hud
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_MEDIUM] = function(ply)
    if ply:GetNWBool("MediumPossessing") then
        return true
    end
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_medium_killer_smoke", "0", FCVAR_REPLICATED)
CreateConVar("ttt_medium_killer_haunt", "1", FCVAR_REPLICATED)
CreateConVar("ttt_medium_killer_haunt_power_max", "100", FCVAR_REPLICATED, "The maximum amount of power a medium can have when haunting their killer", 1, 200)
CreateConVar("ttt_medium_killer_haunt_move_cost", "25", FCVAR_REPLICATED, "The amount of power to spend when a medium is moving their killer via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_medium_killer_haunt_jump_cost", "50", FCVAR_REPLICATED, "The amount of power to spend when a medium is making their killer jump via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_medium_killer_haunt_drop_cost", "75", FCVAR_REPLICATED, "The amount of power to spend when a medium is making their killer drop their weapon via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_medium_killer_haunt_attack_cost", "100", FCVAR_REPLICATED, "The amount of power to spend when a medium is making their killer attack via a haunting. Set to 0 to disable", 0, 100)

table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_weaker_each_respawn",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_announce_death",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_smoke",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_footstep_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_power_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_power_rate",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_move_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_jump_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_drop_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_attack_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_killer_haunt_without_body",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_haunt_saves_lover",
    type = ROLE_CONVAR_TYPE_BOOL
})