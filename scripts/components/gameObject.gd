extends GameComponent
class_name GameObject
# keybulks, doors, lily, etc

var active:bool = true

func propertyChangedDo(property:StringName) -> void: super(property)

func stop() -> void:
	active = true
	propertyGameChangedDo(&"active")
