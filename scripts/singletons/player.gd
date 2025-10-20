extends CharacterBody2D
class_name Player

var game:Game

const FPS:float = 60 # godot velocity works in /s so we account for gamemaker's fps, which is 60

const JUMP_SPEED:float = 8.5
const DOUBLE_JUMP_SPEED:float = 7
const GRAVITY:float = 0.4
const Y_MAXSPEED:float = 9

var canDoubleJump:bool = true

func _process(delta:float) -> void:
	if game.playState == Game.PLAY_STATE.PAUSED:
		%sprite.pause()
		return

	var hSpeed:float = 6
	if !is_on_floor(): hSpeed = 3
	var moveDirection:float = Input.get_axis(&"left", &"right")
	velocity.x = hSpeed*FPS*moveDirection

	if Input.is_action_just_pressed(&"jump"):
		if is_on_floor():
			velocity.y = -JUMP_SPEED*FPS
			canDoubleJump = true
		elif canDoubleJump:
			velocity.y = -DOUBLE_JUMP_SPEED*FPS
			canDoubleJump = false
	if Input.is_action_just_released(&"jump") and velocity.y < 0: velocity.y *= 0.45
	velocity.y += GRAVITY*FPS*FPS*delta # multiplied by an extra FPS*delta, since the original script runs at 60fps, but now it runs at 1/delta fps
	velocity.y = clamp(velocity.y, -Y_MAXSPEED*FPS, Y_MAXSPEED*FPS)

	move_and_slide()

	if moveDirection: %sprite.flip_h = moveDirection < 0

	if velocity.y <= -0.05*FPS: %sprite.play("jump")
	elif velocity.y >= 0.05*FPS: %sprite.play("fall")
	elif moveDirection: %sprite.play("run")
	else: %sprite.play("idle")
	
