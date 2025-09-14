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
function ns.PrintTitle(...)
    print("|cfff4444f Entei |cf334fd9fMageTracker|r", ...)
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
        ns.PrintTitle(...)
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


local ns = select(2, ...)

local function ScanUnitBuffs(unit)
  local i = 1
  while true do
    local name, _, _, _, duration, expires, caster = UnitBuff(unit, i)
    if not name then break end

    local buffData = {
      unit     = unit,
      name     = name,
      duration = duration,
      expires  = expires,
      caster   = caster,
    }

    -- quick map access
    if name == "Mage Armor" or name == "Ice Armor" or name == "Frost Armor" then
      ns.state.buffs[unit .. ":Armor"] = buffData
    else
      ns.state.buffs[unit .. ":" .. name] = buffData
    end

    -- array access
    table.insert(ns.state.buffList, buffData)
    i = i + 1
  end
end

function ns.UpdateAllBuffs()
  ns.state.buffList = {}
  ScanUnitBuffs("player")
  for i = 1, GetNumGroupMembers() do
    local unit = (IsInRaid() and "raid" .. i) or "party" .. i
    if UnitExists(unit) then
      ScanUnitBuffs(unit)
    end
  end
end

local ns = select(2, ...)

-- Track runes etc
local REAGENTS = {
  RuneOfTeleportation = 17031,
  RuneOfPortals       = 17032,
}

function ns.UpdateReagents()
  for name, id in pairs(REAGENTS) do
    local count = GetItemCount(id)
    ns.state.reagents[name] = count
  end
end


local ns = select(2, ...)

-- Tracked spells
ns.SPELLS = {
  Polymorph    = 118,
  FrostNova    = 122,
  Counterspell = 2139,
  Blink        = 1953,
  Evocation    = 12051,
  ArcaneIntellect = 10157,
}

function ns.UpdateCooldowns()
  for name, id in pairs(ns.SPELLS) do
    local start, duration, enabled = GetSpellCooldown(id)
    ns.state.cooldowns[name] = { start=start, duration=duration, enabled=enabled }
  end
end


local ns = select(2, ...)
local state, SPELLS = ns.state, ns.SPELLS

local frame

-- Create icon button with tooltip and real spell texture
local function CreateIcon(name, spellID, parent, x, y)
    local b = CreateFrame("Button", "MageTracker" .. name, parent, "SecureActionButtonTemplate")
    b:SetSize(32, 32)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)

    -- Use the spell's actual icon if available
    local texture = GetSpellTexture(spellID)
    if texture then
        b.icon:SetTexture(texture)
    else
        b.icon:SetTexture(0.8, 0.2, 0.8, 1) -- fallback color
    end

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return b
end

-- Attach a cooldown swipe frame to a button
local function AttachCooldown(btn)
    if not btn.cooldown then
        btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints(btn)
    end
    return btn.cooldown
end

-- Attach a FontString overlay for numeric cooldown
local function AttachText(btn)
    if not btn.text then
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER", btn, "CENTER")
    end
    return btn.text
end

-- Initialize the main UI frame
function ns.InitializeUI()
    frame = CreateFrame("Frame", "MageTrackerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(250, 180)
    frame:SetPoint("TOPLEFT", 10, -10)

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(true)
    frame.bg:SetColorTexture(0, 0, 0, 0.5)

    -- Spell icons
    frame.icons = {}
    frame.icons.Polymorph    = CreateIcon("Polymorph", SPELLS.Polymorph, frame, 6, -6)
    frame.icons.FrostNova    = CreateIcon("FrostNova", SPELLS.FrostNova, frame, 44, -6)
    frame.icons.Counterspell = CreateIcon("Counterspell", SPELLS.Counterspell, frame, 82, -6)
    frame.icons.Blink        = CreateIcon("Blink", SPELLS.Blink, frame, 120, -6)
    frame.icons.Evocation    = CreateIcon("Evocation", SPELLS.Evocation, frame, 158, -6)
    frame.icons.ArcaneIntellect = CreateIcon("ArcaneIntellect", SPELLS.ArcaneIntellect, frame, 200, -6)

    
    frame.portalIcons = {}


    -- Buff text
    frame.armorText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.armorText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -46)
    frame.armorText:SetText("Armor: None")

    -- Reagents text
    frame.reagentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.reagentText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -64)
    frame.reagentText:SetText("Runes: 0")

    frame.teleportButtons = {}
    local teleportSpells = {
      {name = "Orgrimmar", spellID = 3567},
      {name = "Undercity", spellID = 3563},
      {name = "Thunder Bluff", spellID = 3566}}

    local startX, startY = 8, -82
    local spacing = 38

    for i, info in ipairs(teleportSpells) do
        local btn = CreateFrame("Button", "MageTrackerPortal"..info.name, frame, "SecureActionButtonTemplate")
        btn:SetSize(32,32)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", startX + (i-1)*spacing, startY)
    
        -- Icon texture
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints(btn)
        local tex = GetSpellTexture(info.spellID)
        if tex then btn.icon:SetTexture(tex) else btn.icon:SetTexture(0.2,0.2,0.8,1) end
    
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(info.spellID)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
      
        -- Click to cast
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", info.spellID)
      
        frame.teleportButtons[info.name] = btn
    end

    frame.portalButtons = {}
    local portalSpells = {
      {name="Orgrimmar", spellID=11417},
      {name="Thunder Bluff", spellID=11418},
      {name="Undercity", spellID=11420},    
    }


    local startX, startY = 6, -124
    local spacing = 38

    for i, info in ipairs(portalSpells) do
        local btn = CreateFrame("Button", "MageTrackerPortal"..info.name, frame, "SecureActionButtonTemplate")
        btn:SetSize(32,32)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", startX + (i-1)*spacing, startY)
    
        -- Icon texture
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints(btn)
        local tex = GetSpellTexture(info.spellID)
        if tex then btn.icon:SetTexture(tex) else btn.icon:SetTexture(0.2,0.2,0.8,1) end
    
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(info.spellID)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
      
        -- Click to cast
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", info.spellID)
      
        frame.portalButtons[info.name] = btn
    end
