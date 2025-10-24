----------------------------------------
-- Factory Inventory: Display Manager --
--        By W3asel (1337joe)         --
----------------------------------------
-- Bundled: ${date}
-- Latest version always available here: https://du.w3asel.com/du-factory-inventory

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
unit.hideWidget()

-- define display constants and functions
local RENDER_SCRIPT = [[${file:display.screen.lua}]]

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
    for slot, config in pairs(slots.displays) do
        for _, table in pairs(config.tables) do
            for _, row in pairs(table.rows) do
                for _, item in pairs(row) do
                    if type(item) == "table" then
                        local report = ItemReport:new(item)
                        gatheredItems[string.lower(item.name)] = report

                        if item.source == InventoryCommon.constants.SOURCE_CONTAINER_VOLUME_ONLY then
                            scanContainer(item, report)
                        end
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
            if slots.core.getElementDisplayNameById(containerId) == "" then
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
            -- data.containerData = true
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