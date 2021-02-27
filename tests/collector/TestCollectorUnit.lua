#!/usr/bin/env lua
--- Tests for collector unit.start.

package.path = package.path .. ";../du-mocks/?.lua" -- add du-mocks project
package.path = package.path .. ";../du-utils/?.lua" -- add du-utils project
package.path = package.path .. ";../game-data-lua/?.lua" -- add fallback for dkjson

local lu = require("luaunit")

require("duutils.Utilities") -- require("common.Utilities")
require("common.InventoryCommon")

-- load file into a function for efficient calling
local unitStart = loadfile("./collector/collector.unit.start.lua")

local mockDatabankUnit = require("dumocks.DatabankUnit")
local mockControlUnit = require("dumocks.ControlUnit")
local mockContainerUnit = require("dumocks.ContainerUnit")

_G.TestCollectorUnit = {}

function _G.TestCollectorUnit:setup()

    self.databankMock = mockDatabankUnit:new(nil, 1)
    self.databank = self.databankMock:mockGetClosure()

    self.unitMock = mockControlUnit:new(nil, 2, "programming board")

    -- default to one item of each scanned type
    self.containerMock1 = mockContainerUnit:new(nil, 3)
    self.container1 = self.containerMock1:mockGetClosure()

    -- link all mocks by default
    self.unitMock.linkedElements["databank"] = self.databank
    self.unitMock.linkedElements["container1"] = self.container1
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
function _G.TestCollectorUnit:teardown()
    _G.slots = nil
    _G.updateTick = nil
end

--- Verify slot loader maps all elements and reports correctly.
function _G.TestCollectorUnit:testSlotMappingAuto()

    _G.unit = self.unit

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct
    lu.assertStrContains(self.printOutput, "Slot databank mapped to inventory-report-scanner databank.")
end

--- Verify slot loader verifies elements and reports correctly.
function _G.TestCollectorUnit:testSlotMappingManual()

    _G.unit = self.unit

    -- manual mapping to named slots
    _G.databank = self.databank

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct - no output on valid manual mapping
    lu.assertEquals(self.printOutput, "")
end

--- Verify error on case where nothing is available to scan.
function _G.TestCollectorUnit:testNothingToScan()

    -- reset linked elements to only databank
    self.unitMock.linkedElements = {}
    self.unitMock.linkedElements["databank"] = self.databank
    self.unit = self.unitMock:mockGetClosure()

    _G.unit = self.unit

    lu.assertErrorMsgContains("Missing containers", unitStart)
end

os.exit(lu.LuaUnit.run())
