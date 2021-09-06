local screenConfig = {
    vertical = true,
    titleFontSize = 75,
    titleHeight = 100,
    headerRuleHeight = 5,
    fontSize = 45,
    xPadding = 20,
    tableXPadding = 10,
    rowHeight = 50,
    rowPadding = 10,
    countOffset = -150,
    columns = 2,
    tables = {}
}
screenConfig.tables[#screenConfig.tables + 1] = {
    title = "Product",
    columns = {"Heavy Metal"},
    rows = {
        {{name = "Steel Product", label = "Steel", targetCount = 6000}},
        {{name = "Stainless Steel Product", label = "Stainless S.", targetCount = 1000}},
        {{name = "Inconel Product", label = "Inconel", targetCount = 1000}},
        {{name = "Maraging Steel Product", label = "Maraging S.", targetCount = 1000}},
        {{name = "Mangalolly Product", label = "Mangalloy", targetCount = 1000}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    title = "Intermediate",
    columns = {"Screw"},
    countOffset = 100,
    rows = {
        {{name = "Basic Screw", label="", targetCount = 1200}},
        {{name = "Uncommon Screw", label="", targetCount = 800}},
        {{name = "Advanced Screw", label="", targetCount = 400}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Light Metal"},
    rows = {
        {{name = "Silumin Product", label = "Silumin", targetCount = 6000}},
        {{name = "Duralumin Product", label = "Duralumin", targetCount = 1000}},
        {{name = "Al-Li Alloy Product", label = "Al-Li Alloy", targetCount = 1000}},
        {{name = "Sc-Al Alloy Product", label = "Sc-Al Alloy", targetCount = 1000}},
        {{name = "Grade 5 Titanium Alloy Product", label = "G5 Titanium", targetCount = 1000}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Pipe"},
    countOffset = 100,
    rows = {
        {{name = "Basic Pipe", label="", targetCount = 800}},
        {{name = "Uncommon Pipe", label="", targetCount = 400}},
        {{name = "Advanced Pipe", label="", targetCount = 400}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Conductor"},
    rows = {
        {{name = "Al-Fe Alloy Product", label = "Al-Fe Alloy", targetCount = 6000}},
        {{name = "Calcium Reinforced Copper Product", label = "Ca Reinf Cu", targetCount = 1000}},
        {{name = "Cu-Ag Alloy Product", label = "Cu-Ag Alloy", targetCount = 1000}},
        {{name = "Red Gold Product", label = "Red Gold", targetCount = 1000}},
        {{name = "Ti-Nb Supraconductor Product", label = "Ti-Nb Spr.", targetCount = 1000}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Component", "Connector"},
    countOffset = 100,
    rows = {
        {{name = "Basic Component", label="", targetCount = 800}, {name = "Basic Connector", label="", targetCount = 400}},
        {{name = "Uncommon Component", label="", targetCount = 400}, {name = "Uncommon Connector", label="", targetCount = 400}},
        {{name = "Advanced Component", label="", targetCount = 400}, {name = "Advanced Connector", label="", targetCount = 400}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Polymer"},
    rows = {
        {{name = "Polycarbonate Plastic Product", label = "Polycarb", targetCount = 6000}},
        {{name = "Polycalcite Plastic Product", label = "Polycalc", targetCount = 1000}},
        {{name = "Polysulfide Plastic Product", label = "Polysulf", targetCount = 1000}},
        {{name = "Fluoropolymer Product", label = "Fluoroplmr", targetCount = 1000}},
        {{name = "Vanamer Product", label = "Vanamer", targetCount = 1000}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Fixation"},
    countOffset = 100,
    rows = {
        {{name = "Basic Fixation", label="", targetCount = 400}},
        {{name = "Uncommon Fixation", label="", targetCount = 400}},
        {{name = "Advanced Fixation", label="", targetCount = 400}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Glass"},
    rows = {
        {{name = "Glass Product", label = "Glass", targetCount = 6000}},
        {{name = "Advanced Glass Product", label = "Advanced", targetCount = 1000}},
        {{name = "Ag-Li Reinforced Glass Product", label = "Ag-Li Reinf", targetCount = 1000}},
        {{name = "Gold-Coated Glass Product", label = "Gold Ctd", targetCount = 1000}},
        {{name = "Manganese Reinforced Glass Product", label = "Manganese", targetCount = 1000}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"LED"},
    countOffset = 100,
    rows = {
        {{name = "Basic LED", label="", targetCount = 400}},
        {{name = "Uncommon LED", label="", targetCount = 400}},
        {{name = "Advanced LED", label="", targetCount = 400}},
    }
}

-- ensure display array exists
if not _G.displays then
    _G.displays = {}
end

-- must link by slot name
_G.displays[${slotName}] = screenConfig
