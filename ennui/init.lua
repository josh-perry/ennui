local ennui = {
    Constants = require("ennui.constants"),
    Event = require("ennui.event"),
    Host = require("ennui.host"),
    Layout = {
        Vertical = require("ennui.layout.vertical_layout_strategy"),
        Horizontal = require("ennui.layout.horizontal_layout_strategy"),
        Grid = require("ennui.layout.grid_layout_strategy"),
        Overlay = require("ennui.layout.overlay_layout_strategy")
    },
    Size = require("ennui.size"),
    Widget = require("ennui.widget")
}

return ennui