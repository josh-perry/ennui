local ennui = {}

ennui.Widget = require("ennui.widget")
ennui.Constants = require("ennui.constants")
ennui.Event = require("ennui.event")
ennui.Docking = require("ennui.docking")
ennui.Widgets = require("ennui.widgets")
ennui.Layout = {
    Vertical = require("ennui.layout.vertical_layout_strategy"),
    Horizontal = require("ennui.layout.horizontal_layout_strategy"),
    Grid = require("ennui.layout.grid_layout_strategy"),
    Overlay = require("ennui.layout.overlay_layout_strategy"),
    Dock = require("ennui.layout.dock_layout_strategy")
}
ennui.Size = require("ennui.size")

return ennui