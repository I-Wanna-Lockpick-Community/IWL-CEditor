extends AnimatedSprite2D
class_name ExplosionParticle

const SPRITE_FRAMES:SpriteFrames = preload("res://resources/explosionParticle.tres")

func _init(_position:Vector2,animationSign:int) -> void:
	position = _position
	sprite_frames = SPRITE_FRAMES
	play("positive" if animationSign > 0 else "negative")
	animation_finished.connect(queue_free)
