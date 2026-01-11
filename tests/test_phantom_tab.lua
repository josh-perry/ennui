-- Test to reproduce phantom tab issue
package.path = package.path .. ";./tests/lib/?.lua;./ennui/?.lua;./ennui/test/?.lua;./widgets/?.lua;./?.lua"

-- Mock LÖVE environment if needed
if not love then
    love = {
        graphics = {
            getWidth = function() return 1024 end,
            getHeight = function() return 768 end,
            setColor = function() end,
            rectangle = function() end,
            print = function() end,
            line = function() end,
        },
        mouse = {
            getPosition = function() return 0, 0 end,
        }
    }
end

local DockSpace = require("dockspace")
local Widget = require("widget")
local DockValidator = require("dock_validator")

print("\n" .. string.rep("=", 80))
print("TEST: Phantom Tab Reproduction")
print(string.rep("=", 80) .. "\n")

-- Create DockSpace
local dockSpace = DockSpace.new()
dockSpace:setSize(1024, 768)

-- Create 3 test widgets
local w1 = Widget.new()
w1:setId("widget_1")
w1:setSize(200, 150)
dockSpace:addChild(w1)

local w2 = Widget.new()
w2:setId("widget_2")
w2:setSize(200, 150)
dockSpace:addChild(w2)

local w3 = Widget.new()
w3:setId("widget_3")
w3:setSize(200, 150)
dockSpace:addChild(w3)

-- Get center drop zone
local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
local centerZone = nil
for _, z in ipairs(zones) do
    if z.type == "center" then
        centerZone = z
        break
    end
end

print("\n--- Step 1: Dock w1 to center (creates leaf with 1 widget) ---")
dockSpace:dock(w1, centerZone)
print("Children count:", #dockSpace.children)
print()

print("--- Step 2: Dock w2 to center (adds to same node, creates TabBar) ---")
dockSpace:dock(w2, centerZone)
print("Children count:", #dockSpace.children)
print()

print("--- Step 3: Dock w3 to LEFT (creates split) ---")
local leftZone = {type = "left", targetNode = dockSpace.dockTree}
dockSpace:dock(w3, leftZone)
dockSpace:invalidateLayout()
print("Children count:", #dockSpace.children)
print()

print("--- Step 4: Undock w3 (left side becomes empty) ---")
print("Before undock:")
print("  dockTree:", dockSpace.dockTree)
print("  dockTree isSplit:", dockSpace.dockTree:isSplit())
print("  dockTree leftChild:", dockSpace.dockTree.leftChild)
print("  dockTree rightChild:", dockSpace.dockTree.rightChild)
if dockSpace.dockTree.leftChild then
    print("  dockTree.leftChild dockedWidgets:", #dockSpace.dockTree.leftChild.dockedWidgets)
end
if dockSpace.dockTree.rightChild then
    print("  dockTree.rightChild dockedWidgets:", #dockSpace.dockTree.rightChild.dockedWidgets)
end

dockSpace:undock(w3)
dockSpace:invalidateLayout()
print("\nAfter undock:")
print("  dockTree:", dockSpace.dockTree)
print("  dockTree isSplit:", dockSpace.dockTree:isSplit())
print("  dockTree leftChild:", dockSpace.dockTree.leftChild)
print("  dockTree rightChild:", dockSpace.dockTree.rightChild)
print("  dockTree dockedWidgets:", #dockSpace.dockTree.dockedWidgets)
print("  dockTree.tabBar:", dockSpace.dockTree.tabBar)
print("Children count:", #dockSpace.children)
print()

print("--- Step 5: Call invalidateLayout to trigger updateTabBars ---")
dockSpace:invalidateLayout()
print()

print("--- Step 6: Check for orphaned TabBars ---")
local tabBarsInChildren = 0
for i, child in ipairs(dockSpace.children) do
    -- Check if it's a TabBar by looking for tabs field
    if child.tabs then
        print(string.format("Child %d: TabBar with %d tabs", i, #child.tabs))
        for j, tab in ipairs(child.tabs) do
            print(string.format("  Tab %d: %s", j, tostring(tab.title)))
        end
        tabBarsInChildren = tabBarsInChildren + 1
    end
end
print(string.format("Total TabBars in children: %d", tabBarsInChildren))
if tabBarsInChildren > 1 then
    print("\n⚠️  WARNING: Found multiple TabBars! One might be phantom.")
elseif tabBarsInChildren == 0 then
    print("✓ No phantom tabs found (0 TabBars)")
else
    print("✓ Single TabBar found (correct)")
end
print()

-- Validate state
print("--- Validation ---")
local errors = DockValidator:validate(dockSpace)
if #errors == 0 then
    print("✓ State is valid")
else
    print("✗ State has errors:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
end

print("\n" .. string.rep("=", 80))
