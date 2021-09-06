#!/usr/bin/env lua
--- Tests for InventoryCommon.

package.path = "src/?.lua;" .. package.path -- add src directory
package.path = package.path .. ";../du-mocks/src/?.lua" -- add fallback to du-mocks project (if not installed on path)
package.path = package.path .. ";../game-data-lua/?.lua" -- add fallback for dkjson (if not installed on path)

local lu = require("luaunit")
local json = require("dkjson")

local mockDatabankUnit = require("dumocks.DatabankUnit")

local ic = require("common.InventoryCommon")

_G.TestInventoryCommon = {}

function _G.TestInventoryCommon.testJsonToIntList()
    local jsonStr, expected, actual

    -- empty
    jsonStr = "[]"
    expected = json.decode(jsonStr)
    actual = ic.jsonToIntList(jsonStr)
    lu.assertEquals(actual, expected)

    -- single element
    jsonStr = "[1]"
    expected = json.decode(jsonStr)
    actual = ic.jsonToIntList(jsonStr)
    lu.assertEquals(actual, expected)

    -- multiple elements
    jsonStr = "[1,2]"
    expected = json.decode(jsonStr)
    actual = ic.jsonToIntList(jsonStr)
    lu.assertEquals(actual, expected)

    -- handles spaces
    jsonStr = "[1, 2]"
    expected = json.decode(jsonStr)
    actual = ic.jsonToIntList(jsonStr)
    lu.assertEquals(actual, expected)
end

function _G.TestInventoryCommon.testIntListToJson()
    local list, expected, actual

    list = {}
    expected = json.encode(list)
    actual = ic.intListToJson(list)
    lu.assertEquals(actual, expected)

    list = {
        [1] = 1
    }
    expected = json.encode(list)
    actual = ic.intListToJson(list)
    lu.assertEquals(actual, expected)

    list = {
        [1] = 1,
        [2] = 2
    }
    local time1, time2, time3
    expected = json.encode(list)
    actual = ic.intListToJson(list)
    lu.assertEquals(actual, expected)
end

--- Ensures removing a container id from the db works in all cases.
function _G.TestInventoryCommon.testRemoveContainerFromDb()
    local databankMock = mockDatabankUnit:new(nil, 1)
    local databank = databankMock:mockGetClosure()

    local resources = {"pure aluminium", "pure carbon", "pure iron", "pure silicon"}
    local resourceKeys = {}
    for i, resource in pairs(resources) do
        resourceKeys[i] = resource .. ic.constants.CONTAINER_SUFFIX
    end

    local containerId, expected, actual

    -- key not found, no-op
    containerId = 2
    databankMock.data = {
        [resourceKeys[1]] = nil,
        [resourceKeys[2]] = "[3]",
        [resourceKeys[3]] = "[4,5]",
        [resourceKeys[4]] = "[]"
    }
    expected = {
        [resourceKeys[1]] = nil,
        [resourceKeys[2]] = "[3]",
        [resourceKeys[3]] = "[4,5]",
        [resourceKeys[4]] = "[]"
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)

    -- key found alone
    containerId = 2
    databankMock.data = {
        [resourceKeys[1]] = "[2]"
    }
    expected = {
        [resourceKeys[1]] = "[]"
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)

    -- key repeated alone
    containerId = 2
    databankMock.data = {
        [resourceKeys[1]] = "[2,2]"
    }
    expected = {
        [resourceKeys[1]] = "[]"
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)

    -- key found with other combinations
    containerId = 2
    databankMock.data = {
        [resourceKeys[1]] = "[2,3]",
        [resourceKeys[2]] = "[4,2,5]",
        [resourceKeys[3]] = "[6,2]"
    }
    expected = {
        [resourceKeys[1]] = "[3]",
        [resourceKeys[2]] = "[4,5]",
        [resourceKeys[3]] = "[6]"
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)

    -- key is substring of other container
    containerId = 2
    databankMock.data = {
        [resourceKeys[1]] = "[2]",
        [resourceKeys[2]] = "[22]",
        [resourceKeys[3]] = "[2,22]",
        [resourceKeys[4]] = "[22,2]"
    }
    expected = {
        [resourceKeys[1]] = "[]",
        [resourceKeys[2]] = "[22]",
        [resourceKeys[3]] = "[22]",
        [resourceKeys[4]] = "[22]"
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)

    -- failing case from live testing
    containerId = 567
    databankMock.data = {
        ["basic fixation"] = [[{"unitMass":1.12,"unitVolume":1.0,"isMaterial":false}]],
        ["basic fixation.c"] = "[175]",
        ["c.175"] = [[{"maxVolume":1200.0,"optimization":1.0,"selfMass":229.09}]],
        ["advanced screw"] = [[{"unitMass":8.14,"unitVolume":1.0,"isMaterial":false}]],
        ["advanced screw.c"] = "[567]",
        ["c.567"] = [[{"maxVolume":1200.0,"optimization":1.0,"selfMass":229.09}]]
    }
    expected = {
        ["basic fixation"] = [[{"unitMass":1.12,"unitVolume":1.0,"isMaterial":false}]],
        ["basic fixation.c"] = "[175]",
        ["c.175"] = [[{"maxVolume":1200.0,"optimization":1.0,"selfMass":229.09}]],
        ["advanced screw"] = [[{"unitMass":8.14,"unitVolume":1.0,"isMaterial":false}]],
        ["advanced screw.c"] = "[]",
        ["c.567"] = [[{"maxVolume":1200.0,"optimization":1.0,"selfMass":229.09}]]
    }
    ic.removeContainerFromDb(databank, containerId)
    lu.assertEquals(databankMock.data, expected)
