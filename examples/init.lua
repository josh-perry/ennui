local buttonExampleHost = require("examples.button")
local dragExampleHost = require("examples.drag")
local jrpg = require("examples.jrpg")
local checkboxExampleHost = require("examples.checkbox")
local sliderExampleHost = require("examples.slider")
local textinputExampleHost = require("examples.textinput")
local dropdownExampleHost = require("examples.dropdown")
local radiobuttonExampleHost = require("examples.radiobutton")
local treeviewExampleHost = require("examples.treeview")
local scrollareaExampleHost = require("examples.scrollarea")
local collapseableheaderExampleHost = require("examples.collapseableheader")
local textExampleHost = require("examples.text")
local imageExampleHost = require("examples.image")
local comboboxExampleHost = require("examples.combobox")
local layoutsExampleHost = require("examples.layouts")
local rectangleExampleHost = require("examples.rectangle")
local stateExampleHost = require("examples.state")
local computedExampleHost = require("examples.state-computed")
local todoExampleHost = require("examples.state-todo")
local windowsExampleHost = require("examples.windows")
local groupExampleHost = require("examples.group")
local tabbarExampleHost = require("examples.tabbar")
local dockingExampleHost = require("examples.docking")

return {
    {
        name = "Button",
        host = buttonExampleHost,
        description = "Basic button interaction with click counting.",
        tags = {"button", "interaction", "events"}
    },
    {
        name = "Drag",
        host = dragExampleHost,
        description = "Draggable widget examples.",
        tags = {"drag", "interaction", "mouse"}
    },
    {
        name = "JRPG",
        host = jrpg.host,
        state = jrpg.state,
        smallCanvas = true,
        description = "Retro RPG game demo rendered at 320x288.",
        tags = {"game", "canvas", "smallcanvas", "demo"}
    },
    {
        name = "Checkbox",
        host = checkboxExampleHost,
        description = "Checkbox toggle controls.",
        tags = {"checkbox", "toggle", "input"}
    },
    {
        name = "Slider",
        host = sliderExampleHost,
        description = "Slider control for numeric value selection.",
        tags = {"slider", "input", "numeric"}
    },
    {
        name = "TextInput",
        host = textinputExampleHost,
        description = "Text input fields with editing and selection support.",
        tags = {"textinput", "input", "text", "keyboard"}
    },
    {
        name = "Dropdown",
        host = dropdownExampleHost,
        description = "Dropdown menu for selecting from a list.",
        tags = {"dropdown", "menu", "input", "selection"}
    },
    {
        name = "RadioButton",
        host = radiobuttonExampleHost,
        description = "Radio button groups for exclusive selection.",
        tags = {"radiobutton", "selection", "input"}
    },
    {
        name = "TreeView",
        host = treeviewExampleHost,
        description = "Hierarchical tree view with collapsible nodes.",
        tags = {"treeview", "hierarchy", "navigation"}
    },
    {
        name = "ScrollArea",
        host = scrollareaExampleHost,
        description = "Scrollable content container with scroll bars.",
        tags = {"scrollarea", "scroll", "container"}
    },
    {
        name = "CollapseableHeader",
        host = collapseableheaderExampleHost,
        description = "Collapsible header sections for grouping content.",
        tags = {"collapse", "header", "accordion"}
    },
    {
        name = "Text",
        host = textExampleHost,
        description = "Text display widget with alignment and color options.",
        tags = {"text", "display", "label"}
    },
    {
        name = "Image",
        host = imageExampleHost,
        description = "Image display widget.",
        tags = {"image", "display"}
    },
    {
        name = "ComboBox",
        host = comboboxExampleHost,
        description = "Combo box combining text entry with a selection list.",
        tags = {"combobox", "input", "selection", "text"}
    },
    {
        name = "Layouts",
        host = layoutsExampleHost,
        description = "Demonstration of layout strategies including grid and percentage sizing.",
        tags = {"layout", "stackpanel", "grid", "sizing"}
    },
    {
        name = "Rectangle",
        host = rectangleExampleHost,
        description = "Rectangle shape widget with color and border styling.",
        tags = {"rectangle", "shape", "drawing"}
    },
    {
        name = "State",
        host = stateExampleHost,
        description = "Reactive state management and property binding demonstration.",
        tags = {"state", "reactive", "binding"}
    },
    {
        name = "State - todo list",
        host = todoExampleHost,
        description = "Reactive todo list showing State, State.newId(), bindChildren, computedInline, computed:map, and filter binding.",
        tags = {"state", "reactive", "binding", "list", "computed"}
    },
    {
        name = "State - temperature converter",
        host = computedExampleHost,
        description = "Temperature converter demonstrating computed properties, formatting and binding.",
        tags = {"computed", "reactive", "binding", "map", "format"}
    },
    {
        name = "Windows",
        host = windowsExampleHost,
        description = "Draggable floating windows.",
        tags = {"windows", "drag", "overlay"}
    },
    {
        name = "Group",
        host = groupExampleHost,
        description = "Widget grouping and containment.",
        tags = {"group", "container"}
    },
    {
        name = "TabBar",
        host = tabbarExampleHost,
        description = "Tabbed interface for switching between views.",
        tags = {"tabbar", "tabs", "navigation"}
    },
    {
        name = "Docking",
        host = dockingExampleHost,
        description = "Dockable window system for flexible layouts.",
        tags = {"docking", "windows", "layout"}
    }
}
