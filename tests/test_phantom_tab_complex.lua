-- Test that creates TabBars in promoted tree
package.path = package.path .. ";./tests/lib/?.lua;./ennui/?.lua;./ennui/test/?.lua;./widgets/?.lua;./?.lua"

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

print("\n" .. string.rep("=", 80))
print("TEST: Phantom Tab with TabBars in Promoted Tree")
print(string.rep("=", 80) .. "\n")

local dockSpace = DockSpace.new()
dockSpace:setSize(1024, 768)

local w1 = Widget.new()
w1:setId("w1")
dockSpace:addChild(w1)

local w2 = Widget.new()
w2:setId("w2")
dockSpace:addChild(w2)

local w3 = Widget.new()
w3:setId("w3")
dockSpace:addChild(w3)

local w4 = Widget.new()
w4:setId("w4")
dockSpace:addChild(w4)

local w5 = Widget.new()
w5:setId("w5")
dockSpace:addChild(w5)

local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
local centerZone = nil
for _, z in ipairs(zones) do
    if z.type == "center" then
        centerZone = z
        break
    end
end

print("Step 1: Create structure with TabBars:")
print("  - Dock w1 to center")
dockSpace:dock(w1, centerZone)

print("  - Dock w2 to LEFT (creates left leaf)")
local leftZone = {type = "left", targetNode = dockSpace.dockTree}
dockSpace:dock(w2, leftZone)

print("  - Dock w3 to LEFT (adds to left leaf, creates TabBar there)")
-- Get the left child's center zone
local leftNode = dockSpace.dockTree.leftChild
local leftZones = dockSpace.layoutStrategy:getDropZonesForNode(leftNode, 40)
local leftCenterZone = nil
for _, z in ipairs(leftZones) do
    if z.type == "center" then
        leftCenterZone = z
        break
    end
end
dockSpace:dock(w3, leftCenterZone)
dockSpace:invalidateLayout()

print("  - Dock w4 to BOTTOM of left side")
local bottomZone = {type = "bottom", targetNode = leftNode}
dockSpace:dock(w4, bottomZone)
dockSpace:invalidateLayout()

print("  - Dock w5 to RIGHT")
local rightZone = {type = "right", targetNode = dockSpace.dockTree}
dockSpace:dock(w5, rightZone)
dockSpace:invalidateLayout()

print("\nStructure: left=[w2,w3]@top,[w4]@bottom, center=[w1], right=[w5]")
print()

print("Step 2: Undock w4 (bottom of left becomes empty)")
dockSpace:undock(w4)
dockSpace:invalidateLayout()
print()

print("Step 3: Count TabBars")
local tabBars = 0
for i, child in ipairs(dockSpace.children) do
    if child.tabs then
        print(string.format("  Child %d: TabBar with %d tabs", i, #child.tabs))
        tabBars = tabBars + 1
    end
end
print(string.format("Total TabBars: %d", tabBars))

if tabBars > 1 then
    print("\n⚠️  PHANTOM TAB DETECTED - Expected 1, got " .. tabBars)
elseif tabBars == 0 then
    print("\n✓ Correct: No TabBars yet (w2,w3,w5 will be shown as tabs when accessed)")
else
    print("\n✓ Single TabBar (correct)")
end
