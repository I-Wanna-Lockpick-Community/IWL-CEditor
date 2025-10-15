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
	if editor.componentHovered:
		drawOutline(editor.componentHovered,Color("#00a2ff88"))
	if editor.focusDialog.componentFocused:
		drawOutline(editor.focusDialog.componentFocused,Color("#00a2ffff"))

func drawOutline(component:GameComponent,color:Color=Color.WHITE) -> void:
	var pos:Vector2 = component.getDrawPosition()
	if component is KeyBulk:
		RenderingServer.canvas_item_add_texture_rect(drawShader,Rect2(pos,component.size),component.outlineTex(),false,color)
	if component is Door or component is Lock:
		RenderingServer.canvas_item_add_polyline(drawNormal,[ # cant just rectangle with the drawshader since uv doesnt work with rectangles, and there isnt a rectangle outline either from what i can tell
			pos,
			pos+Vector2(component.size.x+1/editor.game.editorCamera.zoom.x,0),
			pos+component.size+Vector2.ONE/editor.game.editorCamera.zoom,
			pos+Vector2(0,component.size.y+1/editor.game.editorCamera.zoom.x),
			pos # bitch
		],[color,color,color,color],2/editor.game.editorCamera.zoom.x)

func _process(_delta) -> void:
	draw()
