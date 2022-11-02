#!/usr/bin/env lua
--- Tests on display.screen.

package.path = "src/?.lua;" .. package.path -- add src directory
package.path = package.path .. ";../du-mocks/src/?.lua" -- add fallback to du-mocks project (if not installed on path)
package.path = "../game-data-lua/?.lua;" .. package.path -- add link to Dual Universe/Game/data/lua/ directory

-- set file locations
local SCREEN_DIR = "src/display/screen/"
local RENDER_SCRIPT = "src/display/display.screen.lua"
local OUTPUT_DIR = "test/results/images/"
local OUTPUT_FILE = OUTPUT_DIR .. "DisplayScreenAll.html"

require("common.InventoryCommon")
local lu = require("luaunit")
local rs = require("dumocks.RenderScript")

_G.json = require("dkjson")

local SVG_WRAPPER_TEMPLATE = [[<li><p>%s<br>%s</p></li>]]

_G.TestDisplayScreen = {
    allSvg = {
[[
<!DOCTYPE html>
<html>
<head>
    <style>
        ul.gallery {
            list-style-type: none;
            padding: 0;
            margin: 5px;
            display: grid;
            grid-gap: 20px 5px;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            grid-template-rows: repeat(300px);
        }
        
        ul.gallery svg {
            width: 100%;
            height: 100%;
            max-height: 450px;
        }
    </style>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fira+Mono&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Montserrat&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Play&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Condensed&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono&display=swap" rel="stylesheet">
</head>
<body>
    <ul class="gallery">
]]
    }
}

function _G.TestDisplayScreen:tearDown()
    local closingTags = [[

    </ul>
</body>
</html>
]]
    -- save as file
    local outputHandle, errorMsg = io.open(OUTPUT_FILE, "w")
    if errorMsg then
        error(errorMsg)
    else
        io.output(outputHandle):write(table.concat(self.allSvg, "\n"))
        io.output(outputHandle):write(closingTags)
        outputHandle:close()
    end
end

local function loadScreenConfig(name)
    local inputFile = SCREEN_DIR .. name .. ".lua"
    local inputHandle = io.open(inputFile, "rb")
    if not inputHandle then
        error("File not found: " .. inputFile)
    end
    local fileContents = io.input(inputHandle):read("*all")
    inputHandle:close()

    -- remove du-bundler pattern to make valid lua
    fileContents = string.gsub(fileContents, "${slotName}", "\"slotName\"", 1)

    _G.displays = nil
    local fileScript = load(fileContents)
    fileScript()

    return _G.displays["slotName"]
end

