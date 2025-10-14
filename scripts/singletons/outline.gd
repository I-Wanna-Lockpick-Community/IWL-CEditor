extends Node2D
class_name Outline

const OUTLINE_MATERIAL:ShaderMaterial = preload("res://resources/outlineDrawMaterial.tres")

@onready var editor:Editor = get_node("/root/editor")

var drawShader:RID
var drawNormal:RID

func _ready() -> void:
	drawShader = RenderingServer.canvas_item_create()
	drawNormal = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawShader,OUTLINE_MATERIAL)
	RenderingServer.canvas_item_set_parent(drawShader,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawNormal,get_canvas_item())

func draw() -> void:
	RenderingServer.canvas_item_clear(drawShader)
	RenderingServer.canvas_item_clear(drawNormal)
	if editor.focusDialog.focused:
		drawOutline(editor.focusDialog.focused)
	if editor.objectHovered:
		drawOutline(editor.objectHovered,Color("#ffffff88"))

func drawOutline(object:GameObject,color:Color=Color.WHITE) -> void:
	if object is KeyBulk:
		RenderingServer.canvas_item_add_texture_rect(drawShader,Rect2(object.position,object.size),object.outlineTex(),false,color)
	if object is Door:
		RenderingServer.canvas_item_add_polyline(drawNormal,[ # cant just rectangle with the drawshader since uv doesnt work with rectangles, and there isnt a rectangle outline either from what i can tell
			object.position,
			object.position+Vector2(object.size.x+1/editor.game.editorCamera.zoom.x,0),
			object.position+object.size+Vector2.ONE/editor.game.editorCamera.zoom,
			object.position+Vector2(0,object.size.y+1/editor.game.editorCamera.zoom.x),
			object.position # bitch
		],[color,color,color,color],1/editor.game.editorCamera.zoom.x)

func _process(_delta) -> void:
	draw()
