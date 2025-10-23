extends CharacterBody2D
class_name Player

var game:Game

const FPS:float = 60 # godot velocity works in /s so we account for gamemaker's fps, which is 60

const JUMP_SPEED:float = 8.5
const DOUBLE_JUMP_SPEED:float = 7
const GRAVITY:float = 0.4
const Y_MAXSPEED:float = 9

var canDoubleJump:bool = true
var key:Array[C] = []
var star:Array[bool]

var nearDoor:bool = false # cant save if near a door

func _ready() -> void:
	for color in Game.COLORS:
		# if color == Game.COLOR.STONE:
		key.append(C.ZERO)
		star.append(false)

func _physics_process(_delta:float):
	if game.playState == Game.PLAY_STATE.PAUSED:
		%sprite.pause()
		return
	
	var xSpeed:float = 6
	if !is_on_floor() or Input.is_key_pressed(KEY_SHIFT): xSpeed = 3
	var moveDirection:float = Input.get_axis(&"left", &"right")
	velocity.x = xSpeed*FPS*moveDirection

	if is_on_floor(): canDoubleJump = true
	if Input.is_action_just_pressed(&"jump"):
		if is_on_floor():
			velocity.y = -JUMP_SPEED*FPS
			%audio.stream = preload("res://resources/sounds/player/jump.wav")
			%audio.play()
		elif canDoubleJump:
			velocity.y = -DOUBLE_JUMP_SPEED*FPS
			canDoubleJump = false
			%audio.stream = preload("res://resources/sounds/player/doubleJump.wav")
			%audio.play()
	if Input.is_action_just_released(&"jump") and velocity.y < 0: velocity.y *= 0.45
	velocity.y += GRAVITY*FPS
	velocity.y = clamp(velocity.y, -Y_MAXSPEED*FPS, Y_MAXSPEED*FPS)

	move_and_slide()

	if moveDirection: %sprite.flip_h = moveDirection < 0

	if velocity.y <= -0.05*FPS: %sprite.play("jump")
	elif velocity.y >= 0.05*FPS: %sprite.play("fall")
	elif moveDirection: %sprite.play("run")
	else: %sprite.play("idle")

func _process(_delta:float) -> void:
	if game.playState == Game.PLAY_STATE.PAUSED:
		%sprite.pause()
		return

	nearDoor = false
	for area in %near.get_overlapping_areas():
		var object:GameObject = area.get_parent()
		if object is Door:
			nearDoor = true
			break

func receiveKey(event:InputEventKey):
	match event.keycode:
		KEY_P: game.pauseTest()
		KEY_O: game.stopTest()
		KEY_R: game.restart()
		KEY_Z: if gameChanges.undo(): %undoSound.play()

func _interacted(area:Area2D):
	var object:GameObject = area.get_parent()
	if object is KeyBulk:
		object.collect(self)
	elif object is Door:
		object.tryOpen(self)

func _near(area:Area2D):
	var _object:GameObject = area.get_parent()
