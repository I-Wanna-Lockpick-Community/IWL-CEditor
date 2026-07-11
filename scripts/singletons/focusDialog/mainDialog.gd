@abstract
extends Control
class_name MainDialog

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var activeDialog:SubDialog

const EDGE_MARGIN:float = 4
const OBJECT_MARGIN:float = 16 # between the dialog and the object; where the speech bubbler goes
const SPEECH_BUBBLER_MARGIN:float = 10 # between speech bubbler and edge of dialog

var focusOffsetAmount:float = 0

var above:bool = false # display above the object instead

var interacted:NumberEdit # the number edit that is currently interacted
var numberEdits:Array[NumberEdit] = []

var bufferSkipInput:Control = null
var bufferFocusObject:bool = false
var bufferFocusComponent:bool = false

func focus(object:GameObject, dontRedirect:bool=false, skipInput:Control = null) -> void:
	var new:bool = object != focused
	if new: focusOffsetAmount = -8
	focused = object
	if focused is GameNote: Game.notesParent.move_child(focused, -1)
	else: Game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if new: deinteract()
	if activeDialog: activeDialog.focus(focused, new, dontRedirect, skipInput)

func defocus() -> void:
	if !focused: return
	var object:GameObject = focused
	focused = null
	if object is RemoteLock: object.queue_redraw()
	deinteract()
	defocusComponent()
	bufferFocusObject = false
	bufferFocusComponent = false

func focusComponent(component:GameComponent, skipInput:Control = null) -> void:
	if !component:
		assert(false)
		return
	componentFocused = component
	if focused != component.parent: focus(component.parent, false, skipInput)

func defocusComponent() -> void:
	if !componentFocused: return
	componentFocused = null
	deinteract()
	bufferFocusObject = false
	bufferFocusComponent = false

@abstract func showCorrectDialog() -> void

@abstract func worldspaceToScreenspace(input:Vector2) -> Vector2
@abstract func cameraZoom() -> float
@abstract func gameCont() -> Container

func _process(delta: float) -> void:
	if bufferFocusComponent and componentFocused:
		focusComponent(componentFocused, bufferSkipInput)
		bufferFocusComponent = false
		bufferSkipInput = null
	if bufferFocusObject and focused:
		focus(focused, false, bufferSkipInput)
		bufferFocusObject = false
		bufferSkipInput = null
	if focused and activeDialog:
		focusOffsetAmount += (-focusOffsetAmount)*min(1, delta*25)
		visible = true
		# position the dialog every frame (could be optimised but i dont care)
		var flip:bool = false
		activeDialog.get_child(0).size = Vector2.ZERO
		var halfWidth:float = activeDialog.get_child(0).size.x/2
		activeDialog.get_child(0).position = Vector2(-halfWidth,0)
		var height:float = activeDialog.get_child(0).size.y

		var objectMargin:float = focusOffsetAmount + OBJECT_MARGIN

		position = worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,focused.size.y))
		if componentFocused: position.y = max(position.y, worldspaceToScreenspace(componentFocused.getDrawPosition() + componentFocused.size).y)
		position += Vector2(0,objectMargin)
		
		if above and position.y - height - 2*objectMargin - focused.size.y*cameraZoom() < gameCont().position.y + EDGE_MARGIN: flip = true
		elif !above and position.y + height > gameCont().position.y + gameCont().size.y - EDGE_MARGIN: flip = true

		if above != flip:
			position = worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,0))
			if componentFocused: position.y = min(position.y, worldspaceToScreenspace(componentFocused.getDrawPosition()).y)
			position -= Vector2(0,objectMargin)
		%speechBubbler.rotation_degrees = 0 if above != flip else 180
		if flip != above: activeDialog.get_child(0).position.y = -height
		else: activeDialog.get_child(0).position.y = 0

		var speechBubblerRange:float = halfWidth
		if activeDialog is DoorDialog and flip: speechBubblerRange = activeDialog.get_child(0).get_child(1).size.x/2
		%speechBubbler.position.x = 0
		if position.x < halfWidth + EDGE_MARGIN:
			%speechBubbler.position.x = max(position.x-halfWidth-EDGE_MARGIN,SPEECH_BUBBLER_MARGIN-speechBubblerRange)
			position.x = halfWidth + EDGE_MARGIN
		if position.x + halfWidth + EDGE_MARGIN > gameCont().size.x:
			%speechBubbler.position.x = min(position.x+halfWidth-gameCont().size.x+EDGE_MARGIN,speechBubblerRange-SPEECH_BUBBLER_MARGIN)
			position.x = gameCont().size.x - halfWidth - EDGE_MARGIN
		
		if above != flip: position.y = min(position.y, gameCont().position.y + gameCont().size.y - SPEECH_BUBBLER_MARGIN)
		else: position.y = max(position.y, gameCont().position.y + SPEECH_BUBBLER_MARGIN)
	else:
		visible = false

@abstract func receiveKey(event:InputEventKey) -> bool

func interact(edit:NumberEdit, last:bool=false) -> void:
	deinteract()
	edit.interact(last)
	interacted = edit

func deinteract() -> void:
	if !interacted: return
	interacted.deinteract()
	interacted = null

@abstract func deleteFocused() -> void

func focusHandlerAdded(_type:GDScript, _index:int) -> void: pass
func focusHandlerRemoved(_type:GDScript, _index:int) -> void: pass
