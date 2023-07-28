AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_tracker_blind_time", "5", FCVAR_REPLICATED, "The number of seconds to blind the Tracker's killer. Set to 0 to disable.", 0, 100)

table.insert(ROLE_CONVARS[ROLE_TRACKER], {
    cvar = "ttt_tracker_blind_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})