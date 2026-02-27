local EnnuiRoot = (...):gsub("%.init$", "")
local ennui = {}

--- @module "ennui.widget"
ennui.Widget = require(EnnuiRoot .. ".widget")

--- @module "ennui.constants"
ennui.Constants = require(EnnuiRoot .. ".constants")

--- @module "ennui.event"
ennui.Event = require(EnnuiRoot .. ".event")

--- @module "ennui.docking"
ennui.Docking = require(EnnuiRoot .. ".docking")

--- @module "ennui.widgets"
ennui.Widgets = require(EnnuiRoot .. ".widgets")

ennui.Layout = {
    --- @module "ennui.layout.vertical_layout_strategy"
    Vertical = require(EnnuiRoot .. ".layout.vertical_layout_strategy"),
    --- @module "ennui.layout.horizontal_layout_strategy"
    Horizontal = require(EnnuiRoot .. ".layout.horizontal_layout_strategy"),
    --- @module "ennui.layout.grid_layout_strategy"
    Grid = require(EnnuiRoot .. ".layout.grid_layout_strategy"),
    --- @module "ennui.layout.overlay_layout_strategy"
    Overlay = require(EnnuiRoot .. ".layout.overlay_layout_strategy"),
    --- @module "ennui.layout.dock_layout_strategy"
    Dock = require(EnnuiRoot .. ".layout.dock_layout_strategy"),
}

--- @module "ennui.size"
ennui.Size = require(EnnuiRoot .. ".size")

--- @module "ennui.size_constraint"
ennui.SizeConstraint = require(EnnuiRoot .. ".size_constraint")

--- @module "ennui.reactive"
ennui.Reactive = require(EnnuiRoot .. ".reactive")

--- @module "ennui.state"
ennui.State = require(EnnuiRoot .. ".state")

--- @module "ennui.widgets.host"
ennui.Host = require(EnnuiRoot .. ".widgets.host")

return ennui
