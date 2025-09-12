<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD036 -->
<!-- markdownlint-disable MD041 -->
<div id="top-of-doc"></div>

# Readme File | Entei Mage Tracker | September-12-2025 |

[Github](https://github.com/popados) | [Jump to End](#end-of-doc)

---

## Specifications

**Entei’s Mage Tracker – Design Outline**

Core Features for classic World of Warcraft

**Spells & Cooldowns**

Track major offensive spells with cooldowns (Frost Nova, Counterspell, Blink, Evocation).

Visual or icon-based cooldown tracker (bars, numbers, pulse effect when ready).

Buffs

**Self Buffs**

Armor (Frost/Fire/Mage Armor → highlight which is active, show alternatives).

Wards (Fire Ward, Frost Ward).

Arcane Intellect.

**Party Buffs**

Track expiration timers for Arcane Intellect/Brilliance on all party members.

**Utilities**

Sheep (Polymorph) tracker: current target, duration timer, re-sheep alert.

Mana Gem charges remaining.

Evocation cooldown/status.

Counterspell cooldown.

**Consumables**

Food/Water Count (Conjured stacks).

Reagents (Runes of Teleportation, Portals).

Auto-warning when below threshold.

**Teleportation**

Teleports (to each city).

Portals (to each city).

Grouped under “Travel” tab with reagent count check.

**Armor & Gear**

Mana Shield / Ice Barrier absorption left (if tracking combat status).

**Cooldowns**

Utilities (Polymorph, Evocation, Mana Gems)

Consumables (Food, Water, Reagents)

Teleport/Portal

Armor/Wards

Display Options

**Advanced Features (Stretch Goals)**

Alerts

Flash/sound when buff about to expire.

Ping for “Polymorph broken.”

Low reagent warning.

**Customization**

Toggle which elements to track.

Scale/position of tracker.

Compact vs expanded view.

**Integration**

Tooltip enhancement (show reagent count, spell CD).

Clickable icons to cast spells directly from tracker.

⚡ This structure would let you build the addon modularly:

Start with core spell cooldowns + buff timers.

Add consumables & reagent tracking.

Build out teleport/portal + utilities.

Layer on UI polish & alerts.

Do you want me to sketch this out into an addon file structure with Lua/XML stubs so you can start coding it right away, or would you prefer I expand this into a visual UI mockup first?

---

### DayNum | x/x/20xx - Today

---

### Day 001 | 9/12/2025 - Friday

Got to work on the addon. Got the basic scaffolding for the lua in place. The various parts of the stub are going into seperate files. Each file will handle a different function of the addon.

- Mage Addon
  - Tracks spells, cooldowns, buffs, utilities, ports, food/water count, damage left on armor, mage armor, sheep target tracker
    - Teleports
    - Portals
    - Conjure Food/Water
    - Spellbook
    - Utility Spells
    - Mana Gems
    - Reagents
    - Buff Timer - Party - Self
    - Mage Armors
      - Current
      - Others
    - Wards
      - Current
    - Blink
      - CD
    -

---

## End of Document

---

[Jump to Top](#top-of-doc)

<div id="end-of-doc"></div>

<details>
<summary>
Notes :
</summary>
</details>
