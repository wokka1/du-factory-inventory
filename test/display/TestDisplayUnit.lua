#!/usr/bin/env lua
--- Tests for display unit.onStart.

package.path = "src/?.lua;" .. package.path -- add src directory
package.path = package.path .. ";../du-mocks/src/?.lua" -- add fallback to du-mocks project (if not installed on path)
package.path = package.path .. ";../game-data-lua/?.lua" -- add fallback for dkjson

local lu = require("luaunit")

require("common.Utilities")
local ic = require("common.InventoryCommon")
_G.json = require("dkjson")

-- load file into a function for efficient calling
local unitStart = loadfile("./src/display/display.unit.onStart.lua")

local mockControlUnit = require("dumocks.ControlUnit")
local mockCoreUnit = require("dumocks.CoreUnit")
local mockDatabankUnit = require("dumocks.DatabankUnit")
local mockContainerUnit = require("dumocks.ContainerUnit")
local mockScreenUnit = require("dumocks.ScreenUnit")

_G.TestDisplayUnit = {}

function _G.TestDisplayUnit:setup()

    self.coreMock = mockCoreUnit:new(nil, 1)
    self.core = self.coreMock:mockGetClosure()

    self.databankMock = mockDatabankUnit:new(nil, 2)
    self.databank = self.databankMock:mockGetClosure()

    self.unitMock = mockControlUnit:new(nil, 3, "programming board")

    -- link basic mocks by default
    self.unitMock.linkedElements["core"] = self.core
    self.unitMock.linkedElements["databank"] = self.databank
    self.unit = self.unitMock:mockGetClosure()

    -- define but don't populate displays list
    _G.displays = {}

    -- collect printed output for verification
    self.printOutput = ""
    _G.system = {
        print = function(output)
            self.printOutput = self.printOutput .. output .. "\n"
        end
    }
end

--- Unset all globals set/used by unit.onStart.
function _G.TestDisplayUnit:teardown()
    _G.core = nil
    _G.databank = nil
    _G.unit = nil

    _G.displays = nil
    _G.containers = nil

    _G.slots = nil
    _G.resumeWork = nil
end

--- Verify slot loader maps all elements and reports correctly.
function _G.TestDisplayUnit:testSlotMappingAuto()

    _G.unit = self.unit

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct
    lu.assertStrContains(self.printOutput, "Slot databank mapped to inventory-report databank.")
    lu.assertStrContains(self.printOutput, "Slot core mapped to inventory-report core.")
end

--- Verify slot loader verifies elements and reports correctly.
function _G.TestDisplayUnit:testSlotMappingManual()

    _G.unit = self.unit

    -- manual mapping to named slots
    _G.databank = self.databank
    _G.core = self.core

    unitStart()

    -- can't directly test mappings, slots list not global
    -- lu.assertIs(_G.slots.databank, self.databank)

    -- helper print text is correct - no output on valid manual mapping
    lu.assertEquals(self.printOutput, "")
end

os.exit(lu.LuaUnit.run())
