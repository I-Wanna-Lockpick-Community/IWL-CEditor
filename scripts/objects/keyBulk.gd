extends Control
class_name KeyBulk

const FILL = preload('res://assets/game/key/fill.png')
const FRAME = preload('res://assets/game/key/frame.png')
const FILL_GLITCH = preload('res://assets/game/key/fillGlitch.png')
const FRAME_GLITCH = preload('res://assets/game/key/frameGlitch.png')

@onready var editor:Editor = get_node("/root/editor")
@onready var area:Area2D = %Area2D
var glitchDraw:GlitchDrawer.DrawTexture = GlitchDrawer.DrawTexture.new()

var id:int
var color:Game.COLOR = Game.COLOR.WHITE

func _ready() -> void:
	add_child(glitchDraw)

func outlineTex() -> Texture2D:
	match color:
		Game.COLOR.MASTER: return preload('res://assets/game/key/master/outlineMask.png')
		_: return preload('res://assets/game/key/outlineMask.png')

func _draw() -> void:
	match color:
		Game.COLOR.MASTER: draw_texture(editor.game.masterKeyTex(),Vector2.ZERO)
		Game.COLOR.PURE: draw_texture(editor.game.pureKeyTex(),Vector2.ZERO)
		Game.COLOR.STONE: draw_texture(editor.game.stoneKeyTex(),Vector2.ZERO)
		Game.COLOR.GLITCH:
			draw_texture(FRAME_GLITCH,Vector2.ZERO)
			glitchDraw.draw(FILL,Vector2i.ZERO)
		_:
			draw_texture(FRAME,Vector2.ZERO)
			draw_texture(FILL,Vector2.ZERO,editor.game.mainTone[color])
	

func _process(_delta) -> void:
	queue_redraw()

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and editor.mode in [Editor.Mode.SELECT, Editor.Mode.KEY]:
				editor.focusDialog.focus(self)
				get_viewport().set_input_as_handled()
