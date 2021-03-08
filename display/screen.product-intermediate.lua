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
        {{name = "Steel Product", label = "Steel"}},
        {{name = "Stainless Steel Product", label = "Stainless S."}},
        {{name = "Inconel Product", label = "Inconel"}},
        {{name = "Maraging Steel Product", label = "Maraging S."}},
        {{name = "Mangalolly Product", label = "Mangalloy"}},
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
        {{name = "Silumin Product", label = "Silumin"}},
        {{name = "Duralumin Product", label = "Duralumin"}},
        {{name = "Al-Li Alloy Product", label = "Al-Li Alloy"}},
        {{name = "Sc-Al Alloy Product", label = "Sc-Al Alloy"}},
        {{name = "Grade 5 Titanium Alloy Product", label = "G5 Titanium"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Pipe"},
    countOffset = 100,
    rows = {
        {{name = "Basic Pipe", label=""}},
        {{name = "Uncommon Pipe", label=""}},
        {{name = "Advanced Pipe", label=""}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Conductor"},
    rows = {
        {{name = "Al-Fe Alloy Product", label = "Al-Fe Alloy"}},
        {{name = "Calcium Reinforced Copper Product", label = "Ca Reinf Cu"}},
        {{name = "Cu-Ag Alloy Product", label = "Cu-Ag Alloy"}},
        {{name = "Red Gold Product", label = "Red Gold"}},
        {{name = "Ti-Nb Supraconductor Product", label = "Ti-Nb Spr."}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Component", "Connector"},
    countOffset = 100,
    rows = {
        {{name = "Basic Component", label=""}, {name = "Basic Connector", label=""}},
        {{name = "Uncommon Component", label=""}, {name = "Uncommon Connector", label=""}},
        {{name = "Advanced Component", label=""}, {name = "Advanced Connector", label=""}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Polymer"},
    rows = {
        {{name = "Polycarbonate Plastic Product", label = "Polycarb"}},
        {{name = "Polycalcite Plastic Product", label = "Polycalc"}},
        {{name = "Polysulfide Plastic Product", label = "Polysulf"}},
        {{name = "Fluoropolymer Product", label = "Fluoroplmr"}},
        {{name = "Vanamer Product", label = "Vanamer"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Fixation"},
    countOffset = 100,
    rows = {
        {{name = "Basic Fixation", label=""}},
        {{name = "Uncommon Fixation", label=""}},
        {{name = "Advanced Fixation", label=""}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"Glass"},
    rows = {
        {{name = "Glass Product", label = "Glass"}},
        {{name = "Advanced Glass Product", label = "Advanced"}},
        {{name = "Ag-Li Reinforced Glass Product", label = "Ag-Li Reinf"}},
        {{name = "Gold Coated Glass Product", label = "Gold Ctd"}},
        {{name = "Manganese Reinforced Glass Product", label = "Manganese"}},
    }
}
screenConfig.tables[#screenConfig.tables + 1] = {
    columns = {"LED"},
    countOffset = 100,
    rows = {
        {{name = "Basic LED", label=""}},
        {{name = "Uncommon LED", label=""}},
        {{name = "Advanced LED", label=""}},
    }
}

-- ensure display array exists
if not _G.displays then
    _G.displays = {}
end

-- must link by slot name
_G.displays[${slotName}] = screenConfig
