#!/usr/bin/env lua
--- Tests for databank override unit.start.

package.path = package.path .. ";../du-mocks/?.lua" -- add du-mocks project
package.path = package.path .. ";../game-data-lua/?.lua" -- add fallback for dkjson

local lu = require("luaunit")

require("common.Utilities")
local ic = require("common.InventoryCommon")
_G.json = require("dkjson")

-- load file into a function for efficient calling
local unitStart = loadfile("./collector/databankoverride.unit.start.lua")

local mockDatabankUnit = require("dumocks.DatabankUnit")
local mockControlUnit = require("dumocks.ControlUnit")
local mockScreenUnit = require("dumocks.ScreenUnit")

_G.TestDatabankOverrideUnit = {}

function _G.TestDatabankOverrideUnit:setup()

    self.databankMock = mockDatabankUnit:new(nil, 1)
    self.databank = self.databankMock:mockGetClosure()

    self.screenMock = mockScreenUnit:new(nil, 3)
    self.screen = self.screenMock:mockGetClosure()

    self.unitMock = mockControlUnit:new(nil, 2, "programming board")

    -- link all mocks by default
    self.unitMock.linkedElements["databank"] = self.databank
    self.unitMock.linkedElements["screen"] = self.screen
    self.unit = self.unitMock:mockGetClosure()

    -- collect printed output for verification
    self.printOutput = ""
    _G.system = {
        print = function(output)
            self.printOutput = self.printOutput .. output .. "\n"
        end
    }
end

--- Unset all globals set/used by unit.start.
function _G.TestDatabankOverrideUnit:teardown()
    _G.databank = nil
    _G.screen = nil
    _G.unit = nil

    _G.slots = nil
end

--- Verify slot loader maps all elements and reports correctly.
function _G.TestDatabankOverrideUnit:testSlotMappingAuto()

    _G.unit = self.unit

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct
    lu.assertStrIContains(self.printOutput, "Slot databank mapped to inventory-report-databank-override databank.")
    lu.assertStrIContains(self.printOutput, "Slot screen mapped to inventory-report-databank-override screen.")
end

--- Verify slot loader verifies elements and reports correctly.
function _G.TestDatabankOverrideUnit:testSlotMappingManual()

    _G.unit = self.unit

    -- manual mapping to named slots
    _G.databank = self.databank
    _G.screen = self.screen

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct - no output on valid manual mapping
    lu.assertNotStrIContains(self.printOutput, "Slot databank")
    lu.assertNotStrIContains(self.printOutput, "Slot screen")
end

--- Verify screen gets output when attached.
function _G.TestDatabankOverrideUnit:testOutputScreen()

    _G.unit = self.unit

    -- prime screen with data, should be cleared on start
    self.screen.setHTML("<div>Old Content</div>")

    lu.assertEquals(self.screen.getState(), 0)
    lu.assertStrIContains(self.screenMock.html, "Old Content")

    unitStart()

    -- screen enabled, base message was cleared
    lu.assertEquals(self.screen.getState(), 1)
    lu.assertNotStrIContains(self.screenMock.html, "Old Content")

    -- output went to screen and console
    lu.assertStrIContains(self.printOutput, "Containers modified")
    lu.assertStrIContains(self.screenMock.html, "Containers modified")
end

--- Verify screen gets output when attached.
function _G.TestDatabankOverrideUnit:testInputValidation()

    _G.unit = self.unit

    unitStart()

    -- default values
    local overrideContainerOptimization = false
    local containerOptimizationSkill = 0
    local targetContainers = "all"

    -- container optimization skill errors
    overrideContainerOptimization = true
    local msg = "Container optimization skill must"

    containerOptimizationSkill = -1
    lu.assertErrorMsgContains(msg, _G.overrideDatabank, overrideContainerOptimization, containerOptimizationSkill,
        targetContainers)
    lu.assertStrIContains(self.printOutput, msg)
    lu.assertStrIContains(self.screenMock.html, msg)

    containerOptimizationSkill = 6
    lu.assertErrorMsgContains(msg, _G.overrideDatabank, overrideContainerOptimization, containerOptimizationSkill,
        targetContainers)

    containerOptimizationSkill = 0.75
    lu.assertErrorMsgContains(msg, _G.overrideDatabank, overrideContainerOptimization, containerOptimizationSkill,
        targetContainers)

    -- not checked when not overriding container optimization
    overrideContainerOptimization = false
    containerOptimizationSkill = -1
    _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    -- no error
end

--- Converts a table with json values to a lua table.
local function jsonToTable(data)
    local result = {}
    for k, v in pairs(data) do
        result[k] = json.decode(v)
    end
    return result
end

--- Verify container optimization override properly overrides where configured and to correct value.
function _G.TestDatabankOverrideUnit:testOverrideContainerOptimization()

    _G.unit = self.unit

    unitStart()

    -- default values
    local overrideContainerOptimization = false
    local containerOptimizationSkill = 0
    local targetContainers = "all"

    local actualTable, expected

    -- respects no-override
    self.printOutput = ""
    overrideContainerOptimization = false
    containerOptimizationSkill = 0
    targetContainers = "all"
    self.databankMock.data = {
        ["c.100"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":1.0}]],
        ["c.101"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":0.75}]],
    }
    expected = {
        ["c.100"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 1.0,
        },
        ["c.101"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 0.75,
        },
    }
    _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    actualTable = jsonToTable(self.databankMock.data)
    lu.assertEquals(actualTable, expected)
    lu.assertStrIContains(self.printOutput, "Containers modified: 0")

    -- override all to 1.0
    self.printOutput = ""
    overrideContainerOptimization = true
    containerOptimizationSkill = 0
    targetContainers = "all"
    self.databankMock.data = {
        ["c.100"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":1.0}]],
        ["c.101"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":0.75}]],
    }
    expected = {
        ["c.100"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 1.0,
        },
        ["c.101"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 1.0,
        },
    }
    _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    actualTable = jsonToTable(self.databankMock.data)
    lu.assertEquals(actualTable, expected)
    lu.assertStrIContains(self.printOutput, "Containers modified: 1")

    -- override all to 0.8
    self.printOutput = ""
    overrideContainerOptimization = true
    containerOptimizationSkill = 4
    targetContainers = "all"
    self.databankMock.data = {
        ["c.100"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":1.0}]],
        ["c.101"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":0.75}]],
    }
    expected = {
        ["c.100"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 0.8,
        },
        ["c.101"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 0.8,
        },
    }
    _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    actualTable = jsonToTable(self.databankMock.data)
    lu.assertEquals(actualTable, expected)
    lu.assertStrIContains(self.printOutput, "Containers modified: 2")

    -- override specific to 0.8
    self.printOutput = ""
    overrideContainerOptimization = true
    containerOptimizationSkill = 4
    targetContainers = "10"
    self.databankMock.data = {
        ["c.10"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":1.0}]],
        ["c.100"] = [[{"selfMass":1281.31,"maxVolume":12000.0,"optimization":1.0}]],
    }
    expected = {
        ["c.10"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 0.8,
        },
        ["c.100"] = {
            selfMass = 1281.31,
            maxVolume = 12000.0,
            optimization = 1.0,
        },
    }
    _G.overrideDatabank(overrideContainerOptimization, containerOptimizationSkill, targetContainers)
    actualTable = jsonToTable(self.databankMock.data)
    lu.assertEquals(actualTable, expected)
    lu.assertStrIContains(self.printOutput, "Containers modified: 1")
end

os.exit(lu.LuaUnit.run())
