# Widget Callbacks

Two ways to register a callback:

- **Method override** - define the bare method on a subclass. Called by the framework as part of internal widget behaviour. This is for stuff like a blinking cursor on a `TextInput` or normal drawing code for this type of widget.
- **Registration wrapper** - call `widget:onSomething(fn)` to append a user-defined handler. Multiple handlers can be registered. Use this for stuff like defining what happens when you press a specific `Button`.

## Event types

### Event
- `type` - event name
- `timestamp` - creation time
- `target` - original widget target
- `currentTarget` - widget currently handling this phase
- `consumed` - whether a handler consumed the event
- `stopsPropagation` - whether propagation is stopped
- `consume()` - marks consumed and stops propagation

### MouseEvent
- `x/y` - screen coordinates
- `localX/localY` - coordinates relative to `target`
- `button` - mouse button index
- `dx/dy` - optional movement or wheel delta
- `isTouch` - whether source input is touch

### KeyboardEvent
- `key` - logical key name
- `scancode` - physical key identifier
- `isRepeat` - whether this is a repeated key press
- `modifiers.shift/ctrl/alt` - modifier-key state
- `value` - optional text/value payload (if present)

### TextInputEvent
- `text` - entered printable text
- `modifiers.shift/ctrl/alt` - modifier-key state

### FocusEvent
- `target/currentTarget` - focus target

## Lifecycle

See: [Lifecycle](Lifecycle).


## Mouse
* `mousePressed(`[MouseEvent](#MouseEvent)`)` / `onMousePressed(fn)`

* `mouseReleased(`[MouseEvent](#MouseEvent)`)` / `onMouseReleased(fn)`
* `mouseMoved(`[MouseEvent](#MouseEvent)`)` / `onMouseMoved(fn)`
* `mouseEntered(`[MouseEvent](#MouseEvent)`)` / `onMouseEntered(fn)` / `onHover(fn)`
* `mouseExited(`[MouseEvent](#MouseEvent)`)` / `onMouseExited(fn)`
* `mouseWheel(`[MouseEvent](#MouseEvent)`)` / `onMouseWheel(fn)`
* `clicked(`[MouseEvent](#MouseEvent)`)` / `onClick(fn)`

## Keyboard & Text

* `keyPressed(`[KeyboardEvent](#KeyboardEvent)`)` / `onKeyPressed(fn)`
* `keyReleased(`[KeyboardEvent](#KeyboardEvent)`)` / `onKeyReleased(fn)`
* `textInput(`[TextInputEvent](#TextInputEvent)`)` / `onTextInput(fn)`

## Focus

* `focusGained(`[FocusEvent](#FocusEvent)`)` / `onFocusGained(fn)`
* `focusLost(`[FocusEvent](#FocusEvent)`)` / `onFocusLost(fn)`

## Drag (draggable widgets)

Registration wrappers append to `__handlers`; property assignment (`widget.dragStart = fn`) sets a single overrideable callback. Both fire.

* `dragStart(`[MouseEvent](#MouseEvent)`)` / `onDragStart(fn)`
* `drag(`[MouseEvent](#MouseEvent)`, deltaX, deltaY)` / `onDrag(fn)`
* `dragEnd(`[MouseEvent](#MouseEvent)`)` / `onDragEnd(fn)`

## Drag (drop targets)

Registration wrappers append to `__handlers`. Property assignment (`widget.dragOver = fn`) sets a single overrideable callback.

* `dragOver(`[MouseEvent](#MouseEvent)`, draggedWidget)` / `onDragOver(fn)`
* `dragLeave(`[MouseEvent](#MouseEvent)`, draggedWidget)` / `onDragLeave(fn)`
* `drop(`[MouseEvent](#MouseEvent)`, draggedWidget)` / `onDrop(fn)`

