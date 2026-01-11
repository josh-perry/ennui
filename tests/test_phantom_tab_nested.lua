-- Test to reproduce phantom tab with nested splits
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
print("TEST: Phantom Tab with Nested Splits")
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

local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
local centerZone = nil
for _, z in ipairs(zones) do
    if z.type == "center" then
        centerZone = z
        break
    end
end

print("Step 1: Dock w1 and w2 to center (creates leaf with TabBar)")
dockSpace:dock(w1, centerZone)
dockSpace:dock(w2, centerZone)
dockSpace:invalidateLayout()
print(string.format("Children: %d", #dockSpace.children))
print()

print("Step 2: Dock w3 to LEFT")
local leftZone = {type = "left", targetNode = dockSpace.dockTree}
dockSpace:dock(w3, leftZone)
dockSpace:invalidateLayout()
print(string.format("dockTree isSplit: %s, children: %d", tostring(dockSpace.dockTree:isSplit()), #dockSpace.children))
print()

print("Step 3: Dock w4 to BOTTOM (creates nested split)")
local bottomZone = {type = "bottom", targetNode = dockSpace.dockTree.leftChild}
dockSpace:dock(w4, bottomZone)
dockSpace:invalidateLayout()
print(string.format("dockTree.leftChild isSplit: %s, children: %d", tostring(dockSpace.dockTree.leftChild:isSplit()), #dockSpace.children))
print()

print("Step 4: Undock w3 from top of left split (left becomes split with only bottom)")
dockSpace:undock(w3)
dockSpace:invalidateLayout()
print(string.format("After undock - children: %d", #dockSpace.children))
print()

print("Step 5: Undock w4 from bottom (left should collapse)")
dockSpace:undock(w4)
dockSpace:invalidateLayout()
print(string.format("After undock w4 - dockTree isSplit: %s, children: %d", tostring(dockSpace.dockTree:isSplit()), #dockSpace.children))
print()

print("Step 6: Check TabBar count")
local tabBars = 0
for i, child in ipairs(dockSpace.children) do
    if child.tabs then
        print(string.format("Child %d: TabBar with %d tabs", i, #child.tabs))
        tabBars = tabBars + 1
    end
end
print(string.format("Total TabBars: %d", tabBars))
if tabBars > 1 then
    print("⚠️  PHANTOM TAB DETECTED!")
elseif tabBars == 0 then
    print("✓ No TabBars (single leaf, no TabBar created yet)")
else
    print("✓ Single TabBar")
end
