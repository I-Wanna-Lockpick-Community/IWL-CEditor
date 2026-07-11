extends MainDialog
class_name PlayGameDialog

@onready var pencilmarkDialog:PencilmarkDialog = %pencilmarkDialog

func focus(object:GameObject, dontRedirect:bool=false, skipInput:Control = null) -> void:
	var new:bool = object != focused
	if new: focusOffsetAmount = -8
	focused = object
	if focused is GameNote: Game.notesParent.move_child(focused, -1)
	else: Game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if new: deinteract()
	if activeDialog: activeDialog.focus(focused, new, dontRedirect, skipInput)

func showCorrectDialog() -> void:
	above = false
	%speechBubbler.visible = true
	match focused.get_script():
		Pencilmark: activeDialog = pencilmarkDialog
	%speechBubbler.visible = !!activeDialog
	for dialog in get_children():
		if dialog is not SubDialog: continue
		dialog.visible = dialog == activeDialog

func receiveKey(event:InputEventKey) -> bool:
	if activeDialog and activeDialog.receiveKey(event): return true
	else: return false

func deleteFocused() -> void: Game.playGame.deleteNote(focused)

func worldspaceToScreenspace(input:Vector2) -> Vector2: return Game.playGame.worldspaceToScreenspace(input)
func cameraZoom() -> float: return Game.camera.zoom.x
func gameCont() -> Container: return Game.playGame.worldViewportCont
func quickSet() -> QuickSet: return null
