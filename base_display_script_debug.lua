----------------------------------------
-- Factory Inventory: Display Manager --
--        By W3asel (1337joe)         --
----------------------------------------
-- DEBUG VERSION with console output

-- exported variables
local elementsReadPerUpdate = 50 --export: The number of elements to process for data collection before the coroutine sleeps.
local maxMassError = 0.001 -- max error allowed for container lookups

-- localize global lookups
local slots = {}
slots.displays = _G.displays
slots.containers = _G.containers
local Utilities = _G.Utilities
local InventoryCommon = _G.InventoryCommon
local json = _G.json
local math = _G.math

system.print("=== DISPLAY SCRIPT DEBUG ===")
system.print("_G.displays exists: " .. tostring(_G.displays ~= nil))
if _G.displays then
    local displayCount = 0
    for slotName, config in pairs(_G.displays) do
        displayCount = displayCount + 1
        system.print("  Display slot: " .. tostring(slotName))
    end
    system.print("Number of displays configured: " .. displayCount)
else
    system.print("ERROR: _G.displays is nil! Did you load ore_pure_config.lua in a library slot?")
    unit.exit()
    return
end

-- if not found by name will autodetect
slots.databank = databank
slots.core = core

-- validate inputs
local screenIndex = 1
for slot, _ in pairs(slots.displays) do
    assert(slot.getClass() == "ScreenUnit",
        string.format("Display slot %d is invalid type: %s", screenIndex, slot.getClass()))
    slot.activate()
    screenIndex = screenIndex + 1
end
system.print("Activated " .. (screenIndex - 1) .. " screen(s)")

-----------------------
-- End Configuration --
-----------------------

-- link missing slot inputs / validate provided slots
local module = "inventory-report"
slots.core = Utilities.loadSlot(slots.core, {"CoreUnitDynamic", "CoreUnitStatic", "CoreUnitSpace"}, nil, module, "core", false)
local databankOptionalMsg = nil
if slots.core then
    databankOptionalMsg = "Databank link not found, required for reading container data from core."
end
slots.databank = Utilities.loadSlot(slots.databank, "DataBankUnit", nil, module, "databank", true, databankOptionalMsg)

if slots.databank then
    local keyCount = 0
    for _, key in pairs(slots.databank.getKeyList()) do
        keyCount = keyCount + 1
    end
    system.print("Databank has " .. keyCount .. " keys")
else
    system.print("WARNING: No databank connected!")
end

-- hide widget
unit.hideWidget()

-- define display constants and functions
local RENDER_SCRIPT = [[-- constants
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

    local canCreateLayers = getRenderCostMax() - getRenderCost() > 150000
    if not canCreateLayers then
        textColor = labelColor
    end

    if barColor then
        -- new layer to allow for clipping
        if percent < 1 and canCreateLayers then
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
]]

local function populateScreen(screen, screenConfig, itemData)
    local script = string.format([=[
        local screenConfig = load(%q)()
        local itemData = load(%q)()
        %s]=],
        "return " .. serialize(screenConfig), "return " .. serialize(itemData), RENDER_SCRIPT)
    screen.setRenderScript(script)
end

-- define data gathering functions

--- Initialize metadata: complete autodetected config fields, prepare for reading/receiving data.
local function initializeMetadata(firstRun)
    for screen, config in pairs(slots.displays) do
        if firstRun then
        -- TODO add loading overlay svg screen
        end

        -- clear/prep for data
        config.data = nil
        config.complete = false
    end
end
initializeMetadata(true)

-- define class for managing item data
local ItemReport = {}
function ItemReport:new(o)
    if not o or type(o) ~= "table" then
        o = {}
    end
    setmetatable(o, self)
    self.__index = self

    o.units = ""

    -- o.containerData = false
    o.containerItems = 0
    o.containerMaxItems = 0
    o.containerError = nil

    return o
end
local gatheredItems = {}

local function scanContainer(itemData, report)
    local name = itemData.name
    if slots.containers and slots.containers[name] and slots.containers[name].getItemsVolume then
        report.units = "L"
        report.containerItems = slots.containers[name].getItemsVolume()
        report.containerMaxItems = slots.containers[name].getMaxVolume()
        report.containerError = nil
    else
        system.print("Container link not found for " .. name)
        report.containerError = true
    end
end

