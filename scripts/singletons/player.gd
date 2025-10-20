extends CharacterBody2D
class_name Player

func _process(_delta: float) -> void:
	var moveDirection:float = Input.get_axis(&"left", &"right")
	if moveDirection:
		if is_on_floor(): %sprite.play("run")
		%sprite.flip_h = moveDirection < 0
	elif is_on_floor(): %sprite.play("idle")
	velocity.x = 192*moveDirection
	
	if Input.is_action_just_pressed(&"jump") and is_on_floor(): velocity.y = -400
	else: velocity.y += 20
	
	if !is_on_floor():
		if velocity.y >= 1: %sprite.play("jump")
		elif velocity.y <= -1: %sprite.play("fall")
	
	move_and_slide()
