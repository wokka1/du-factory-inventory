local screenConfig = {
    vertical = true,
    titleFontSize = 40,
    titleHeight = 55,
    headerRuleHeight = 2,
    fontSize = 24,
    xPadding = 5,
    tableXPadding = 2,
    rowHeight = 27,
    rowPadding = 5,
    countOffset = -90,
    columns = 2,
    colspan = 2,
    tables = {}
}
screenConfig.tables[#screenConfig.tables + 1] = {
    title = "Ore",
    colspan = 1,
    rows = {}
}
screenConfig.tables[#screenConfig.tables + 1] = {
    title = "Pure",
    colspan = 1,
    rows = {}
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Tier 1", ""},
    rows = {
        {"Bauxite", {name = "Pure Aluminium", label = "Aluminium"}},
        {"Coal", {name = "Pure Carbon", label = "Carbon"}},
        {"Hematite", {name = "Pure Iron", label = "Iron"}},
        {"Quartz", {name = "Pure Silicon", label = "Silicon"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Tier 2", ""},
    rows = {
        {"Limestone", {name = "Pure Calcium", label = "Calcium"}},
        {"Chromite", {name = "Pure Chromium", label = "Chromium"}},
        {"Malachite", {name = "Pure Copper", label = "Copper"}},
        {"Natron", {name = "Pure Sodium", label = "Sodium"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Tier 3", ""},
    rows = {
        {"Petalite", {name = "Pure Lithium", label = "Lithium"}},
        {"Garnierite", {name = "Pure Nickel", label = "Nickel"}},
        {"Acanthite", {name = "Pure Silver", label = "Silver"}},
        {"Pyrite", {name = "Pure Sulfur", label = "Sulfur"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Tier 4", ""},
    rows = {
        {"Cobaltite", {name = "Pure Cobalt", label = "Cobalt"}},
        {"Cryolite", {name = "Pure Fluorine", label = "Fluorine"}},
        {{name = "Gold Nuggets", label = "Gold Ngts"}, {name = "Pure Gold", label = "Gold"}},
        {"Kolbeckite", {name = "Pure Scandium", label = "Scandium"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Tier 5", ""},
    rows = {
        {"Columbite", {name = "Pure Niobium", label = "Niobium"}},
        {"Rhodonite", {name = "Pure Manganese", label = "Manganese"}},
        {"Illmenite", {name = "Pure Titanium", label = "Titanium"}},
        {"Vanadinite", {name = "Pure Vanadium", label = "Vanadium"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    colspan = 1,
    columns = {"Gasses"},
    reverse = true,
    rows = {
        {{name = "Pure Hydrogen", label = "Hydrogen"}},
        {{name = "Pure Oxygen", label = "Oxygen"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    colspan = 1,
    columns = {"Catalyst"},
    rows = {
        {"Catalyst 3"},
        {"Catalyst 4"},
        {"Catalyst 5"},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    colspan = 2,
    columns = {"Ore Overflow"},
    countOffset = 50,
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
_G.displays[${slotName}] = screenConfig
