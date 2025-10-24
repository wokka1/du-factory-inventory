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
    title = "Row 1",
    columns = {"Top Left", "Top Right"},
    rows = {
        {{name = "Corner Cable Model C"},{name = "Resurrection Node"}},
        {{name = "Cable Model C S"},{name = "Steel Panel"}},
        {{name = "Cable Model B M"},{name = "Shelf Half Full"}},
        {{name = "Corner Cable Model A"},{name = "Wingtip L"}},
        {{name = "Cable Model A S"},{name = "Wingtip S"}},
        {{name = "Screen M"},{name = "Hull Decorative Element B", label = "Hull Dec B"}},
        {{name = "Screen XS"},{name = "Force Field L"}},
        {{name = "Relay"},{name = "Force Field S"}},
        {{name = "Detection Zone M"},{name = "Headlight"}},
        {{name = "Detection Zone XS"},{name = "Long Light M"}},
        {{name = "Squash Plant Case"},{name = "Long Light XS"}},
        {{name = "Plant Case A"},{name = "Square Light M"}},
        {{name = "Ficus Plant A"},{name = "Square Light XS"}},
        {{name = "Plant"},{name = "Vertical Light M"}},
        {{name = "Suspended Fruit Plant"},{name = "Vertical Light XS"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Bottom Left", "Bottom Right"},
    rows = {
        {{name = "Steel Column"},{name = "Fuel Intake XS"}},
        {{name = "Cable Model C M"},{name = "Shelf Full"}},
        {{name = "Corner Cable Model B"},{name = "Shelf Empty"}},
        {{name = "Cable Model B S"},{name = "Wingtip M"}},
        {{name = "Cable Model A M"},{name = "Vertical Wing"}},
        {{name = "Transparent Screen L"},{name = "Hull Decorative Element C", label = "Hull Dec C"}},
        {{name = "Screen S"},{name = "Hull Decorative Element A", label = "Hull Dec A"}},
        {{name = "Programming Board"},{name = "Force Field M"}},
        {{name = "Detection Zone L"},{name = "Force Field XS"}},
        {{name = "Detection Zone S"},{name = "Long Light L"}},
        {{name = "Eggplant Plant Case"},{name = "Long Light S"}},
        {{name = "Plant Case S"},{name = "Square Light L"}},
        {{name = "Salad Plant Case"},{name = "Square Light S"}},
        {{name = "Bagged Plant A"},{name = "Vertical Light L"}},
        {{name = "Suspended Plant A"},{name = "Vertical Light S"}},
    }
}

-- ensure display array exists
if not _G.displays then
    _G.displays = {}
end

-- must link by slot name
_G.displays[${slotName}] = screenConfig
