#!/usr/bin/env lua
--- Tests for collector unit.onStart.

package.path = "src/?.lua;" .. package.path -- add src directory
package.path = package.path .. ";../du-mocks/src/?.lua" -- add fallback to du-mocks project (if not installed on path)
package.path = package.path .. ";../game-data-lua/?.lua" -- add fallback for dkjson (if not installed on path)

local lu = require("luaunit")

require("common.Utilities")
local ic = require("common.InventoryCommon")
_G.json = require("dkjson")

-- load file into a function for efficient calling
local unitStart = loadfile("./src/collector/collector.unit.onStart.lua")

local mockDatabankUnit = require("dumocks.DatabankUnit")
local mockControlUnit = require("dumocks.ControlUnit")
local mockContainerUnit = require("dumocks.ContainerUnit")
local mockScreenUnit = require("dumocks.ScreenUnit")

local itemDatabase = {
    [947806142] = {
        id = 947806142,
        type = "material",
        unitVolume = 1.0,
        unitMass = 1.0,
        name = "OxygenPure",
        displayName = "Pure Oxygen",
        tier = 0,
    },
    [1331181119] = {
        id = 947806142,
        type = "object",
        unitVolume = 10.0,
        unitMass = 28.95,
        name = "hydraulics_1",
        displayName = "Basic Hydraulics",
        tier = 1,
    }
}

_G.TestCollectorUnit = {}

function _G.TestCollectorUnit:setup()

    self.databankMock = mockDatabankUnit:new(nil, 1)
    self.databank = self.databankMock:mockGetClosure()

    self.unitMock = mockControlUnit:new(nil, 2, "programming board")

    -- default to one item container linked
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
        end,
        getItem = function(id)
            return itemDatabase[id]
        end
    }
end

--- Unset all globals set/used by unit.onStart.
function _G.TestCollectorUnit:teardown()
    _G.databank = nil
    _G.unit = nil

    _G.slots = nil
    _G.updateTick = nil
    _G.contentUpdated = nil
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
    -- error message went to console as well
    lu.assertStrIContains(self.printOutput, "Missing containers")
end

--- Verify screen gets output when attached.
function _G.TestCollectorUnit:testScreenOutput()

    self.screenMock = mockScreenUnit:new(nil, 10)
    self.screen = self.screenMock:mockGetClosure()

    -- reset linked elements to only databank and screen
    self.unitMock.linkedElements = {}
    self.unitMock.linkedElements["databank"] = self.databank
    self.unitMock.linkedElements["screen"] = self.screen
    self.unit = self.unitMock:mockGetClosure()

    _G.unit = self.unit

    -- prime screen with data, should be cleared on start
    self.screen.setHTML("<div>Old Content</div>")

    lu.assertEquals(self.screen.getState(), 0)
    lu.assertStrIContains(self.screenMock.html, "Old Content")

    lu.assertErrorMsgContains("Missing containers", unitStart)

    -- screen enabled, base message was cleared
    lu.assertEquals(self.screen.getState(), 1)
    lu.assertNotStrIContains(self.screenMock.html, "Old Content")

    -- error message went to screen and console as well
    lu.assertStrIContains(self.printOutput, "Missing containers")
    lu.assertStrIContains(self.screenMock.html, "Missing containers")
end

--- Verify results of a container scan on expected types of contents: empty.
function _G.TestCollectorUnit:testProcessContainerEmpty()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({})

    -- intended container finished
    lu.assertStrIContains(self.printOutput, "Error: No items in container id " .. self.container1.getId())
    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- verify (lack of) result in databank
    lu.assertEquals(self.databankMock.data, {})
end

--- Verify results of a container scan on expected types of contents: material.
-- Base case: no database preload, no container optimization.
function _G.TestCollectorUnit:testProcessContainerMaterial()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    -- use oxygen for 1.0 density
    local density = 1.0
    self.containerMock1.itemsVolume = 20
    self.containerMock1.itemsMass = self.containerMock1.itemsVolume * density
    local itemName = "Pure Oxygen"

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({{ id = 947806142, quantity = self.containerMock1.itemsVolume }})

    -- intended container finished
    lu.assertStrIContains(self.printOutput, "Registered \"" .. itemName .. "\" to container id: " .. self.container1.getId())
    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- verify result in databank

    -- itemName -> unitMass, unitVolume, isMaterial
    local expectedItemData = {
        unitMass = density,
        unitVolume = 1,
        isMaterial = true
    }
    local itemNameLower = itemName:lower()
    local itemData = self.databankMock.data[itemNameLower]
    lu.assertNotNil(itemData)
    itemData = json.decode(itemData)
    lu.assertEquals(itemData, expectedItemData)

    -- itemName.containers -> [id, id, id, ...]
    local expectedContainers = {self.container1.getId()}
    local itemContainers = self.databankMock.data[itemNameLower .. ic.constants.CONTAINER_SUFFIX]
    lu.assertNotNil(itemContainers)
    itemContainers = json.decode(itemContainers)
    lu.assertEquals(itemContainers, expectedContainers)

    -- container.id -> selfMass, maxVolume, optimization
    local expectedContainerData = {
        selfMass = self.container1.getSelfMass(),
        maxVolume = self.container1.getMaxVolume(),
        optimization = 1
    }
    local containerData = self.databankMock.data[ic.constants.CONTAINER_PREFIX .. self.container1.getId()]
    lu.assertNotNil(containerData)
    containerData = json.decode(containerData)
    lu.assertEquals(containerData, expectedContainerData)
