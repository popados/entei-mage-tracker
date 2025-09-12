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
    frame:SetSize(200, 120)
    frame:SetPoint("TOPLEFT", 10, -10)

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(true)
    frame.bg:SetColorTexture(0, 0, 0, 0.5)

    -- Spell icons
    frame.icons = {}
    frame.icons.FrostNova    = CreateIcon("FrostNova", SPELLS.FrostNova, frame, 6, -6)
    frame.icons.Counterspell = CreateIcon("Counterspell", SPELLS.Counterspell, frame, 44, -6)
    frame.icons.Blink        = CreateIcon("Blink", SPELLS.Blink, frame, 82, -6)
    frame.icons.Evocation    = CreateIcon("Evocation", SPELLS.Evocation, frame, 120, -6)

    -- Buff text
    frame.armorText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.armorText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -46)
    frame.armorText:SetText("Armor: None")

    -- Reagents text
    frame.reagentText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.reagentText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -64)
    frame.reagentText:SetText("Runes: 0")
end

-- Refresh UI: spells, buffs, reagents
function ns.RefreshUI()
    if not frame then return end

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
