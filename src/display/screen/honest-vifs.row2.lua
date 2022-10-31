----------------------------------------
-- Factory Inventory: Display Manager --
--        By W3asel (1337joe)         --
----------------------------------------
-- This display commissioned by Vifrevaert for Honest Vif's store at Utopia Station
-- Bundled: ${date}
-- Latest version always available here: https://du.w3asel.com/du-factory-inventory/templates/template.display.honest-vifs.json

local screenConfig = {
    vertical = true,
    titleFontSize = 40,
    titleHeight = 50,
    headerRuleHeight = 2,
    fontSize = 19,
    xPadding = 10,
    tableXPadding = 5,
    rowHeight = 25.5,
    rowPadding = 5,
    countOffset = -50,
    columns = 1,
    colspan = 1,
    tables = {}
}
screenConfig.tables[#screenConfig.tables + 1] = {
    title = "Row 2",
    columns = {"Top Left", "Top Right"},
    rows = {
        {{name = "Window XS"},{name = "Window M"}},
        {{name = "Surrogate VR Station"},{name = "Armored Window XS"}},
        {{name = "Trash Can"},{name = "Armored Window M"}},
        {{name = "Barrier M"},{name = "Dispenser"}},
        {{name = "Wooden Low Table"},{name = "Square Carpet"}},
        {{name = "Wooden Dresser"},{name = "Glass Panel M"}},
        {{name = "Wooden Chair"},{name = "Keyboard Unit"}},
        {{name = "Navigator Chair"},{name = "Spaceship Hologram S"}},
        {{name = "Toilet Unit B"},{name = "Command Seat Controller", label = "Command Seat"}},
        {{name = "Sink Unit"},{name = "Wooden Table L"}},
        {{name = "Nightstand"}},
        {{name = "Bed"}},
        {{name = "Sofa"}},
        {{name = "Wooden Armchair"}},
        {{name = "Wooden Table M"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Bottom Left", "Bottom Right"},
    rows = {
        {{name = "Surrogate Pod Station"},{name = "Window S"}},
        {{name = "Elevator XS"},{name = "Window L"}},
        {{name = "Barrier Corner"},{name = "Armored Window S"}},
        {{name = "Barrier S"},{name = "Armored Window L"}},
        {{name = "Dresser"},{name = "Hatch S"}},
        {{name = "Encampment Chair"},{name = "Glass Panel S"}},
        {{name = "Office Chair"},{name = "Glass Panel L"}},
        {{name = "Urinal Unit"},{name = "Planet Hologram"}},
        {{name = "Toilet Unit A"},{name = "Spaceship Hologram M"}},
        {{name = "Shower Unit"},{name = "Hovercraft Seat Controller", label = "Hovercraft Seat"}},
        {{name = "Wardrobe"}},
        {{name = "Bench"}},
        {{name = "Wooden Sofa"}},
        {{name = "Table"}},
        {{name = "Wooden Wardrobe"}},
    }
}

-- ensure display array exists
if not _G.displays then
    _G.displays = {}
end

-- must link by slot name
_G.displays[${slotName}] = screenConfig
