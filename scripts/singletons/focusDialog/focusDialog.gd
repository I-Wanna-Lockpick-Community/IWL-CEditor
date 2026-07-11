extends MainDialog
class_name FocusDialog

@onready var colorLink:Button = %colorLink

@onready var keyDialog:KeyDialog = %keyDialog
@onready var doorDialog:DoorDialog = %doorDialog
@onready var playerDialog:PlayerDialog = %playerDialog
@onready var keyCounterDialog:KeyCounterDialog = %keyCounterDialog
@onready var goalDialog:GoalDialog = %goalDialog
@onready var pencilmarkDialog:PencilmarkDialog = %pencilmarkDialog

func _ready() -> void:
	get_tree().call_group("modUI", "changedMods")

func showCorrectDialog() -> void:
	above = false
	%speechBubbler.visible = true
	match focused.get_script():
		KeyBulk: activeDialog = keyDialog
		Door, RemoteLock: activeDialog = doorDialog
		PlayerSpawn, PlayerPlaceholderObject: activeDialog = playerDialog
		KeyCounter: activeDialog = keyCounterDialog; above = true
		Goal: activeDialog = goalDialog
		Pencilmark: activeDialog = pencilmarkDialog
	%speechBubbler.visible = !!activeDialog
	for dialog in get_children():
		if dialog is not SubDialog: continue
		dialog.visible = dialog == activeDialog

func defocus() -> void:
	Game.editor.quickSet.applyOrCancel()
	super()

func focusComponent(component:GameComponent, skipInput:Control = null) -> void:
	var new:bool = component != componentFocused
	super(component, skipInput)
	if component is Lock: doorDialog.focusComponent(component, new, skipInput)
	elif component is KeyCounterElement: keyCounterDialog.focusComponent(component, new, skipInput)

func receiveKey(event:InputEventKey) -> bool:
	if activeDialog and activeDialog.receiveKey(event): return true
	else:
		if Editor.eventIs(event, &"editDelete"): deleteFocused()
		elif event.keycode == KEY_TAB:
			Game.editor.grab_focus()
			if interacted: 
				var index:int = numberEdits.find(interacted)
				if Input.is_key_pressed(KEY_SHIFT):
					index -= 1
					if index == -1: previousMenu()
					while !numberEdits[index].is_visible_in_tree():
						index -= 1
						if index == -1: previousMenu()
					interact(numberEdits[index], true)
				else:
					index += 1
					if index == len(numberEdits): nextMenu(); index = 0
					while !numberEdits[index].is_visible_in_tree():
						index += 1
						if index == len(numberEdits): nextMenu(); index = 0
					interact(numberEdits[index])
			else:
				bufferFocusComponent = true
				bufferFocusObject = true
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

func deleteFocused() -> void:
	Changes.addChange(Changes.DeleteComponentChange.new(focused))
	Changes.bufferSave()

func worldspaceToScreenspace(input:Vector2) -> Vector2: return Game.editor.worldspaceToScreenspace(input)
func cameraZoom() -> float: return Game.editor.cameraZoom
func gameCont() -> Container: return Game.editor.gameCont
