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

