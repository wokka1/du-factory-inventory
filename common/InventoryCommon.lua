--- Common definitions for inventory system.

-- Guard to keep this module from reinitializing any time the start event fires if placed in libraries/system slot.
if _G.InventoryCommon then
    return
end
_G.InventoryCommon = {}

local constants = {}
-- Container status will be read from core.
constants.CORE = "core"
-- Container status will be read from receiver.
constants.RECEIVER = "receiver"
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

        prefix, suffix = string.match(containerList, "(%D)%s*" .. containerId .. "%s*(%D)")

        if prefix then
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

            databank.setStringValue(itemContainers, string.gsub(containerList, prefix .. containerId .. suffix, replaceText))
        end
    end
end

return _G.InventoryCommon
