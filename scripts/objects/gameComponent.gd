extends Node2D
class_name GameComponent
# game objects and also door locks

enum TYPES {KEY, DOOR, LOCK}

var size:Vector2

@onready var editor:Editor = get_node("/root/editor")

func getDrawPosition() -> Vector2: return position
