AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_paladin_explosion_protect_self", "1", FCVAR_REPLICATED)

table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_explosion_immune",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_explosion_protect_self",
    type = ROLE_CONVAR_TYPE_BOOL
})