end

--- Verify results of a container scan on expected types of contents: part.
-- Base case: no database preload, no container optimization.
function _G.TestCollectorUnit:testProcessContainerPart()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    -- use hydraulics for non-1 unit mass/volume
    local unitMass = 28.95
    local unitVolume = 10
    self.containerMock1.itemsVolume = 2770
    self.containerMock1.itemsMass = self.containerMock1.itemsVolume / unitVolume * unitMass
    local itemName = "Basic Hydraulics"

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({{ id = 1331181119, quantity = self.containerMock1.itemsVolume / unitVolume }})

    -- intended container finished
    lu.assertStrIContains(self.printOutput, "Registered \"" .. itemName .. "\" to container id: " .. self.container1.getId())
    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- verify result in databank

    -- itemName -> unitMass, unitVolume, isMaterial
    local expectedItemData = {
        unitMass = unitMass,
        unitVolume = unitVolume,
        isMaterial = false
    }
    local itemNameLower = itemName:lower()
    local itemData = self.databankMock.data[itemNameLower]
    lu.assertNotNil(itemData)
    itemData = json.decode(itemData)
    lu.assertEquals(itemData, expectedItemData)

    -- itemName.containers -> [id, id, id, ...]
    local expectedContainers = {self.container1.getId()}
    local itemContainers = self.databankMock.data[itemNameLower .. ic.constants.CONTAINER_SUFFIX]
    lu.assertNotNil(itemContainers)
    itemContainers = json.decode(itemContainers)
    lu.assertEquals(itemContainers, expectedContainers)

    -- container.id -> selfMass, maxVolume, optimization
    local expectedContainerData = {
        selfMass = self.container1.getSelfMass(),
        maxVolume = self.container1.getMaxVolume(),
        optimization = 1
    }
    local containerData = self.databankMock.data[ic.constants.CONTAINER_PREFIX .. self.container1.getId()]
    lu.assertNotNil(containerData)
    containerData = json.decode(containerData)
    lu.assertEquals(containerData, expectedContainerData)
end

--- Verify results of a container scan with container optimization applied.
function _G.TestCollectorUnit:testProcessContainerOptimization()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    -- use oxygen for 1.0 density
    local optimization = 0.8
    local density = 1.0
    self.containerMock1.itemsVolume = 20
    self.containerMock1.itemsMass = self.containerMock1.itemsVolume * density * optimization
    local itemName = "Pure Oxygen"

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({{ id = 947806142, quantity = self.containerMock1.itemsVolume }})

    -- intended container finished
    lu.assertStrIContains(self.printOutput, "Registered \"" .. itemName .. "\" to container id: " .. self.container1.getId())
    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- verify result in databank

    -- item data unchanged
    -- itemName -> unitMass, unitVolume, isMaterial
    local expectedItemData = {
        unitMass = density,
        unitVolume = 1,
        isMaterial = true
    }
    local itemNameLower = itemName:lower()
    local itemData = self.databankMock.data[itemNameLower]
    lu.assertNotNil(itemData)
    itemData = json.decode(itemData)
    lu.assertEquals(itemData, expectedItemData)

    -- container.id -> selfMass, maxVolume, optimization
    local expectedContainerData = {
        selfMass = self.container1.getSelfMass(),
        maxVolume = self.container1.getMaxVolume(),
        optimization = optimization
    }
    local containerData = self.databankMock.data[ic.constants.CONTAINER_PREFIX .. self.container1.getId()]
    lu.assertNotNil(containerData)
    containerData = json.decode(containerData)
    lu.assertEquals(containerData, expectedContainerData)
end

