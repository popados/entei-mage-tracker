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


