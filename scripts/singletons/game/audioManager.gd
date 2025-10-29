extends Node

@onready var editor:Editor = get_node("/root/editor")

func play(stream:AudioStream) -> AudioStreamPlayer:
	var player:AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	editor.add_child(player)
	player.play()
	return player
