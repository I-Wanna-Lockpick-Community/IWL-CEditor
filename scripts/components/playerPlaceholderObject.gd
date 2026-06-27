extends PlaceholderObject
class_name PlayerPlaceholderObject

var undoStack:Array[Array]:
	get(): return GameChanges.undoStack

func outlineTex() -> Texture2D:
	return Game.player.getCurrentSprite()

func getOffset() -> Vector2:
	return Vector2(10, 11)

func getDrawSize() -> Vector2:
	return Vector2(32,32)

func propertyChangedDo(property:StringName) -> void:
	match property:
		&"position":
			Game.player.position = position + Vector2(6, 12)

func deleted(alreadyStopped:bool=false) -> void:
	Game.objects.erase(-1)
	Game.objectsParent.remove_child(self)
	if !alreadyStopped: Game.stopTest()
	if self == Game.editor.focusDialog.focused: Game.editor.focusDialog.defocus()
