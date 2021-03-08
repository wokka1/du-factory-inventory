----------------------------------------
-- Factory Inventory: Display Manager --
--        By W3asel (1337joe)         --
----------------------------------------
-- Bundled: ${date}
-- Latest version always available here: https://du.w3asel.com/du-factory-inventory

-- exported variables
local elementsReadPerUpdate = 100 --export: The number of elements to process for data collection before the coroutine sleeps.
local maxMassError = 0.001 -- max error allowed for container lookups

-- localize global lookups
local slots = {}
slots.displays = _G.displays
slots.containers = _G.containers
local Utilities = _G.Utilities
local InventoryCommon = _G.InventoryCommon
local json = _G.json
local math = _G.math

-- if not found by name will autodetect
slots.databank = databank
slots.core = core

-- validate inputs
local screenIndex = 1
for slot, _ in pairs(slots.displays) do
    assert(slot.getElementClass() == "ScreenUnit",
        string.format("Display slot %d is invalid type: %s", screenIndex, slot.getElementClass()))
    slot.activate()
    screenIndex = screenIndex + 1
end

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

-- hide widget
unit.hide()

-- define display constants and functions
local STYLE_TEMPLATE = [[
<style>
text {
    font-size: %fpx;
    fill: white;
    font-family: Arial;
    text-transform: none;
}
text.blockTitle {
    font-size: %fpx;
    text-anchor: middle;
}
.empty .label {
    fill: #777;
}
.full text {
    fill: black;
}
.full .label {
    fill: #333;
}
.fillGreen, .fillGreen text {
    fill: green;
}
.fillYellow, .fillYellow text {
    fill: yellow;
}
.fillRed, .fillRed text {
    fill: red;
}
rect.headerRule {
    fill: white;
}
</style>
]]
local function generateStyle(screenConfig)
    return string.format(STYLE_TEMPLATE, screenConfig.fontSize, screenConfig.titleFontSize)
end

local ROW_TEMPLATE = [[
<g transform="translate(%.1f,%.1f)">
    <defs>
        <clipPath id="percentClip%d">
            <rect x="%.1f" y="0" width="1920" height="1920" />
        </clipPath>
    </defs>
    <g class="empty %s">
        <text x="$leftText" y="$textHeight">%s</text>
        <text x="$countOffset" y="$textHeight" text-anchor="end">%s</text>
        <text x="$countOffset" y="$textHeight" class="label">%s</text>
        <text x="$rightText" y="$textHeight" text-anchor="end">%.0f<tspan class="label">%%</tspan></text>
    </g>
    <g class="full" clip-path="url(#percentClip%d)">
        <rect x="0" y="0" width="%.1f" height="%.1f" class="%s"/>
        <text x="$leftText" y="$textHeight">%s</text>
        <text x="$countOffset" y="$textHeight" text-anchor="end">%s</text>
        <text x="$countOffset" y="$textHeight" class="label">%s</text>
        <text x="$rightText" y="$textHeight" text-anchor="end">%.0f<tspan class="label">%%</tspan></text>
    </g>
</g>
]]
local rowClassIndex = 0
local function generateRowCell(item, itemConfig, itemData, xStart, yStart, width, height, countOffset)
    rowClassIndex = rowClassIndex + 1

    local itemName, itemLabel
    if type(item) == "table" then
        itemName = string.lower(item.name)
        itemLabel = item.label or itemName
    else
        itemName = string.lower(item)
        itemLabel = item
    end

    local itemResults = itemData[itemName] or {}
    local units = ""
    local count = 0
    local maxCount = 1
    local countError = false

    -- determine data source based on configuration, fall back to first available data if not specified
    if itemConfig.source == InventoryCommon.constants.SOURCE_CONTAINER_VOLUME_ONLY then
        if slots.containers and slots.containers[itemName] and slots.containers[itemName].getItemsVolume then
            units = "L"
            count = slots.containers[itemName].getItemsVolume()
            maxCount = slots.containers[itemName].getMaxVolume()
            countError = false
        else
            system.print("Container link not found for " .. itemName)
            countError = true
        end
    elseif itemConfig.source == InventoryCommon.constants.SOURCE_CORE_CONTAINER or (not itemConfig.source and itemResults.containerData) then
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
            barColor = "fillRed"
        elseif percent > 0.5 then
            barColor = "fillYellow"
        else
            barColor = "fillGreen"
        end
    else
        if percent > 0.5 then
            barColor = "fillGreen"
        elseif percent > 0.1 then
            barColor = "fillYellow"
        else
            barColor = "fillRed"
        end
    end

    local printableCount, countUnits = Utilities.printableNumber(count, units)
    local printablePercent = math.floor(percent * 100 + 0.5)

    -- TODO show/test error

    local rowSvg = string.format(ROW_TEMPLATE, xStart, yStart,
               rowClassIndex, (1 - percent) * width, barColor, itemLabel, printableCount, countUnits,
               printablePercent, rowClassIndex, width, height, barColor, itemLabel, printableCount, countUnits, printablePercent)

    rowSvg = string.gsub(rowSvg, "$textHeight", height * 3 / 4)
    rowSvg = string.gsub(rowSvg, "$leftText", 5)
    if countOffset < 0 then
        rowSvg = string.gsub(rowSvg, "$countOffset", width + countOffset - 5)
    else
        rowSvg = string.gsub(rowSvg, "$countOffset", 5 + countOffset)
    end
    rowSvg = string.gsub(rowSvg, "$rightText", width - 5)

    return rowSvg
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

