-- core.lua
local addonName, ns = ...
local state = ns.state or {}

-- Initialize all state subtables safely
state.cooldowns = state.cooldowns or {}
state.buffs = state.buffs or {}
state.buffList = state.buffList or {}
state.reagents = state.reagents or {}
ns.state = state

-- Helper for current time
function ns.Now()
    return GetTime()
end

-- Safe print for debugging
function ns.Print(...)
    print("|cff69ccf0[MageTracker]|r", ...)
end

-- Flag to ensure UI is initialized only once
ns.InitializeUIDone = ns.InitializeUIDone or false

-- Main event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")

f:SetScript("OnEvent", function(_, event, arg1, ...)
    -- First run: PLAYER_LOGIN initializes the UI
    if event == "PLAYER_LOGIN" and not ns.InitializeUIDone then
        ns.InitializeUI()           -- create frame and all UI elements
        ns.InitializeUIDone = true

        ns.UpdateAllBuffs()        -- scan player + party buffs
        ns.UpdateReagents()        -- count runes and other items
        ns.UpdateCooldowns()       -- scan tracked spell cooldowns
        ns.RefreshUI()             -- draw initial state
        return
    end

    -- Prevent updates if UI not yet created
    if not ns.InitializeUIDone then return end

    -- Update buffs
    if event == "UNIT_AURA" and arg1 then
        ns.UpdateAllBuffs()
        ns.RefreshUI()
    -- Update reagents
    elseif event == "BAG_UPDATE" then
        ns.UpdateReagents()
        ns.RefreshUI()
    -- Update spell cooldowns
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        ns.UpdateCooldowns()
        ns.RefreshUI()
    end
end)
