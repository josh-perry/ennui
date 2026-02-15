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
local windowsExampleHost = require("examples.windows")
local groupExampleHost = require("examples.group")
local tabbarExampleHost = require("examples.tabbar")

return {
    {
        name = "Button",
        host = buttonExampleHost
    },
    {
        name = "Drag",
        host = dragExampleHost
    },
    {
        name = "JRPG",
        host = jrpg.host,
        state = jrpg.state,
        smallCanvas = true
    },
    {
        name = "Checkbox",
        host = checkboxExampleHost
    },
    {
        name = "Slider",
        host = sliderExampleHost
    },
    {
        name = "TextInput",
        host = textinputExampleHost
    },
    {
        name = "Dropdown",
        host = dropdownExampleHost
    },
    {
        name = "RadioButton",
        host = radiobuttonExampleHost
    },
    {
        name = "TreeView",
        host = treeviewExampleHost
    },
    {
        name = "ScrollArea",
        host = scrollareaExampleHost
    },
    {
        name = "CollapseableHeader",
        host = collapseableheaderExampleHost
    },
    {
        name = "Text",
        host = textExampleHost
    },
    {
        name = "Image",
        host = imageExampleHost
    },
    {
        name = "ComboBox",
        host = comboboxExampleHost
    },
    {
        name = "Layouts",
        host = layoutsExampleHost
    },
    {
        name = "Rectangle",
        host = rectangleExampleHost
    },
    {
        name = "State",
        host = stateExampleHost
    },
    {
        name = "Windows",
        host = windowsExampleHost
    },
    {
        name = "Group",
        host = groupExampleHost
    },
    {
        name = "TabBar",
        host = tabbarExampleHost
    },
    {
        name = "Docking",
        host = require("examples.docking")
    }
}