local addonName, ns = ...
local state = ns.state


local optionsPanel = CreateFrame("Frame", "OptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "Entei's Mage Tracker"

-- Register panel with options
-- Old: InterfaceOptions_AddCategory(panel)
local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
Settings.RegisterAddOnCategory(category)
