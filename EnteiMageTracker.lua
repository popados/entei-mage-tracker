-- Entei's Mage Tracker - Lua stub for WoW Classic
-- File: EnteisMageTracker.lua
-- Minimal, modular skeleton to get you started. Fill in spell IDs/names and polish UI as needed.

local addonName = "EnteiMageTracker"
local Entei = {}
_G[addonName] = Entei

----------------------------------------------------------------
-- Defaults / SavedVariables
----------------------------------------------------------------
local defaults = {
  profile = {
    enabled = true,
    showCooldowns = true,
    showBuffs = true,
    showConsumables = true,
    travelTab = true,
    scale = 1.0,
    pos = { x = 100, y = -100 },
    thresholds = { reagents = 5, food = 2 },
    trackedSpells = {
      FrostNova = true,
      Counterspell = true,
      Blink = true,
      Evocation = true,
    }
  }
}

-- SavedVariables placeholder (declare in TOC: ## SavedVariables: EnteisMTDB)
Entei.db = nil -- will be set on PLAYER_LOGIN

----------------------------------------------------------------
-- Local helper lists (fill spell IDs or names appropriate for Classic)
----------------------------------------------------------------
local SPELLS = {
  FrostNova = { id = 122, name = "Frost Nova" },
  Counterspell = { id = 2139, name = "Counterspell" },
  Blink = { id = 1953, name = "Blink" },
  Evocation = { id = 12051, name = "Evocation" },
}

local PORTAL_REAGENTS = {
  -- itemIDs for rune/reagent names (example placeholders)
  RuneOfPortals = 17031, -- example
}

----------------------------------------------------------------
-- Frame / Event handling
----------------------------------------------------------------
local frame = CreateFrame("Frame", addonName .. "Frame", UIParent)
frame:SetSize(200, 120)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", defaults.profile.pos.x, defaults.profile.pos.y)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) if Entei.db.profile.locked ~= true then self:StartMoving() end end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Simple backdrop to see the frame; remove/skin in final UI
frame.bg = CreateFrame("Frame", nil, frame)
frame.bg:SetAllPoints(frame)
frame.bg.texture = frame.bg:CreateTexture(nil, "BACKGROUND")
frame.bg.texture:SetAllPoints(frame.bg)
frame.bg.texture:SetTexture(0,0,0,0.4)

-- event registration
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- left combat
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- entered combat

----------------------------------------------------------------
-- Internal state
----------------------------------------------------------------
local state = {
  cooldowns = {}, -- [spellName] = {start, duration, enabled}
  buffs = {}, -- [unit or name] = expiry
  reagents = {},
  lastUpdate = 0,
  updateInterval = 0.2,
}

----------------------------------------------------------------
-- Utility functions
----------------------------------------------------------------
local function Now()
  return GetTime()
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff4bf5ff[EnteiMT]|r " .. tostring(msg))
end

----------------------------------------------------------------
-- Cooldown tracking
----------------------------------------------------------------
local function UpdateSpellCooldown(spellKey)
  local s = SPELLS[spellKey]
  if not s then return end

  -- Prefer using spellID where possible; fallback to name-based lookup
  local start, duration, enabled = 0, 0, 0
  if s.id then
    start, duration, enabled = GetSpellCooldown(s.id)
  else
    start, duration, enabled = GetSpellCooldown(s.name)
  end

  if duration and duration > 1.5 then
    state.cooldowns[spellKey] = { start = start, duration = duration, enabled = enabled }
  else
    state.cooldowns[spellKey] = nil
  end
end

local function UpdateAllCooldowns()
  for k, v in pairs(SPELLS) do
    if Entei.db.profile.trackedSpells[k] then
      UpdateSpellCooldown(k)
    end
  end
end

----------------------------------------------------------------
-- Buff tracking (self + party)
----------------------------------------------------------------
local function ScanUnitBuffs(unit)
  local i = 1
  while true do
    local name, _, count, dtype, duration, expires, caster, _, _, spellId = UnitBuff(unit, i)
    if not name then break end
    -- Track Arcane Intellect / Brilliance for party members
    if name == "Arcane Intellect" or name == "Brilliance" then
      state.buffs[unit .. ":ArcaneIntellect"] = { expires = expires, duration = duration }
    end
    -- Track wards, armor, etc. for self
    if unit == "player" then
      if name == "Mage Armor" or name == "Frost Armor" or name == "Fire Armor" then
        state.buffs["player:Armor"] = { name = name, expires = expires }
      elseif name == "Ice Barrier" or name == "Mana Shield" then
        state.buffs[name] = { expires = expires }
      end
    end
    i = i + 1
  end
end

local function UpdateAllBuffs()
  -- Player
  ScanUnitBuffs("player")
  -- Party
  for i = 1, GetNumGroupMembers() do
    local unit = (IsInRaid() and ("raid" .. i)) or ("party" .. i)
    if UnitExists(unit) then ScanUnitBuffs(unit) end
  end
end

----------------------------------------------------------------
-- Consumables & Reagents
----------------------------------------------------------------
local function UpdateConsumables()
  -- Example: count conjured food/water by itemID or name
  -- Use GetItemCount for reagent tracking
  if PORTAL_REAGENTS.RuneOfPortals then
    local count = GetItemCount(PORTAL_REAGENTS.RuneOfPortals, false, false)
    state.reagents.RuneOfPortals = count
  end

  -- Add checks for conjured Water/Conjured Bread by item name or itemId
end

----------------------------------------------------------------
-- UI Update / Drawing (very basic placeholder)
----------------------------------------------------------------
local function CreateIcon(name, parent, x, y)
  local b = CreateFrame("Button", addonName .. name, parent, "SecureActionButtonTemplate")
  b:SetSize(32,32)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints(b)
  b.icon:SetTexture(0.2,0.2,0.8,1)
  b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(name); GameTooltip:Show() end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

-- simple container for icons
frame.icons = {}
frame.icons.frost = CreateIcon("FrostNova", frame, 6, -6)
frame.icons.counter = CreateIcon("Counterspell", frame, 44, -6)
frame.icons.blink = CreateIcon("Blink", frame, 82, -6)
frame.icons.evocation = CreateIcon("Evocation", frame, 120, -6)

local function AttachCooldown(btn)
  if not btn.cooldown then
    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
  end
  return btn.cooldown
end

local function AttachText(btn)
  if not btn.text then
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER", btn, "CENTER")
  end
  return btn.text
end

local function RefreshUI()
  for k, cfg in pairs(SPELLS) do
    local btn = frame.icons[string.lower(k)]
    if btn then
      local cd = state.cooldowns[k]
      local cooldownFrame = AttachCooldown(btn)
      local text = AttachText(btn)

      if cd and cd.duration and cd.duration > 0 then
        local expires = cd.start + cd.duration
        local remaining = expires - Now()
        if remaining > 0 then
          cooldownFrame:SetCooldown(cd.start, cd.duration)
          btn.icon:SetAlpha(0.6)
          text:SetText(string.format("%.0f", remaining))
        else
          cooldownFrame:Clear()
          btn.icon:SetAlpha(1)
          text:SetText("")
        end
      else
        cooldownFrame:Clear()
        btn.icon:SetAlpha(1)
        text:SetText("")
      end
    end
  end
end

-- during frame setup (after creating frame.bg, icons, etc.)
frame.armorText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.armorText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -46)
if state.buffs["player:Armor"] then
  frame.armorText:SetText("Armor: " .. (state.buffs["player:Armor"].name or "None"))