local resumeOnUpdate = true
local function updateData()

    -- determine necessary data
    system.print("Scanning display config for items...")
    local itemCount = 0
    for slot, config in pairs(slots.displays) do
        for _, table in pairs(config.tables) do
            for _, row in pairs(table.rows) do
                for _, item in pairs(row) do
                    if type(item) == "table" then
                        local report = ItemReport:new(item)
                        gatheredItems[string.lower(item.name)] = report
                        itemCount = itemCount + 1

                        if item.source == InventoryCommon.constants.SOURCE_CONTAINER_VOLUME_ONLY then
                            scanContainer(item, report)
                        end
                    elseif type(item) == "string" then
                        gatheredItems[string.lower(item)] = ItemReport:new()
                        itemCount = itemCount + 1
                    else
                        assert(false, "Unexpected item type: " .. tostring(item) .. " (" .. type(item) .. ")")
                    end
                end
            end
        end

        coroutine.yield()
        ::continue::
    end
    system.print("Found " .. itemCount .. " items to track")

    -- gather data by databank lookup (containers)
    system.print("Reading databank...")
    local elementsRead = 0
    local itemsFound = 0
    local containersProcessed = 0

    for name, data in pairs(gatheredItems) do
        if not slots.databank then
            system.print("ERROR: No databank available!")
            break
        end

        -- read container data using databank values
        local containerIdListKey = name .. InventoryCommon.constants.CONTAINER_SUFFIX
        if not (slots.databank.hasKey(name) == 1 and slots.databank.hasKey(containerIdListKey) == 1) then
            goto continueContainers
        end

        -- Found this item in databank
        itemsFound = itemsFound + 1

        -- itemName -> unitMass, unitVolume, isMaterial
        -- itemName.CONTAINER_SUFFIX -> [id, id, id, ...]
        -- CONTAINER_PREFIX.containerId -> selfMass, maxVolume, optimization

        local itemDetails = json.decode(slots.databank.getStringValue(name))

        local containerIdList = InventoryCommon.jsonToIntList(slots.databank.getStringValue(containerIdListKey))
        system.print("  " .. name .. ": " .. #containerIdList .. " container(s)")

        for _, containerId in pairs(containerIdList) do
            -- remove container ids that aren't in core.getElementIdList
            if slots.core.getElementDisplayNameById(containerId) == "" then
                InventoryCommon.removeContainerFromDb(slots.databank, containerId)
                system.print(string.format("Container %d not found in core lookup, removing from databank...", containerId))
                goto continueContainerId
            end

            local containerDetails = json.decode(slots.databank.getStringValue(InventoryCommon.constants.CONTAINER_PREFIX .. containerId))

            local containerMass = slots.core.getElementMassById(containerId)
            local itemMass = (containerMass - containerDetails.selfMass) / containerDetails.optimization
            local itemCount = itemMass / itemDetails.unitMass
            local itemUnits
            local maxItems
            if itemDetails.isMaterial then
                itemUnits = "L"
                maxItems = containerDetails.maxVolume
            else
                itemUnits = ""
                maxItems = math.floor(containerDetails.maxVolume / itemDetails.unitVolume)
            end

            system.print(string.format("    Container %d: %.1fL / %.1fL (%.1f%% full)",
                containerId, itemCount, maxItems, (itemCount/maxItems)*100))

            data.units = itemUnits
            -- data.containerData = true
            data.containerItems = data.containerItems + itemCount
            data.containerMaxItems = data.containerMaxItems + maxItems
            data.containerError = data.containerError or math.abs(itemCount - math.floor(itemCount)) > maxMassError

            containersProcessed = containersProcessed + 1

            elementsRead = elementsRead + 1
            if elementsRead % elementsReadPerUpdate == 0 then
                coroutine.yield()
            end

            ::continueContainerId::
        end

        ::continueContainers::
    end

    system.print(string.format("Processed %d items with %d containers", itemsFound, containersProcessed))

    -- gather data by container links

    -- gather data by industry scanning
    if slots.core then
        for _, id in pairs(slots.core.getElementIdList()) do
            -- system.print(id .. ": " .. slots.core.getElementNameById(id) .. ": " .. slots.core.getElementDisplayNameById(id))

            elementsRead = elementsRead + 1
            if elementsRead % elementsReadPerUpdate == 0 then
                coroutine.yield()
            end
        end
    end

    -- update screens
    system.print("Updating screens...")
    for slot, config in pairs(slots.displays) do
        -- skip if already done
        if config.finished then
            goto continue
        end

        populateScreen(slot, config, gatheredItems)
        config.complete = true
        system.print("Screen updated successfully!")

        coroutine.yield()
        ::continue::
    end

    resumeOnUpdate = false
    system.print("=== UPDATE COMPLETE ===")
    unit.exit()
end

local updateCoroutine = coroutine.create(updateData)
function _G.resumeWork()
    -- don't hit coroutine every tick when it's waiting for more data
    if not resumeOnUpdate then
        return
    end

    local ok, message = coroutine.resume(updateCoroutine)
    if not ok then
        error(string.format("Resuming coroutine failed: %s", message))
    end
end

function _G.handleMessage(msg)
    -- TODO store data as appropriate

    resumeOnUpdate = true
end
