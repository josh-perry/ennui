local EnnuiRoot = (...):gsub("%.init$", "")

return {
    DockNode = require(EnnuiRoot .. ".docknode")
}