end

--- Verifies validateDb catches known problems.
function _G.TestInventoryCommon.testValidateDb()
    local databankMock = mockDatabankUnit:new(nil, 1)
    local databank = databankMock:mockGetClosure()

    local systemPrint = ""
    _G.system = {}
    function system.print(msg)
        systemPrint = systemPrint .. msg .. "\n"
    end

    -- duplicate keys
    local hackedDatabank = {
        getStringValue = databank.getStringValue
    }
    function hackedDatabank.getKeys()
        local keysList = {}
        for key,_ in pairs(databankMock.data) do
            for i = 1, databankMock.data[key] do
                keysList[#keysList + 1] = string.format([["%s"]], key)
            end
        end
        return "[" .. table.concat(keysList, ",") .. "]"
    end

    systemPrint = ""
    databankMock.data = {
        key1 = 1,
        key2 = 2
    }
    ic.validateDb(hackedDatabank)
    lu.assertStrMatches(systemPrint, "Duplicate key: key2 %(2%)[%c]*")

    -- duplicate containers on different keys
    systemPrint = ""
    databankMock.data = {
        ["key1.c"] = "[1,2]",
        ["key2.c"] = "[2]"
    }
    ic.validateDb(databank)
    lu.assertStrMatches(systemPrint, "Duplicate container mapping: 2 %(2%)[%c]*")

    -- duplicate containers on same keys
    systemPrint = ""
    databankMock.data = {
        ["key3.c"] = "[3,3,3]",
    }
    ic.validateDb(databank)
    lu.assertStrMatches(systemPrint, "Duplicate container mapping: 3 %(3%)[%c]*")

    -- no warning based on item data
    systemPrint = ""
    databankMock.data = {
        ["basic chemical industry m"] = [[{"unitMass":2302.34,"unitVolume":479.2,"isMaterial":false}]],
        ["basic refiner m"] = [[{"unitMass":2302.34,"unitVolume":479.2,"isMaterial":false}]]
    }
    ic.validateDb(databank)
    lu.assertEquals(systemPrint, "")
end

os.exit(lu.LuaUnit.run())
