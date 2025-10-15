extends GameComponent
class_name GameObject
# keybulks, doors, lily, etc

@onready var shape:CollisionShape2D = %shape

func receiveMouseInput(_event:InputEventMouse) -> bool: return false
