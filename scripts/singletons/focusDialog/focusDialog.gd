extends Control
class_name FocusDialog

@onready var colorLink:Button = %colorLink

@onready var keyDialog:KeyDialog = %keyDialog
@onready var doorDialog:DoorDialog = %doorDialog
@onready var playerDialog:PlayerDialog = %playerDialog
@onready var keyCounterDialog:KeyCounterDialog = %keyCounterDialog
@onready var goalDialog:GoalDialog = %goalDialog

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var activeDialog:Control
var bufferFocus:bool = false

var focusOffsetAmount:float = 0

var interacted:NumberEdit # the number edit that is currently interacted
var numberEdits:Array[NumberEdit] = []

var above:bool = false # display above the object instead

func _ready() -> void:
	get_tree().call_group("modUI", "changedMods")

func focus(object:GameObject, dontRedirect:bool=false) -> void:
	var new:bool = object != focused
	if new: focusOffsetAmount = -8
	focused = object
	Game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if new: deinteract()
	if activeDialog: activeDialog.focus(focused, new, dontRedirect)

func showCorrectDialog() -> void:
	above = false
	for dialog in get_children():
		if dialog is not Control: continue
		dialog.visible = false
	%speechBubbler.visible = true
	activeDialog = null
	match focused.get_script():
		KeyBulk: activeDialog = keyDialog
		Door, RemoteLock: activeDialog = doorDialog
		PlayerSpawn, PlayerPlaceholderObject: activeDialog = playerDialog
		KeyCounter: activeDialog = keyCounterDialog; above = true
		Goal: activeDialog = goalDialog
		_: %speechBubbler.visible = false
	if activeDialog: activeDialog.visible = true

func defocus() -> void:
	if !focused: return
	var object:GameObject = focused
	Game.editor.quickSet.applyOrCancel()
	focused = null
	if object is RemoteLock: object.queue_redraw()
	deinteract()
	defocusComponent()
	bufferFocus = false

func focusComponent(component:GameComponent) -> void:
	if !component:
		assert(false)
		return
	var new:bool = component != componentFocused
	componentFocused = component
	if focused != component.parent: focus(component.parent)
	if component is Lock: doorDialog.focusComponent(component, new)
	elif component is KeyCounterElement: keyCounterDialog.focusComponent(component, new)

func defocusComponent() -> void:
	if !componentFocused: return
	componentFocused = null
	deinteract()
	bufferFocus = false

func interact(edit:NumberEdit, last:bool=false) -> void:
	deinteract()
	edit.interact(last)
	interacted = edit

func deinteract() -> void:
	if !interacted: return
	interacted.deinteract()
	interacted = null

func receiveKey(event:InputEventKey) -> bool:
	if activeDialog and activeDialog.receiveKey(event): return true
	else:
		if Editor.eventIs(event, &"editDelete"):
			Changes.addChange(Changes.DeleteComponentChange.new(focused))
			Changes.bufferSave()
		elif event.keycode == KEY_TAB:
			Game.editor.grab_focus()
			if interacted: 
				var index:int = numberEdits.find(interacted)
				if Input.is_key_pressed(KEY_SHIFT):
					index -= 1
					while !numberEdits[index].is_visible_in_tree():
						if index == -1: previousMenu()
						index -= 1
					interact(numberEdits[index], true)
				else:
					index += 1
					while !numberEdits[index].is_visible_in_tree():
						if index == len(numberEdits)-1:
							nextMenu(); index = 0
						else: index += 1
					interact(numberEdits[index])
			else: bufferFocus = true
		else: return false
	return true

func previousMenu() -> void:
	match activeDialog:
		doorDialog:
			if componentFocused:
				if componentFocused.index > 0: focusComponent(focused.locks[componentFocused.index-1])
				else: doorDialog._spendSelected()
			else: focusComponent(focused.locks[-1])
		playerDialog:
			playerDialog.setSelectedColor(Mods.previousColor(playerDialog.color))

