local orePureConfig = {
    vertical = true,
    titleFontSize = 75,
    titleHeight = 100,
    headerRuleHeight = 5,
    fontSize = 45,
    xPadding = 20,
    tableXPadding = 10,
    rowHeight = 50,
    rowPadding = 10,
    countOffset = -145,
    columns = 2,
    colspan = 2,
    tables = {}
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    title = "Ore",
    colspan = 1,
    rows = {}
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    title = "Pure",
    colspan = 1,
    rows = {}
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    columns = {"Tier 1", ""},
    rows = {
        {"Bauxite", {name = "Pure Aluminium", label = "Aluminium"}},
        {"Coal", {name = "Pure Carbon", label = "Carbon"}},
        {"Hematite", {name = "Pure Iron", label = "Iron"}},
        {"Quartz", {name = "Pure Silicon", label = "Silicon"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    columns = {"Tier 2", ""},
    rows = {
        {"Limestone", {name = "Pure Calcium", label = "Calcium"}},
        {"Chromite", {name = "Pure Chromium", label = "Chromium"}},
        {"Malachite", {name = "Pure Copper", label = "Copper"}},
        {"Natron", {name = "Pure Sodium", label = "Sodium"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    columns = {"Tier 3", ""},
    rows = {
        {"Petalite", {name = "Pure Lithium", label = "Lithium"}},
        {"Garnierite", {name = "Nickel Pure", label = "Nickel"}},
        {"Acanthite", {name = "Silver Pure", label = "Silver"}},
        {"Pyrite", {name = "Pure Sulfur", label = "Sulfur"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    columns = {"Tier 4", ""},
    rows = {
        {"Cobaltite", {name = "Pure Cobalt", label = "Cobalt"}},
        {"Cryolite", {name = "Pure Cryolite", label = "Cryolite"}},
        {{name = "Gold Nuggets", label = "Gold Ngts"}, {name = "Pure Gold", label = "Gold"}},
        {"Kolbeckite", {name = "Scandium Pure", label = "Scandium"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    columns = {"Tier 5", ""},
    rows = {
        {"Columbite", {name = "Niobium Pure", label = "Niobium"}},
        {"Rhodonite", {name = "Pure Manganese", label = "Manganese"}},
        {"Illmenite", {name = "Pure Titanium", label = "Titanium"}},
        {"Vanadinite", {name = "Vanadium Pure", label = "Vanadium"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    colspan = 1,
    columns = {"Gasses"},
    reverse = true,
    rows = {
        {{name = "Pure Hydrogen", label = "Hydrogen"}},
        {{name = "Pure Oxygen", label = "Oxygen"}},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    colspan = 1,
    columns = {"Catalyst"},
    rows = {
        {"Catalyst 3"},
        {"Catalyst 4"},
        {"Catalyst 5"},
    }
}
orePureConfig.tables[#orePureConfig.tables + 1] = {
    colspan = 1,
    columns = {"Ore Overflow"},
    countOffset = 100,
    reverse = true,
    rows = {
        {{name = "ore overflow", label = "", source = "container volume"}},
    }
}

-- ensure display array exists
if not _G.displays then
    _G.displays = {}
end

-- must link by slot name
_G.displays[${slotName}] = orePureConfig
