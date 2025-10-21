extends GameComponent
class_name GameObject
# keybulks, doors, lily, etc

@onready var shape:CollisionShape2D = %shape


func propertyChanged(property:StringName) -> void:
	if property == &"size":
		shape.shape.size = size
		shape.position = size/2
