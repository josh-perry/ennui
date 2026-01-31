---Mixin modules for composing functionality across State and Widget
---
---Usage:
---  local Mixins = require("ennui.mixins")
---  local Mixin = require("ennui.utils.mixin")
---
---  local MyClass = {}
---  Mixin.extend(MyClass, Mixins.Stateful, Mixins.EventEmitter)
---
---  function MyClass.new()
---    local self = setmetatable({}, MyClass)
---    Mixins.Stateful.initStateful(self)
---    Mixins.EventEmitter.initEventEmitter(self)
---    return self
---  end

return {
    Stateful = require("ennui.mixins.stateful"),
    Parentable = require("ennui.mixins.parentable"),
    Positionable = require("ennui.mixins.positionable"),
    Layoutable = require("ennui.mixins.layoutable"),
    Draggable = require("ennui.mixins.draggable"),
    Focusable = require("ennui.mixins.focusable"),
    EventEmitter = require("ennui.mixins.event_emitter"),
}