func nextMenu() -> void:
	match activeDialog:
		doorDialog:
			if componentFocused:
				if componentFocused.index == len(focused.locks) - 1: doorDialog._spendSelected()
				else: focusComponent(focused.locks[componentFocused.index+1])
			else: focusComponent(focused.locks[0])
		playerDialog:
			playerDialog.setSelectedColor(Mods.nextColor(playerDialog.color))

const EDGE_MARGIN:float = 4
const OBJECT_MARGIN:float = 16 # between the dialog and the object; where the speech bubbler goes
const SPEECH_BUBBLER_MARGIN:float = 10 # between speech bubbler and edge of dialog

func _process(delta:float) -> void:
	if bufferFocus:
		if componentFocused: focusComponent(componentFocused)
		elif focused: focus(focused)
		bufferFocus = false
	if focused and activeDialog:
		focusOffsetAmount += (-focusOffsetAmount)*delta*25
		visible = true
		# position the dialog every frame (could be optimised but i dont care)
		var flip:bool = false
		activeDialog.get_child(0).size = Vector2.ZERO
		var halfWidth:float = activeDialog.get_child(0).size.x/2
		activeDialog.get_child(0).position = Vector2(-halfWidth,0)
		var height:float = activeDialog.get_child(0).size.y

		var objectMargin:float = focusOffsetAmount + OBJECT_MARGIN

		position = Game.editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,objectMargin)
		
		if above and position.y - height - 2*objectMargin - focused.size.y*Game.editor.cameraZoom < Game.editor.gameCont.position.y + EDGE_MARGIN: flip = true
		elif !above and position.y + height > Game.editor.gameCont.position.y + Game.editor.gameCont.size.y - EDGE_MARGIN: flip = true

		if above != flip: position = Game.editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,0)) + Vector2(0,-objectMargin)
		%speechBubbler.rotation_degrees = 0 if above != flip else 180
		if flip != above: activeDialog.get_child(0).position.y = -height
		else: activeDialog.get_child(0).position.y = 0

		var speechBubblerRange:float = halfWidth
		if activeDialog == doorDialog and flip: speechBubblerRange = activeDialog.get_child(0).get_child(1).size.x/2
		%speechBubbler.position.x = 0
		if position.x < halfWidth + EDGE_MARGIN:
			%speechBubbler.position.x = max(position.x-halfWidth-EDGE_MARGIN,SPEECH_BUBBLER_MARGIN-speechBubblerRange)
			position.x = halfWidth + EDGE_MARGIN
		if position.x + halfWidth + EDGE_MARGIN > Game.editor.gameCont.size.x:
			%speechBubbler.position.x = min(position.x+halfWidth-Game.editor.gameCont.size.x+EDGE_MARGIN,speechBubblerRange-SPEECH_BUBBLER_MARGIN)
			position.x = Game.editor.gameCont.size.x - halfWidth - EDGE_MARGIN
		
		if above != flip: position.y = min(position.y, Game.editor.gameCont.position.y + Game.editor.gameCont.size.y - SPEECH_BUBBLER_MARGIN)
		else: position.y = max(position.y, Game.editor.gameCont.position.y + SPEECH_BUBBLER_MARGIN)
	else:
		visible = false

func focusHandlerAdded(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.addButton(index)
			focusComponent(focused.locks[index])
		KeyCounterElement:
			%keyCounterHandler.addButton(index)
			focusComponent(focused.elements[index])
		Door: %doorsHandler.addButton(index,false)

func focusHandlerRemoved(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.removeButton(index)
			if index != 0: focusComponent(focused.locks[index-1])
			elif len(focused.locks) > 0: focusComponent(focused.locks[0])
		KeyCounterElement:
			%keyCounterHandler.removeButton(index)
			if index != 0: focusComponent(focused.elements[index-1])
			elif len(focused.elements) > 0: focusComponent(focused.elements[0])
		Door: %doorsHandler.removeButton(index,false)
