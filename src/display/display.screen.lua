-- constants
local DEFAULT_FONT = "Play-Bold"

local FONT = loadFont(DEFAULT_FONT, screenConfig.fontSize)

local EMPTY_LABEL = {0.46, 0.46, 0.46, 1}
local FULL_TEXT = {0, 0, 0, 1}
local FULL_LABEL = {0.2, 0.2, 0.2, 1}
local GREEN = {0, 0.5, 0, 1}
local YELLOW = {1, 1, 0, 1}
local RED = {0.5, 0, 0, 1}
local HEADER_RULE = {1, 1, 1, 1}

local X_RES, Y_RES = getResolution()

local X_START, Y_START, WIDTH
if screenConfig.vertical then
    X_START = -Y_RES
    Y_START = 0
    WIDTH = Y_RES
else
    X_START = 0
    Y_START = 0
    WIDTH = X_RES
end

-- define functions

local function applyTransformation(layer)
    if screenConfig.vertical then
        setLayerRotation(layer, -math.pi / 2)
    end
end

local SI_PREFIXES = {"", "k", "M", "G", "T", "P", "E", "Z", "Y"}
--- Converts raw float to formatted SI prefix with limited decimal places.
-- @tparam number value The number to format.
-- @tparam string units The units label to apply SI prefixes to.
-- @treturn string The formated number for display.
-- @treturn string The units with SI prefix applied.
local function printableNumber(value, units)
    -- can't process nil, 0 breaks the sign calculation
    if not value or value == 0 then
        return "0.0", units
    end

    local adjustedValue = math.abs(value)
    local sign = value / adjustedValue
    local factor = 1 -- index of no prefix
    while adjustedValue >= 999.5 and factor < #SI_PREFIXES do
        adjustedValue = adjustedValue / 1000
        factor = factor + 1
    end

    if adjustedValue < 9.95 then -- rounded to 10, show 1 decimal place
        return string.format("%.1f", sign * math.floor(adjustedValue * 10 + 0.5) / 10), SI_PREFIXES[factor] .. units
    end
    return string.format("%.0f", sign * math.floor(adjustedValue + 0.5)), SI_PREFIXES[factor] .. units
end

local function drawRow(layer, barColor, textColor, labelColor, xStart, yStart, width, height, textPadding, title, countOffset, count, units, percent)
    if barColor and percent <= 0 then
        return
    elseif not barColor and percent >= 1 then
        return
    end

    local printablePercent = math.floor(percent * 100 + 0.5)
    percent = math.min(1, percent)

    if barColor then
        -- new layer to allow for clipping
        if percent < 1 then
            layer = createLayer()
            applyTransformation(layer)

            setLayerClipRect(layer, xStart + (1 - percent) * width, yStart, width, height)
        end

        setNextFillColor(layer, table.unpack(barColor))
        addBox(layer, xStart + (1 - percent) * width, yStart, percent * width, height)
    end

    local textHeight = yStart + height * 3 / 4

    setNextTextAlign(layer, AlignH_Left, AlignV_Baseline)
    setNextFillColor(layer, table.unpack(textColor))
    addText(layer, FONT, title, xStart + textPadding, textHeight)

    local countX
    if countOffset < 0 then
        countX = xStart + width + countOffset - textPadding
    else
        countX = xStart + textPadding + countOffset
    end
    setNextTextAlign(layer, AlignH_Right, AlignV_Baseline)
    setNextFillColor(layer, table.unpack(textColor))
    addText(layer, FONT, count, countX, textHeight)
    if units:len() > 0 then
        setNextTextAlign(layer, AlignH_Left, AlignV_Baseline)
        setNextFillColor(layer, table.unpack(labelColor))
        addText(layer, FONT, units, countX, textHeight)
    end

    local percentWidth = getTextBounds(FONT, "%")
    setNextTextAlign(layer, AlignH_Right, AlignV_Baseline)
    setNextFillColor(layer, table.unpack(textColor))
    addText(layer, FONT, printablePercent, xStart + width - textPadding - percentWidth, textHeight)
    setNextTextAlign(layer, AlignH_Right, AlignV_Baseline)
    setNextFillColor(layer, table.unpack(labelColor))
    addText(layer, FONT, "%", xStart + width - textPadding, textHeight)
end

