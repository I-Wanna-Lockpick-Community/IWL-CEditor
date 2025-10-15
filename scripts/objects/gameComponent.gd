extends Node2D
class_name GameComponent
# game objects and also door locks

enum TYPES {KEY, DOOR}

var size:Vector2

@onready var shape:CollisionShape2D = %shape
@onready var editor:Editor = get_node("/root/editor")
