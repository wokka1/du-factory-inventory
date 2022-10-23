------------------------------------------
-- Factory Inventory: Databank Override --
--          By W3asel (1337joe)         --
------------------------------------------
-- Bundled: ${date}
-- Latest version always available here: https://du.w3asel.com/du-factory-inventory

-- user configuration
local overrideContainerOptimization = false --export: Set to true to override container optimization.
local containerOptimizationSkill = 0 --export: Level of container optimization to apply: 0-5 skills trained
local targetContainers = "all" --export: "all" for all containers, or (in quotes) a comma-separated list of container IDs to update

-- localize global lookups
local slots = {}
local Utilities = _G.Utilities
local InventoryCommon = _G.InventoryCommon

-- if not found by name will autodetect
slots.screen = screen
slots.databank = databank

-- link missing slot inputs / validate provided slots
local module = "inventory-report-databank-override"
slots.screen = Utilities.loadSlot(slots.screen, "ScreenUnit", nil, module, "screen", true)
slots.databank = Utilities.loadSlot(slots.databank, "DataBankUnit", slots.screen, module, "databank")

-- clear screen, will be appending html to it as a debug output log
if slots.screen then
    slots.screen.setHTML("")
    slots.screen.activate()
end

local debugIndex = 0
local debugFontSize = 2.5
local function allOutputPrint(msg)
    if slots.screen then
        slots.screen.addText(0, debugIndex * debugFontSize, debugFontSize, msg)
        debugIndex = debugIndex + 1
    end
    system.print(msg)
end

-- define operation in a function for testability
local CONTAINER_KEY_PATTERN = "^" .. string.gsub(InventoryCommon.constants.CONTAINER_PREFIX, "%.", "%%.") .. "(%d+)" -- escape "." prefix
function _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    -- Validate user inputs, printing statement and throwing exception on problem.
    if overrideContainerOptimization and (containerOptimizationSkill < 0 or containerOptimizationSkill > 5 or
        string.match(tostring(containerOptimizationSkill), "%.")) then
        local msg = string.format("Container optimization skill must be an integer in range [0,5]: %s",
                        containerOptimizationSkill)
        allOutputPrint(msg)
        error(msg)
    end

    -- skill to value calculation
    local containerOptimizationLevel = 1 - containerOptimizationSkill * 0.05
    -- extract container ids from list
    local targetContainerList = {}
    if targetContainers == "all" then
        targetContainerList = nil
    else
        for match in string.gmatch(targetContainers, "%d+") do
            targetContainerList[match] = true
        end
    end

    local modifiedContainers = 0

    for key in string.gmatch(slots.databank.getKeys(), "\"(.-)\"") do
        local containerId = string.match(key, CONTAINER_KEY_PATTERN)
        if containerId and ((not targetContainerList) or targetContainerList[containerId]) then

            local containerData = json.decode(slots.databank.getStringValue(key))

            -- only update if different
            if overrideContainerOptimization and containerData.optimization ~= containerOptimizationLevel then
                containerData.optimization = containerOptimizationLevel
                local containerDataJson = json.encode(containerData)
                slots.databank.setStringValue(key, containerDataJson)

                allOutputPrint(string.format("Updated container id %s: %s", containerId, containerDataJson))
                modifiedContainers = modifiedContainers + 1
            end
        end
    end

    allOutputPrint("Containers modified: " .. modifiedContainers)
end

_G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)

unit.exit()
