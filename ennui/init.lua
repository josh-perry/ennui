local EnnuiRoot = (...):gsub("%.init$", "")
local ennui = {}

ennui.Widget = require(EnnuiRoot .. ".widget")
ennui.Constants = require(EnnuiRoot .. ".constants")
ennui.Event = require(EnnuiRoot .. ".event")
ennui.Docking = require(EnnuiRoot .. ".docking")
ennui.Widgets = require(EnnuiRoot .. ".widgets")
ennui.Layout = {
    Vertical = require(EnnuiRoot .. ".layout.vertical_layout_strategy"),
    Horizontal = require(EnnuiRoot .. ".layout.horizontal_layout_strategy"),
    Grid = require(EnnuiRoot .. ".layout.grid_layout_strategy"),
    Overlay = require(EnnuiRoot .. ".layout.overlay_layout_strategy"),
    Dock = require(EnnuiRoot .. ".layout.dock_layout_strategy")
}
ennui.Size = require(EnnuiRoot .. ".size")
ennui.SizeConstraint = require(EnnuiRoot .. ".size_constraint")
ennui.Reactive = require(EnnuiRoot .. ".reactive")
ennui.State = require(EnnuiRoot .. ".state")
ennui.Host = require(EnnuiRoot .. ".widgets.host")

return ennui