else
  frame.armorText:SetText("Armor: None")
end

frame.reagentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.reagentText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -64)
frame.reagentText:SetText("Runes: 0")


----------------------------------------------------------------
-- Main OnUpdate loop (throttled)
----------------------------------------------------------------
frame:SetScript("OnUpdate", function(self, elapsed)
  state.lastUpdate = state.lastUpdate + elapsed
  if state.lastUpdate < state.updateInterval then return end
  state.lastUpdate = 0

  -- periodic checks
  UpdateAllCooldowns()
  UpdateAllBuffs()
  UpdateConsumables()
  RefreshUI()
end)

----------------------------------------------------------------
-- Event Handler (lighter duties; heavy scanning is done in OnUpdate)
----------------------------------------------------------------
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    -- load DB
    if not EnteiDB then EnteiDB = {} end
    Entei.db = EnteiDB
    Entei.db.profile = Entei.db.profile or defaults.profile
    Print("loaded. Use /enteimt to toggle or open options.")
  elseif event == "SPELL_UPDATE_COOLDOWN" then
    UpdateAllCooldowns()
  elseif event == "UNIT_AURA" then
    local unit = ...
    if unit then ScanUnitBuffs(unit) end
  elseif event == "BAG_UPDATE" then
    UpdateConsumables()
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- optional: expand UI after leaving combat
  end
end)

----------------------------------------------------------------
-- Slash commands for quick testing
----------------------------------------------------------------
SLASH_ENTEIMT1 = "/enteimt"
SlashCmdList["ENTEIMT"] = function(msg)
  if msg == "toggle" then
    Entei.db.profile.enabled = not Entei.db.profile.enabled
    Print("Enabled = " .. tostring(Entei.db.profile.enabled))
    frame:SetShown(Entei.db.profile.enabled)
  elseif msg == "debug" then
    Print("State dumps:")
    for k,v in pairs(state.cooldowns) do Print(k.." -> "..tostring(v.duration)) end
  else
    Print("Commands: toggle, debug")
  end
end

----------------------------------------------------------------
-- API hooks / helper entry points you can expand
----------------------------------------------------------------
function Entei.TrackSpell(spellKey)
  UpdateSpellCooldown(spellKey)
  RefreshUI()
end

function Entei.TrackAll()
  UpdateAllCooldowns()
  UpdateAllBuffs()
  UpdateConsumables()
  RefreshUI()
end

-- End of stub

