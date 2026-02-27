local EnnuiRoot = (...):gsub("%.init$", "")

---Mixin modules for composing functionality
return {
    Stateful = require(EnnuiRoot .. ".stateful"),
    Parentable = require(EnnuiRoot .. ".parentable"),
    Positionable = require(EnnuiRoot .. ".positionable"),
    Layoutable = require(EnnuiRoot .. ".layoutable"),
    Draggable = require(EnnuiRoot .. ".draggable"),
    Focusable = require(EnnuiRoot .. ".focusable"),
    EventEmitter = require(EnnuiRoot .. ".event_emitter"),
    ListBindable = require(EnnuiRoot .. ".listbindable"),
}
