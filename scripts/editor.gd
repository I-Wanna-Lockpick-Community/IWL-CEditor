extends Control
class_name Editor

@onready var level:Level = %level

enum Mode {SELECT, TILE, KEY, DOOR, PASTE}
var mode:Mode = Mode.SELECT

func _guiInput(event:InputEvent) -> void:
    if event is InputEventMouse:
        var worldPosition:Vector2 = event.position - %levelViewportCont.position
        var tilePosition:Vector2i = Vector2i(worldPosition) / Vector2i(32,32)
        match mode:
            Mode.TILE:
                if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                    level.tiles.set_cell(tilePosition,1,Vector2i(1,1))
                elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
                    level.tiles.erase_cell(tilePosition)
