-- display configs
local screen1Config = {
    vertical = true,
    titleFontSize = 100,
    titleHeight = 120,
    fontSize = 60,
    xPadding = 20,
    tableXPadding = 10,
    rowHeight = 70,
    rowPadding = 10,
    tables = {}
}
screen1Config.tables[#screen1Config.tables + 1] = {
    -- TODO configure source, if both core and receiver default to core, otherwise whichever is present unless specified
    title = "Gasses",
    columns = 2,
    reverse = true, -- TODO read at table, row, and item level for overrides
    rows = {
        {{name = "Pure Hydrogen", label = "Hydrogen"}, {name = "Pure Oxygen", label = "Oxygen"}},
    }
}
screen1Config.tables[#screen1Config.tables + 1] = {
    title = "Tier 1",
    columns = 2, -- TODO read type for number (count) or table of strings (header row)
    rows = {
        {"Bauxite", {name = "Pure Aluminium", label = "Aluminium"}},
        {"Coal", {name = "Pure Carbon", label = "Carbon"}},
        {"Hematite", {name = "Pure Iron", label = "Iron"}},
        {"Quartz", {name = "Pure Silicon", label = "Silicon"}},
    }
}
screen1Config.tables[#screen1Config.tables + 1] = {
    title = "Tier 2",
    columns = 2,
    rows = {
        {"Limestone", {name = "Pure Calcium", label = "Calcium"}},
        {"Chromite", {name = "Pure Chromium", label = "Chromium"}},
        {"Malachite", {name = "Pure Copper", label = "Copper"}},
        {"Natron", {name = "Pure Sodium", label = "Sodium"}},
    }
}
screen1Config.tables[#screen1Config.tables + 1] = {
    title = "Tier 3",
    columns = 2,
    rows = {
        {"Petalite", {name = "Pure Lithium", label = "Lithium"}},
        {"Garnierite", {name = "Nickel Pure", label = "Nickel"}},
        {"Acanthite", {name = "Silver Pure", label = "Silver"}},
        {"Pyrite", {name = "Pure Sulfur", label = "Sulfur"}},
    }
}
screen1Config.tables[#screen1Config.tables + 1] = {
    title = "Tier 4",
    columns = 2,
    rows = {
        {"Cobaltite", {name = "Pure Cobalt", label = "Cobalt"}},
        {"Cryolite", {name = "Pure Cryolite", label = "Cryolite"}},
        {"Gold Nuggets", {name = "Pure Gold", label = "Gold"}},
        {"Kolbeckite", {name = "Scandium Pure", label = "Scandium"}},
    }
}
screen1Config.tables[#screen1Config.tables + 1] = {
    title = "Tier 5",
    columns = 2,
    rows = {
        {"Columbite", {name = "Niobium Pure", label = "Niobium"}},
        {"Rhodonite", {name = "Pure Manganese", label = "Manganese"}},
        {"Illmenite", {name = "Pure Titanium", label = "Titanium"}},
        {"Vanadinite", {name = "Vanadium Pure", label = "Vanadium"}},
    }
}

-- slot definitions
_G.slots = {}

-- if not found by name will autodetect
_G.slots.databank = databank
_G.slots.core = core
_G.slots.receiver = receiver

-- must be specified by name to properly associate screens to displays
_G.slots.displays = {}
_G.slots.displays[orePure] = screen1Config
