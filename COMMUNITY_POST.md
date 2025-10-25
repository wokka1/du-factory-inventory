# Container API Issue - onContentUpdate Event Never Fires

## Summary
The `onContentUpdate` event does not fire after calling `updateContent()` on ItemContainer, making it impossible to use the documented container content API pattern.

## Environment
- Game Version: [Current DU version]
- Container Type: ItemContainer (slot8, ID 31)
- Programming Board: Standard Lua configuration

## Expected Behavior (from API docs)

According to the official API documentation:
```lua
--- Send a request to get an update of the content of the container
--- The onContentUpdate event is emitted by the container when the content is updated.
function container.updateContent() end

--- Emitted when the container content is updated
container.onContentUpdate = Event:new()
```

**Expected flow:**
1. Call `container.updateContent()`
2. Wait for `onContentUpdate` event to fire
3. Call `container.getContent()` to retrieve updated content

## Actual Behavior

**The `onContentUpdate` event never fires**, even after waiting well past the 30-second cooldown period.

## Test Results

Created a diagnostic test that:
1. Calls `updateContent()`
2. Registers an `onContentUpdate` event handler
3. Waits 35 seconds
4. Checks if the event fired

### Output:
```
Found slot8: Container ID 31
Class: ItemContainer
===================================
DIAGNOSTIC TEST
===================================

[0.0s] TEST 1: getContent() without updateContent()
[0.0s] Items: 0

[0.0s] TEST 2: Call updateContent()
[0.0s] Result: 8.2013135
[0.0s] COOLDOWN: 8.20s remaining

[0.0s] TEST 3: getContent() immediately after
[0.0s] Items: 0

[0.0s] TEST 4: Monitoring for onContentUpdate events...
[0.0s] Waiting 35 seconds to see if event fires...
[0.0s] (Event handler registered for slot8)

[35.0s] TEST 5: Final getContent() check
[35.0s] Items: 0

===================================
[35.0s] DIAGNOSTIC COMPLETE
[35.0s] onContentUpdate events: 0
===================================
```

### Event Handler Configuration
```json
{
    "code": "_G.handleContentUpdate()",
    "filter": {
        "signature": "onContentUpdate()",
        "slotKey": "7"
    }
}
```

## Impact

This makes the container content API (`updateContent()/getContent()`) unusable for real-time inventory scanning, as there's no way to know when the cache has been updated.

## Workaround

Community scripts use `core.getElementMassById()` instead:
```lua
local containerMass = core.getElementMassById(containerId)
local contentMass = containerMass - containerSelfMass
local quantity = contentMass / itemUnitMass
```

This works but requires:
- Knowing the container's self-mass
- Knowing the item's unit mass
- Container contains only one item type

## Questions

1. Is `onContentUpdate` known to be broken?
2. Is there an alternative way to detect when `updateContent()` completes?
3. Is there documentation on the correct usage pattern that actually works?
4. Should the API documentation be updated to reflect actual behavior?

## Test Files

Full diagnostic test code available at: [your repo link]

---

Has anyone successfully used `updateContent()/getContent()` with the `onContentUpdate` event? If so, what's different about your configuration?
