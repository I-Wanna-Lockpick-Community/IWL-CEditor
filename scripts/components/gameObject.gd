extends GameComponent
class_name GameObject
# keybulks, doors, lily, etc

var active:bool = true

func propertyChanged(_property:StringName) -> void: pass

func start() -> void:
	active = true
	propertyGameChanged(&"active")
