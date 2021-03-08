--- Common definitions for inventory system.

-- Guard to keep this module from reinitializing any time the start event fires if placed in libraries/system slot.
if _G.InventoryCommon then
    return
end
_G.InventoryCommon = {}

local constants = {}
-- Container status will be read from core.
constants.SOURCE_CORE_CONTAINER = "core container"
-- Container status will be read directly from container by volume.
constants.SOURCE_CONTAINER_VOLUME_ONLY = "container volume"
-- suffix of item container keys, format "<item name>.c"
constants.CONTAINER_SUFFIX = ".c"
-- prefix for container metadata keys, format "c.<id>"
constants.CONTAINER_PREFIX = "c."
_G.InventoryCommon.constants = constants

function _G.InventoryCommon.jsonToIntList(json)
    local listElements = {}

    for element in string.gmatch(json, "%d+") do
        listElements[#listElements + 1] = tonumber(element)
    end

    return listElements
end

function _G.InventoryCommon.intListToJson(list)
    return string.format("[%s]", table.concat(list, ","))
end

local CONTAINERS_DB_PATTERN = string.format([["(.-%%%s)"]], constants.CONTAINER_SUFFIX) -- escape . in suffix
--- Strips the provided container id out of any items that have it listed.
function _G.InventoryCommon.removeContainerFromDb(databank, containerId)
    local allKeys = databank.getKeys()
    local containerList, prefix, suffix, replaceText
    for itemContainers in string.gmatch(allKeys, CONTAINERS_DB_PATTERN) do
        containerList = databank.getStringValue(itemContainers)

        local prefix, suffix, changed
        repeat
            prefix, suffix = string.match(containerList, "(%D)%s*" .. containerId .. "%s*(%D)")
            if not prefix then
                break
            end

            if prefix == suffix then
                replaceText = prefix
            elseif prefix == "," then
                replaceText = suffix
            elseif suffix == "," then
                replaceText = prefix
            elseif prefix == "[" and suffix == "]" then
                replaceText = "[]"
            end

            -- sanitize prefix for regex if necessary
            if prefix == "[" then
                prefix = "%["
            end

            containerList = string.gsub(containerList, prefix .. containerId .. suffix, replaceText)
            changed = true
        until not prefix

        if changed then
            databank.setStringValue(itemContainers, containerList)
        end
    end
end

--- Examines the databank, searching for duplicate keys, containers with multiple mappings, etc.
local ITEM_CONTAINER_PATTERN = ".-" .. constants.CONTAINER_SUFFIX
function _G.InventoryCommon.validateDb(databank)
    local keyCount = {}
    local containerCount = {}
    for key in string.gmatch(databank.getKeys(), "\"(.-)\"") do
        keyCount[key] = (keyCount[key] or 0) + 1

        if string.match(key, ITEM_CONTAINER_PATTERN) then
            for _, containerId in pairs(InventoryCommon.jsonToIntList(databank.getStringValue(key))) do
                containerCount[containerId] = (containerCount[containerId] or 0) + 1
            end
        end
    end
    for key, count in pairs(keyCount) do
        if count > 1 then
            system.print(string.format("Duplicate key: %s (%d)", key, count))
        end
    end
    for containerId, count in pairs(containerCount) do
        if count > 1 then
            system.print(string.format("Duplicate container mapping: %s (%d)", containerId, count))
        end
    end
end

return _G.InventoryCommon