local function generateTable(table, tableConfig, xOffset, yOffset, width, itemData)
    local title = table.title

    local document = ""
    if title then
        document = string.format([[<text class="blockTitle" x="%f" y="%f">%s</text>]], xOffset + width / 2, yOffset + tableConfig.titleHeight * 3 / 4, title)
        yOffset = yOffset + tableConfig.titleHeight
    end

    local columns
    if type(table.columns) == "table" then
        columns = #table.columns
    else
        columns = table.columns or 1
    end
    local columnXPadding = tableConfig.xPadding or tableConfig.xPadding or 0

    local columnWidth = (width - (columns - 1) * columnXPadding) / columns
    local rowHeight = table.rowHeight or tableConfig.rowHeight
    local rowPadding = table.rowPadding or tableConfig.rowPadding

    if type(table.columns) == "table" then
        for i, columnHeader in pairs(table.columns) do
            local headerX = xOffset + (i - 1) * (columnWidth + columnXPadding) + columnWidth / 2
            document = document .. string.format([[<text x="%f" y="%f" text-anchor="middle">%s</text>]], headerX, yOffset + tableConfig.rowHeight * 3 / 4, columnHeader)
        end
        yOffset = yOffset + rowHeight
        document = document .. string.format([[<rect x="%f" y="%f" width="%f" height="%f" class="headerRule"/>]], xOffset, yOffset, width, tableConfig.headerRuleHeight)
        yOffset = yOffset + tableConfig.headerRuleHeight
    end

    for _, row in pairs(table.rows) do
        local rowConfig = inheritConfig(tableConfig, row)

        local column = 0
        for _, item in pairs(row) do
            local itemConfig = inheritConfig(rowConfig, item)

            local rowX = xOffset + column * (columnWidth + columnXPadding)
            document = document .. generateRowCell(item, itemConfig, itemData, rowX, yOffset, columnWidth, rowHeight, tableConfig.countOffset)

            column = column + 1
        end

        yOffset = yOffset + rowHeight + rowPadding
    end

    return document, yOffset
end

