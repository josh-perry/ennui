-- Widget docking system tests
package.path = package.path .. ";./tests/lib/?.lua;./ennui/?.lua;./ennui/test/?.lua;./widgets/?.lua;./?.lua"

local lester = require("lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

-- Load test utilities
local DockValidator = require("dock_validator")
local EventSimulator = require("event_simulator")

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

local DockNode = require("docknode")
local DockSpace = require("dockspace")
local Widget = require("widget")

-- Test helpers
local function createTestDockSpace()
    local dockSpace = DockSpace.new()
    dockSpace:setSize(1024, 768)

    -- Create test widgets
    local widgets = {}
    for i = 1, 5 do
        local widget = Widget.new()
        widget:setId("test_widget_" .. i)
        widget:setSize(200, 150)
        widget:setPosition(50 + i * 30, 50 + i * 30)
        dockSpace:addChild(widget)
        table.insert(widgets, widget)
    end

    return dockSpace, widgets
end

-- Test suites
describe("Widget Docking System", function()

    describe("Basic dock operations", function()
        it("should dock widget to empty space", function()
            local dockSpace, widgets = createTestDockSpace()
            local w = widgets[1]

            -- Create drop zone for center
            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end

            expect.truthy(centerZone, "Center zone exists")

            -- Dock widget
            local success = dockSpace:dock(w, centerZone)
            expect.truthy(success, "Dock succeeded")

            -- Validate state
            local errors = DockValidator:validate(dockSpace)
            expect.equal(#errors, 0, "No validation errors after dock")

            -- Check widget was added to node
            local node = dockSpace.dockTree
            expect.equal(#node.dockedWidgets, 1, "Widget added to node")
        end)

        it("should undock widget from dock", function()
            local dockSpace, widgets = createTestDockSpace()
            local w = widgets[1]

            -- Dock widget first
            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end
            dockSpace:dock(w, centerZone)

            -- Now undock
            local success = dockSpace:undock(w)
            expect.truthy(success, "Undock succeeded")

            -- Validate state
            local errors = DockValidator:validate(dockSpace)
            expect.equal(#errors, 0, "No validation errors after undock")
        end)
    end)

    describe("Node state consistency", function()
        it("should maintain valid activeTabIndex after adding widgets", function()
            local dockSpace, widgets = createTestDockSpace()

            -- Add multiple widgets to same node
            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end

            for i = 1, 3 do
                dockSpace:dock(widgets[i], centerZone)
            end

            -- Check node state
            local node = dockSpace.dockTree
            print(string.format("[Test] Node state: widgets=%d, activeIdx=%d", #node.dockedWidgets, node.activeTabIndex))

            expect.truthy(node.activeTabIndex >= 1, "activeTabIndex >= 1")
            expect.truthy(node.activeTabIndex <= #node.dockedWidgets, "activeTabIndex <= widget count")

            -- Validate
            local errors = DockValidator:validate(dockSpace)
            expect.equal(#errors, 0, "No validation errors")
        end)

        it("should maintain valid activeTabIndex after removing widgets", function()
            local dockSpace, widgets = createTestDockSpace()

            -- Add 3 widgets
            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end

            for i = 1, 3 do
                dockSpace:dock(widgets[i], centerZone)
            end

            local node = dockSpace.dockTree

            -- Remove middle widget
            node:removeWidget(widgets[2])
            print(string.format("[Test] After removal: widgets=%d, activeIdx=%d", #node.dockedWidgets, node.activeTabIndex))

            -- Check bounds
            expect.truthy(node.activeTabIndex >= 1, "activeTabIndex >= 1 after removal")
            expect.truthy(node.activeTabIndex <= #node.dockedWidgets, "activeTabIndex <= widget count after removal")

            local errors = DockValidator:validate(dockSpace)
            expect.equal(#errors, 0, "No validation errors after removal")
        end)
    end)

    describe("TabBar synchronization", function()
        it("should have correct node state when multiple widgets docked", function()
            local dockSpace, widgets = createTestDockSpace()

            -- Add 2 widgets to create TabBar
            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end

            dockSpace:dock(widgets[1], centerZone)
            dockSpace:dock(widgets[2], centerZone)

            local node = dockSpace.dockTree
            print(string.format("[Test] Node state: widgets=%d, activeIdx=%d", #node.dockedWidgets, node.activeTabIndex))
            expect.equal(#node.dockedWidgets, 2, "Two widgets in node")
            expect.truthy(node.activeTabIndex >= 1 and node.activeTabIndex <= 2, "activeTabIndex in valid range")

            local errors = DockValidator:validate(dockSpace)
            expect.equal(#errors, 0, "No validation errors with multiple widgets")
        end)
    end)

    describe("Stress tests", function()
        it("should handle rapid dock/undock cycles", function()
            local dockSpace, widgets = createTestDockSpace()
            local w = widgets[1]

            local zones = dockSpace.layoutStrategy:getDropZonesForNode(dockSpace.dockTree, 40)
            local centerZone = nil
            for _, z in ipairs(zones) do
                if z.type == "center" then
                    centerZone = z
                    break
                end
            end

            -- Rapid cycle
            for i = 1, 5 do
                dockSpace:dock(w, centerZone)
                local errors = DockValidator:validate(dockSpace)
                expect.equal(#errors, 0, "Iteration " .. i .. " dock valid")

                dockSpace:undock(w)
                errors = DockValidator:validate(dockSpace)
                expect.equal(#errors, 0, "Iteration " .. i .. " undock valid")
            end

            print("[Test] Rapid cycles completed successfully")
        end)
    end)
end)

-- Run tests
lester.report()
lester.exit()
