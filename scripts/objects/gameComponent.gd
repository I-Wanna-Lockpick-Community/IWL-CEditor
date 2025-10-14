extends Node2D
class_name GameComponent
# game objects and also door locks

enum TYPES {KEY, DOOR}

@onready var editor:Editor = get_node("/root/editor")