end

-- Refresh UI: spells, buffs, reagents
function ns.RefreshUI()
    if not frame then return end
-- Utility to scan buffs by spellID
local function FindBuff(unit, spellID)
  local i = 1
  while true do
      local name, icon, count, debuffType, duration, expirationTime, caster, 
            isStealable, shouldConsolidate, sid = UnitBuff(unit, i)
      if not name then break end -- no more buffs
      if sid == spellID then
          return name, icon, duration, expirationTime, sid
      end
      i = i + 1
  end
end

-- Arcane Intellect tracker (self + party)
do
  local btn = frame.icons.ArcaneIntellect
  if btn then
      local found, duration, expirationTime, texture

      -- Check yourself first
      local name, icon, dur, exp, sid = FindBuff("player", SPELLS.ArcaneIntellect)
      if name then
          found, duration, expirationTime, texture = true, dur, exp, icon
      else
          -- Check party members
          for i = 1, GetNumGroupMembers() do
              local unit = "party" .. i
              if UnitExists(unit) then
                  local pname, picon, pdur, pexp, psid = FindBuff(unit, SPELLS.ArcaneIntellect)
                  if pname then
                      found, duration, expirationTime, texture = true, pdur, pexp, picon
                      break
                  end
              end
          end
      end

      if found and duration and expirationTime then
          local remaining = expirationTime - ns.Now()

          btn.icon:SetTexture(texture or GetSpellTexture(SPELLS.ArcaneIntellect))
          local text = AttachText(btn)
          text:SetText(string.format("%.0f", remaining))

          local cdFrame = AttachCooldown(btn)
          cdFrame:SetCooldown(expirationTime - duration, duration)
          cdFrame:Show()

          btn.icon:SetAlpha(1)
      else
          btn.icon:SetTexture(GetSpellTexture(SPELLS.ArcaneIntellect))
          if btn.text then btn.text:SetText("") end
          if btn.cooldown then btn.cooldown:Hide() end
          btn.icon:SetAlpha(0.3)
      end
  end
end


    -- Spells
    for k, spellID in pairs(SPELLS) do
        local btn = frame.icons[k]
        if btn then
            local cd = state.cooldowns[k]
            local cooldownFrame = AttachCooldown(btn)
            local text = AttachText(btn)

            if cd and cd.duration and cd.duration > 0 then
                local expires = cd.start + cd.duration
                local remaining = expires - ns.Now()
                if remaining > 0 then
                    cooldownFrame:SetCooldown(cd.start, cd.duration)
                    cooldownFrame:Show()
                    btn.icon:SetAlpha(0.6)
                    text:SetText(string.format("%.0f", remaining))
                else
                    cooldownFrame:Hide()
                    btn.icon:SetAlpha(1)
                    text:SetText("")
                end
            else
                cooldownFrame:Hide()
                btn.icon:SetAlpha(1)
                text:SetText("")
            end
        end
    end

    -- Buffs
    if state.buffs["player:Armor"] then
        frame.armorText:SetText("Armor: " .. (state.buffs["player:Armor"].name or "None"))
    else
        frame.armorText:SetText("Armor: None")
    end

    -- Reagents
    frame.reagentText:SetText("Runes: " .. (state.reagents.RuneOfPortals or 0))
end