local function populateScreen(screen, screenConfig, itemData)
    local document = [[<svg viewbox="0 0 1920 1145" style="width:100%;height:100%;" class="bootstrap" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="none">]]

    document = document .. generateStyle(screenConfig)

    local height, width, rotateString
    if screenConfig.vertical then
        height = 1920
        width = 1145
        document = document .. [[<g transform="translate(0,1145) rotate(-90)">]]
    else
        height = 1145
        width = 1920
    end

    local yOffset = 0
    local maxYOffset = 0

    local columns = screenConfig.columns or 1
    local columnWidth = (width - (columns - 1) * screenConfig.xPadding) / columns
    local column = 0

    for _, table in pairs(screenConfig.tables) do
        local tableConfig = inheritConfig(screenConfig, table)

        local xOffset = screenConfig.xPadding + column * columnWidth + math.max(0, column - 1) * screenConfig.xPadding

        local colspan = tableConfig.colspan or 1
        local tableWidth = (width - screenConfig.xPadding) / columns * colspan - screenConfig.xPadding

        local tableElement, tableYEnd = generateTable(table, tableConfig, xOffset, yOffset, tableWidth, itemData)
        document = document .. tableElement
        maxYOffset = math.max(maxYOffset, tableYEnd)
        column = column + colspan

        if column >= columns then
            yOffset = maxYOffset
            maxYOffset = 0
            column = 0
        end
    end

    if screenConfig.vertical then
        document = document .. [[</g>]]
    end
    document = document .. "</svg>"
    screen.setHTML(document)
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

    o.containerData = false
    o.containerItems = 0
    o.containerMaxItems = 0
    o.containerError = false

    return o
end
local gatheredItems = {}

local resumeOnUpdate = true
local function updateData()

    -- determine necessary data
    for slot, config in pairs(slots.displays) do
        for _, table in pairs(config.tables) do
            for _, row in pairs(table.rows) do
                for _, item in pairs(row) do
                    if type(item) == "table" then
                        gatheredItems[string.lower(item.name)] = ItemReport:new(item)
                    elseif type(item) == "string" then
                        gatheredItems[string.lower(item)] = ItemReport:new()
                    else
                        assert(false, "Unexpected item type: " .. tostring(item) .. " (" .. type(item) .. ")")
                    end
                end
            end
        end

        coroutine.yield()
        ::continue::
    end

    -- gather data by databank lookup (containers)
    local elementsRead = 0
    for name, data in pairs(gatheredItems) do
        if not slots.databank then
            break
        end

        -- read container data using databank values
        local containerIdListKey = name .. InventoryCommon.constants.CONTAINER_SUFFIX
        if not (slots.databank.hasKey(name) == 1 and slots.databank.hasKey(containerIdListKey) == 1) then
            goto continueContainers
        end

        -- itemName -> unitMass, unitVolume, isMaterial
        -- itemName.CONTAINER_SUFFIX -> [id, id, id, ...]
        -- CONTAINER_PREFIX.containerId -> selfMass, maxVolume, optimization

        local itemDetails = json.decode(slots.databank.getStringValue(name))

        local containerIdList = InventoryCommon.jsonToIntList(slots.databank.getStringValue(containerIdListKey))

        for _, containerId in pairs(containerIdList) do
            -- remove container ids that aren't in core.getElementIdList
            if slots.core.getElementTypeById(containerId) == "" then
                InventoryCommon.removeContainerFromDb(slots.databank, containerId)
                system.print(string.format("Container %d not found in core lookup, removing from databank...", containerId))
                goto continueContainerId
            end

            local containerDetails = json.decode(slots.databank.getStringValue(InventoryCommon.constants.CONTAINER_PREFIX .. containerId))

            local itemMass = (slots.core.getElementMassById(containerId) - containerDetails.selfMass) / containerDetails.optimization
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

            data.units = itemUnits
            data.containerData = true
            data.containerItems = data.containerItems + itemCount
            data.containerMaxItems = data.containerMaxItems + maxItems
            data.containerError = data.containerError or math.abs(itemCount - math.floor(itemCount)) > maxMassError

            elementsRead = elementsRead + 1
            if elementsRead % elementsReadPerUpdate == 0 then
                coroutine.yield()
            end

            ::continueContainerId::
        end

        ::continueContainers::
    end

    -- gather data by industry scanning
    if slots.core then
        for _, id in pairs(slots.core.getElementIdList()) do
            -- system.print(id .. ": " .. slots.core.getElementNameById(id) .. ": " .. slots.core.getElementTypeById(id))

            elementsRead = elementsRead + 1
            if elementsRead % elementsReadPerUpdate == 0 then
                coroutine.yield()
            end
        end
    end

    -- update screens
    for slot, config in pairs(slots.displays) do
        -- skip if already done
        if config.finished then
            goto continue
        end

        populateScreen(slot, config, gatheredItems)
        config.complete = true

        coroutine.yield()
        ::continue::
    end

    resumeOnUpdate = false
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