local prefix = 0
function _G.TestDisplayScreen:renderConfiguration(name, configuration)

    prefix = prefix + 1
    local renderScript = rs:new(nil, 1024, 613, prefix)

    renderScript.fontStrings = {
        ["Play-Bold"] = {
            ["%"] = {20.625 / 20, 18.125 / 20},
        }
    }

    local environment = renderScript:mockGetEnvironment()

    environment.constants = InventoryCommon.constants
    configuration(environment)

    local script = loadfile(RENDER_SCRIPT, "t", environment)

    script()

    local actual = renderScript:mockGenerateSvg()
    lu.assertFalse(actual:len() == 0, string.format("%s produced no output.", name))

    -- save as file
    local outputHandle, errorMsg = io.open(OUTPUT_DIR .. name .. ".svg", "w")
    if errorMsg then
        error(errorMsg)
    else
        io.output(outputHandle):write(actual)
        outputHandle:close()
    end

    self.allSvg[#self.allSvg + 1] = string.format(SVG_WRAPPER_TEMPLATE, name, actual)
end

function _G.TestDisplayScreen:testOrePure()
    local name = "ore-pure"
    local screenConfig = loadScreenConfig(name)

    local configuration = function(environment)
        environment.screenConfig = screenConfig
        environment.itemData = {
            ["hematite"]={["containerItems"]=471.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["coal"]={["containerItems"]=2382.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["bauxite"]={["containerItems"]=4266.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["quartz"]={["containerItems"]=3909.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["pure aluminium"]={["name"]="Aluminium",["containerItems"]=10000.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["pure oxygen"]={["name"]="Oxygen",["containerItems"]=6000.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["ore overflow"]={["containerMaxItems"]=179200.0,["label"]="",["units"]="L",["containerItems"]=165000,["name"]="ore overflow"},
        }
    end
    self:renderConfiguration(name, configuration)
end

function _G.TestDisplayScreen:testProductIntermediate()
    local name = "product-intermediate"
    local screenConfig = loadScreenConfig(name)

    local configuration = function(environment)
        environment.screenConfig = screenConfig
        environment.itemData = {
            ["basic pipe"]={["label"]="",["containerItems"]=251.0,["targetCount"]=800,["name"]="Basic Pipe",["units"]="",["containerMaxItems"]=1400},
            ["basic component"]={["label"]="",["containerItems"]=515.0,["targetCount"]=800,["name"]="Basic Component",["units"]="",["containerMaxItems"]=2800},
            ["hematite"]={["containerItems"]=4718.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["basic fixation"]={["label"]="",["containerItems"]=275.0,["targetCount"]=400,["name"]="Basic Fixation",["units"]="",["containerMaxItems"]=1400},
            ["silumin product"]={["label"]="Silumin",["containerItems"]=1383.5,["targetCount"]=6000,["name"]="Silumin Product",["units"]="L",["containerMaxItems"]=1400.0},
            ["basic screw"]={["label"]="",["containerItems"]=1307.0,["targetCount"]=1200,["name"]="Basic Screw",["units"]="",["containerMaxItems"]=1400},
            ["polycarbonate plastic product"]={["label"]="Polycarb",["containerItems"]=1398.0,["targetCount"]=6000,["name"]="Polycarbonate Plastic Product",["units"]="L",["containerMaxItems"]=1400.0},
            ["glass product"]={["label"]="Glass",["containerItems"]=1389.75,["targetCount"]=6000,["name"]="Glass Product",["units"]="L",["containerMaxItems"]=1400.0},
            ["coal"]={["containerItems"]=2382.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["al-fe alloy product"]={["label"]="Al-Fe Alloy",["containerItems"]=1330.0,["targetCount"]=6000,["name"]="Al-Fe Alloy Product",["units"]="L",["containerMaxItems"]=1400.0},
            ["steel product"]={["label"]="Steel",["containerItems"]=1386.25,["targetCount"]=6000,["name"]="Steel Product",["units"]="L",["containerMaxItems"]=1400.0},
            ["bauxite"]={["containerItems"]=4266.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["quartz"]={["containerItems"]=3909.0,["containerMaxItems"]=11200.0,["units"]="L"},
            ["basic connector"]={["label"]="",["containerItems"]=510.0,["targetCount"]=400,["name"]="Basic Connector",["units"]="",["containerMaxItems"]=1750},
        }
    end
    self:renderConfiguration(name, configuration)
end

function _G.TestDisplayScreen:testHonestVifsRow1()
    local name = "honest-vifs.row1"
    local screenConfig = loadScreenConfig(name)

    local configuration = function(environment)
        environment.screenConfig = screenConfig
        environment.itemData = {}
    end
    self:renderConfiguration(name, configuration)
end

function _G.TestDisplayScreen:testHonestVifsRow2()
    local name = "honest-vifs.row2"
    local screenConfig = loadScreenConfig(name)

    local configuration = function(environment)
        environment.screenConfig = screenConfig
        environment.itemData = {}
    end
    self:renderConfiguration(name, configuration)
end

function _G.TestDisplayScreen:testScreenOutput()
    local renderScript = rs:new()
    local environment = renderScript:mockGetEnvironment()

    local script, message = loadfile(SCREEN_DIR .. "test.lua", "t", environment)
    if not script then
        lu.skip("Failed to load test.lua: " .. message)
    end

    script()

    self.allSvg[#self.allSvg + 1] = string.format(SVG_WRAPPER_TEMPLATE, "test file", renderScript:mockGenerateSvg())
end

os.exit(lu.LuaUnit.run())
