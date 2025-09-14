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