--- Verify error behavior when a container has multiple items/materials on scan.
function _G.TestCollectorUnit:testContainerMultipleItems()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    -- preload databank with a mapping for the container
    local screwKey = "uncommon screw" .. ic.constants.CONTAINER_SUFFIX
    self.databankMock.data[screwKey] = "[" .. self.container1.getId() .. "]"

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    self.containerMock1.itemsVolume = 1
    self.containerMock1.itemsMass = 1
    local item1Name = "Pure Oxygen"

    self.containerMock1.itemsVolume = self.containerMock1.itemsVolume + 10.0
    self.containerMock1.itemsMass = self.containerMock1.itemsMass + 28.95
    local item2Name = "Basic Hydraulics"

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({
        { id = 947806142, quantity = self.containerMock1.itemsVolume },
        { id = 1331181119, quantity = self.containerMock1.itemsVolume }
    })

    -- intended container errored out, listing both items of contents
    lu.assertStrIContains(self.printOutput, "Error: Multiple item types in container id " .. self.container1.getId())
    lu.assertStrIContains(self.printOutput, item1Name)
    lu.assertStrIContains(self.printOutput, item2Name)

    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- databank cleared container mapping, didn't add anything
    local expectedDatabank = {
        [screwKey] = "[]"
    }
    lu.assertEquals(self.databankMock.data, expectedDatabank)
end

--- Verify container scan removes existing container mapping and adds to new, already existing, location.
function _G.TestCollectorUnit:testProcessContainerRemap()
    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    -- preload databank with a mapping for the container
    local screwKey = "uncommon screw" .. ic.constants.CONTAINER_SUFFIX
    self.databankMock.data[screwKey] = "[" .. self.container1.getId() .. "]"

    local function callbackFunction()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction)

    -- use oxygen for 1.0 density
    local density = 1.0
    self.containerMock1.itemsVolume = 20
    self.containerMock1.itemsMass = self.containerMock1.itemsVolume * density
    local itemName = "Pure Oxygen"
    local oxygenKey = itemName:lower() .. ic.constants.CONTAINER_SUFFIX

    -- preload databank with extra container id for new item
    self.databankMock.data[oxygenKey] = "[" .. 100 .. "]"

    lu.assertTrue(self.containerMock1.storageRequested, "Should have requested storage on initial unit.onStart run.")
    self.containerMock1:mockDoContentUpdate({{id = 947806142, quantity = self.containerMock1.itemsVolume }})

    -- intended container finished
    lu.assertStrIContains(self.printOutput, "Registered \"" .. itemName .. "\" to container id: " .. self.container1.getId())
    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")

    -- verify result in databank

    -- added new container alongside old
    -- itemName.containers -> [id, id, id, ...]
    local expectedContainers = {100, self.container1.getId()}
    local itemContainers = self.databankMock.data[oxygenKey]
    lu.assertNotNil(itemContainers)
    itemContainers = json.decode(itemContainers)
    lu.assertItemsEquals(itemContainers, expectedContainers)

    -- databank cleared existing container mapping
    lu.assertEquals(self.databankMock.data[screwKey], "[]")
end

--- Verify sequence of requesting and processing containers.
function _G.TestCollectorUnit:testProcessContainerMultiple()
    -- add second container
    self.containerMock2 = mockContainerUnit:new(nil, 4)
    self.container2 = self.containerMock2:mockGetClosure()

    self.unitMock.linkedElements["container2"] = self.container2
    self.unit = self.unitMock:mockGetClosure()

    -- initialize, map databank and container, clear auto-map output
    _G.unit = self.unit
    unitStart()
    self.printOutput = ""

    local function callbackFunction1()
        _G.contentUpdated("container1")
    end
    self.containerMock1:mockRegisterContentUpdate(callbackFunction1)
    local function callbackFunction2()
        _G.contentUpdated("container2")
    end
    self.containerMock2:mockRegisterContentUpdate(callbackFunction2)

    lu.assertTrue(self.containerMock1.storageRequested ~= self.containerMock2.storageRequested,
        "Should have requested storage on exactly one container.")

    -- determine first requested container and provide storage
    local firstContainer, firstContainerMock
    if self.containerMock1.storageRequested then
        firstContainer = self.container1
        firstContainerMock = self.containerMock1
    else
        firstContainer = self.container2
        firstContainerMock = self.containerMock2
    end
    firstContainerMock:mockDoContentUpdate({})

    -- first container finished
    lu.assertStrIContains(self.printOutput, "Error: No items in container id " .. firstContainer.getId())

    lu.assertTrue(self.containerMock1.storageRequested == self.containerMock2.storageRequested and
                      self.containerMock1.storageRequested == true, "Both containers should have been requested now.")

    -- clear output and provide second container
    self.printOutput = ""
    local secondContainer, secondContainerMock
    if self.containerMock1 == firstContainerMock then
        secondContainer = self.container2
        secondContainerMock = self.containerMock2
    else
        secondContainer = self.container1
        secondContainerMock = self.containerMock1
    end
    secondContainerMock:mockDoContentUpdate({})

    -- second container finished
    lu.assertStrIContains(self.printOutput, "Error: No items in container id " .. secondContainer.getId())

    -- scan completed
    lu.assertStrIContains(self.printOutput, "All containers complete,")
end

os.exit(lu.LuaUnit.run())