local function generateRowCell(layer, item, itemConfig, itemData, xStart, yStart, width, height, countOffset)
    local itemName, itemLabel
    if type(item) == "table" then
        itemName = string.lower(item.name)
        itemLabel = item.label or item.name
    else
        itemName = string.lower(item)
        itemLabel = item
    end

    local itemResults = itemData[itemName] or {}
    local units = ""
    local count = 0
    local maxCount = 1
    local countError = false

    if itemResults.containerMaxItems and itemResults.containerMaxItems > 0 then
        units = itemResults.units
        count = itemResults.containerItems
        maxCount = itemResults.containerMaxItems
        countError = itemResults.containerError
    end

    if itemConfig.targetCount then
        maxCount = itemConfig.targetCount
    end

    local percent = count / maxCount

    local barColor
    if itemConfig.reverse then
        if percent > 0.9 then
            barColor = RED
        elseif percent > 0.5 then
            barColor = YELLOW
        else
            barColor = GREEN
        end
    else
        if percent > 0.5 then
            barColor = GREEN
        elseif percent > 0.1 then
            barColor = YELLOW
        else
            barColor = RED
        end
    end

    local printableCount, countUnits = printableNumber(count, units)

    -- TODO show/test error

    setFontSize(FONT, itemConfig.fontSize)

    drawRow(layer, nil, barColor, EMPTY_LABEL, xStart, yStart, width, height, itemConfig.tableXPadding, itemLabel, countOffset, printableCount, countUnits, percent)
    drawRow(layer, barColor, FULL_TEXT, FULL_LABEL, xStart, yStart, width, height, itemConfig.tableXPadding, itemLabel, countOffset, printableCount, countUnits, percent)
end

local function inheritConfig(parentConfig, childConfig)
    local resultConfig = {}
    for key, value in pairs(parentConfig) do
        if type(value) ~= "table" then
            resultConfig[key] = value
        end
    end

    if type(childConfig) == "table" then
        for key, value in pairs(childConfig) do
            if type(value) ~= "table" then
                resultConfig[key] = value
            end
        end
    end

    return resultConfig
end

local function generateTable(layer, displayTable, tableConfig, xOffset, yOffset, width, itemData)
    local title = displayTable.title

    if title then
        setFontSize(FONT, tableConfig.titleFontSize)
        setNextTextAlign(layer, AlignH_Center, AlignV_Descender)
        addText(layer, FONT, title, xOffset + width / 2, yOffset + tableConfig.titleHeight * 3 / 4)
        yOffset = yOffset + tableConfig.titleHeight
    end

    local columns
    if type(displayTable.columns) == "table" then
        columns = #displayTable.columns
    else
        columns = displayTable.columns or 1
    end
    local columnXPadding = tableConfig.xPadding or tableConfig.xPadding or 0

    local columnWidth = (width - (columns - 1) * columnXPadding) / columns
    local rowHeight = displayTable.rowHeight or tableConfig.rowHeight
    local rowPadding = displayTable.rowPadding or tableConfig.rowPadding

    if type(displayTable.columns) == "table" then
        for i, columnHeader in pairs(displayTable.columns) do
            setFontSize(FONT, tableConfig.fontSize)
            setNextTextAlign(layer, AlignH_Center, AlignV_Descender)
            local headerX = xOffset + (i - 1) * (columnWidth + columnXPadding) + columnWidth / 2
            addText(layer, FONT, columnHeader, headerX, yOffset + tableConfig.rowHeight * 3 / 4)
        end
        yOffset = yOffset + rowHeight
        setNextFillColor(layer, table.unpack(HEADER_RULE))
        addBox(layer, xOffset, yOffset, width, tableConfig.headerRuleHeight)
        yOffset = yOffset + tableConfig.headerRuleHeight
    end

    for _, row in pairs(displayTable.rows) do
        local rowConfig = inheritConfig(tableConfig, row)

        local column = 0
        for _, item in pairs(row) do
            local itemConfig = inheritConfig(rowConfig, item)

            local rowX = xOffset + column * (columnWidth + columnXPadding)
            generateRowCell(layer, item, itemConfig, itemData, rowX, yOffset, columnWidth, rowHeight, tableConfig.countOffset)

            column = column + 1
        end

        yOffset = yOffset + rowHeight + rowPadding
    end

    return yOffset
end

-- render

local baseLayer = createLayer()
applyTransformation(baseLayer)

local yOffset = Y_START
local maxYOffset = 0

local columns = screenConfig.columns or 1
local columnWidth = (WIDTH - (columns - 1) * screenConfig.xPadding) / columns
local column = 0

for _, displayTable in pairs(screenConfig.tables) do
    local tableConfig = inheritConfig(screenConfig, displayTable)

    local xOffset = X_START + screenConfig.xPadding + column * columnWidth + math.max(0, column - 1) * screenConfig.xPadding

    local colspan = tableConfig.colspan or 1
    local tableWidth = (WIDTH - screenConfig.xPadding) / columns * colspan - screenConfig.xPadding

    local tableYEnd = generateTable(baseLayer, displayTable, tableConfig, xOffset, yOffset, tableWidth, itemData)
    maxYOffset = math.max(maxYOffset, tableYEnd)
    column = column + colspan

    if column >= columns then
        yOffset = maxYOffset
        maxYOffset = 0
        column = 0
    end
end
