# DU Factory Inventory

Configurable, screen-based factory inventory monitor.

**TODO: pictures**

## Design

**Goal:** Create an easily customizable display for the inventory of various parts and materials held by a factory while minimizing the need to directly link to containers. Avoid relying on container/industry unit naming if possible.

**Implementation:**

1. Data Collector: Script that can be run to collect data and store it in a databank for reference by the display.
    1. Scan containers to store: item metadata, containers by item they hold, container metadata (max volume, container optimization, self mass).
2. Display: Script that links to databank, core, and displays to provide visual output of inventory status.
    1. Each screen slot has a ```start()``` filter that maps a display template onto the slot name.
    2. Containers may be linked directly to the display programming board to support mixed contents by reading/displaying only volume.
    3. Default behavior is to update once on startup, then exit. If a manual switch is used to enable the board and linked to the board the programming board will disable the button on stop. A detection zone may be linked to the switch to automatically enable it when a player walks up.

## Getting Started

### Standard Configuration Element Requirements:

* 2x Programming Board
* 1x Databank
* 1x Screen
* 1x Manual Switch (optional)

### Steps:

#### Display Setup

1. Install the display programming board and copy the [base display script](https://du.w3asel.com/du-factory-inventory/templates/template.display.base.json) to it. Make sure you copy the raw data, not your browser's JSON formatted page.
    1. You should get a "Lua script loaded" confirmation message. If this is not the case try pasting the JSON in notepad to confirm that the right data is in the clipboard.
2. Link the named slots to the appropriate elements: Core, Databank, and Manual Switch if using one to turn on the programming board (use the link tool right-click -> Select an OUT plug to link to... option to specify what link is used). Alternately, you can use [this version of the script](https://du.w3asel.com/du-factory-inventory/templates/template.display.blank.json) and link any slot to any element for it to autodetect slot assignment on startup, though you'll still need to track which slots are used for what displays as detailed in the next step.
3. Select the desired templates to add from the [display/screen](display/screen) directory. **TODO create and link to template images page**
    1. Link a display to put the template on to the programming board.
    2. Open the programming board (right-click -> Advanced -> Edit Lua script) and select the slot that links the new display. You may want to rename the slot for clarity, but make sure you don't add spaces or punctuation in the slot name.
    3. Click "+ Add Filter" at the bottom of the filter panel, then mouse over the three dots to the left of the filter and select "start".
    4. Paste the contents of the template you chose into the Lua Editor panel.
    5. **Important:** Scroll to the bottom of the template and replace ```${slotName}``` with the actual name of the slot you are adding to.
    6. Click the "Apply" button to save your changes and close the programming board.
4. Activate the programming board (you must be out of build mode to activate it directly). It should turn on the display, render the template with no data, and shut down. To add data go through the data collector steps below.

#### Data Collector Setup

1. Install the data collector programming board and copy the [data collector script](https://du.w3asel.com/du-factory-inventory/templates/template.collector.json) to it. Make sure you copy the raw data, not your browser's JSON formatted page.
    1. You should get a "Lua script loaded" confirmation message. If this is not the case try pasting the JSON in notepad to confirm that the right data is in the clipboard.
    2. I recommend renaming this programming board to indicate what it is (such as "Inventory Registration"), as the script may take some time to run when registering many containers and it will leave the widget visible as a reminder not to get out of load range while it works.
2. Link the board to the databank that is already connected to the display programming board. You should get a popup for "Slot Compatibility Check", click "yes" to proceed.
3. Link the board to containers that hold items that you want to show on the display (up to nine containers can be linked at a time). If using container hubs link to the hub instead of the individual containers.
4. Activate the programming board (you must be out of build mode to activate it directly). It should print out a series of message telling you what item name is linked to what container id and shut down.
    1. Containers must contain only the item that they're meant to hold for the container to register properly. Otherwise an error message will print to the Lua console notifying you of what the problem with the container is and you will need to rerun the script once it's been resolved.
    2. If too many queries have been made to the container API (the limit is ten every five minutes), you'll get an error message printed to the Lua console to that effect and the script will continue running. It will retry the query every thirty seconds until it succeeds, which may take up about five minutes if this is the only container script running or longer if you have multiple going at the same time. You can relog to clear the timeout, or just wait for it to finish.
    3. You may optionally link the board to a screen to get the normal console log printed to a display (useful when using through a surrogate session). If the text runs off the display edit the display to view it. This will reduce the number of containers that can be scanned at a time by one.
5. Return to your display programming board and activate it, the registered containers should now show their contents on the display.

## Display Templates

Template documentation isn't a priority while I'm actively developing, for now look through examples in [display/screen](display/screen).

**TODO detail this, provide sample template with all options specified**

Many attributes can be applied at any level and will inherit downward, such as ```countOffset```, which specifies in pixels where in the row the current count is displayed (item label is on the left, percent of target is on the right). If applied at the top of the screen config it will apply to all tables and item rows, unless the specific table or item row overrides it with a different value.

If you aren't up to building a custom display yourself and want to commission a display to match your needs contact me on discord (info below) and we can try to work something out.

## Troubleshooting

### Container Optimization not registering properly / incorrect counts on optimized containers

There are cases where items in a container placed with the Container Optimization skill don't have their mass reduced. The scanner can only detect the container optimization applied to the container by the mass reduction, so it won't detect the proper level of optimization, throwing off the counts when the mass reduction kicks in.

The presense of this bug can be detected by the player by inspecting an item in an optimized container and comparing the stack mass with the container mass: assuming only one item stack is present if they match then the container optimization isn't applied. Getting the game to register the container optimization seems to be as simple as picking up the item that is not reduced and moving it to a different slot in the container.

The simple fix for this is to reconnect the scanning programming board once the optimization is applied and rescanning it, though if it happened to many containers this can be a hassle.

Alternately, you can run the [Databank Override script](https://du.w3asel.com/du-factory-inventory/templates/template.databankoverride.json) to fix any/all containers by directly overriding the databank contents for them. Simply install the linked script to a programming board, then edit lua parameters (right-click -> Advanced -> Edit Lua parameters), check the box for "overrideContainerOptimization", set the desired skill level (0-5), and either enter the container IDs (in quotes) or "all" for targetContainers to specify what to update.

## Building from a Template

This project is designed to be used with my other Dual Universe project [DU Bundler](https://github.com/1337joe/du-bundler), which can be installed by calling `luarocks install du-bundler`.

Documentation of the bundler is at the above link, but to put it simply you need to be able to run Lua scripts and simply call `du-bundler template.json` (with appropriate paths for file locations) and it will build a json configuration based on the template. On Linux this can be piped to `xclip -selection c` to put it directly on the clipboard, while on Windows piping to `clip.exe` should do the same thing. Alternately, you can write it to a file and copy from there.

If you don't have a Lua runtime set up the easiest solution is to copy from the configurations hosted on the [project page on my website](https://du.w3asel.com/du-factory-inventory/). Each template included in the repository is built automatically on update and uploaded there. The alternative is manually replacing the tags (`${tag}`) according to the rules of the templater.

## Developer Dependencies

Luarocks can be used to install all dependencies: `luarocks install --only-deps du-factory-inventory-scm-0.rockspec`

* dkjson - Used for testing of json data and for json serialization/deserialization in-game. This will fall back to (from the project root) `../game-data-lua` if dkjson isn't installed.

* Dual Universe/Game/data/lua: For automated testing without installing dkjson, link or copy your C:\ProgramData\Dual Universe\Game\data\lua directory to ../game-data-lua relative to within the root directory of the project.

* [luaunit](https://github.com/bluebird75/luaunit): For automated testing.

* [luacov](https://keplerproject.github.io/luacov/): For tracking code coverage when running all tests. Can be removed from `runTests.sh` if not desired. To view results using luacov-html (which is a separate package) simply run `luacov -r html` after running tests and open `luacov-html/index.html`.

* [DU Mocks](https://github.com/1337joe/du-mocks): For automated testing. This will fall back to (from the project root) `../du-mocks` if not installed.

* [du-bundler](https://github.com/1337joe/du-bundler): For exporting templates to json to paste into Dual Universe.

## Support

If you encounter bugs or any of my instructions don't work either send me a message or file a GitHub Issue (or fork the project, fix it, and send me a pull request).

Discord channel: [du-ship-displays on DU Open Source Initiative](https://discord.gg/uhXRgw86k7)

Discord: 1337joe#6186

In-Game: W3asel

My game/coding time is often limited so I can't promise a quick response.
