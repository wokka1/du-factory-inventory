---------------------------------------
-- Factory Inventory: Data Collector --
--        By W3asel (1337joe)        --
---------------------------------------
-- Bundled: ${date}
-- Latest version always available here: https://du.w3asel.com/du-factory-inventory

local waitTime = 30 --export: Time between container scans.

-- localize global lookups
local slots = {}
slots.containers = {}
local Utilities = _G.Utilities
local InventoryCommon = _G.InventoryCommon

-- if not found by name will autodetect
slots.screen = screen
slots.databank = databank

-- link missing slot inputs / validate provided slots
local module = "inventory-report-scanner"
slots.screen = Utilities.loadSlot(slots.screen, "ScreenUnit", nil, module, "screen", true)
slots.databank = Utilities.loadSlot(slots.databank, "DataBankUnit", slots.screen, module, "databank")

-- clear screen, will be appending html to it as a debug output log
if slots.screen then
    slots.screen.setHTML("")
    slots.screen.activate()
end

local debugIndex = 0
local debugFontSize = 2.5
local function debugPrint(msg)
    if slots.screen then
        slots.screen.addText(0, debugIndex * debugFontSize, debugFontSize, msg)
        debugIndex = debugIndex + 1
    end
    system.print(msg)
end

local nextContainer = nil
local name
local containerCount = 0
repeat
    nextContainer, name = Utilities.findFirstSlot("Container%a+Group", slots.containers)

    if nextContainer ~= nil then
        slots.containers[name] = nextContainer
        containerCount = containerCount + 1
    end
until nextContainer == nil
if containerCount == 0 then
    local msg = "Missing containers to register."
    debugPrint(msg)
    assert(false, msg)
end

-- initialize
local containerStatus = {}
for _, container in pairs(slots.containers) do
    containerStatus[container] = {
        available = false,
        complete = false,
    }
end

-- define functions
local function processContainer(container)
    local itemsListJson = container.getItemsList()
    local itemsList = json.decode(itemsListJson)

    local id = container.getId()
    local selfMass = container.getSelfMass()
    local maxVolume = container.getMaxVolume()

    InventoryCommon.removeContainerFromDb(slots.databank, id)

    local name, quantity, unitMass, unitVolume, isMaterial
    for _, item in pairs(itemsList) do
        if name then
            debugPrint(string.format("Error: Multiple item types in container id %d: %s, %s, ...", id, name, item.name));
            containerStatus[container].complete = true
            return
        else
            name = string.lower(item.name)
            quantity = item.quantity
            unitMass = item.unitMass
            unitVolume = item.unitVolume
            isMaterial = item.type == "material"
        end
    end
    if not name then
        debugPrint(string.format("Error: No items in container id %d", id));
        containerStatus[container].complete = true
        return
    end

    -- itemName -> unitMass, unitVolume, isMaterial
    -- itemName.containers -> [id, id, id, ...]
    -- container.id -> selfMass, maxVolume, optimization

    local itemDetails = {
        unitMass = unitMass,
        unitVolume = unitVolume,
        isMaterial = isMaterial,
    }
    local itemString = json.encode(itemDetails)
    slots.databank.setStringValue(name, itemString)

    local itemContainersKey = name .. InventoryCommon.constants.CONTAINER_SUFFIX
    local currentContainers = InventoryCommon.jsonToIntList(slots.databank.getStringValue(itemContainersKey))
    table.insert(currentContainers, id)
    slots.databank.setStringValue(itemContainersKey, InventoryCommon.intListToJson(currentContainers))

    local density = container.getItemsMass() / quantity
    local containerOptimization = density / unitMass
    local containerKey = InventoryCommon.constants.CONTAINER_PREFIX .. id
    local containerDetails = {
        selfMass = selfMass,
        maxVolume = maxVolume,
        optimization = containerOptimization,
    }
    local containerString = json.encode(containerDetails)
    slots.databank.setStringValue(containerKey, containerString)

    debugPrint(string.format("Registered \"%s\" to container id: %d, optimization: %.2f", name, id, containerOptimization))

    containerStatus[container].complete = true
end

function _G.updateTick()
    for slot, container in pairs(slots.containers) do
        if not containerStatus[container].available then
            container.acquireStorage()
            break
        end
    end

    local incomplete = false
    for _, container in pairs(slots.containers) do
        if not containerStatus[container].complete then
            if containerStatus[container].available then
                processContainer(container)
            else
                incomplete = true
            end
        end
    end

    if not incomplete then
        debugPrint("All containers complete, ending from timer.")
        InventoryCommon.validateDb(slots.databank)
        unit.exit()
    end
end

function _G.storageAcquired(slot)
    containerStatus[slots.containers[slot]].available = true

    _G.updateTick()
end

unit.setTimer("update", waitTime)
_G.updateTick()
