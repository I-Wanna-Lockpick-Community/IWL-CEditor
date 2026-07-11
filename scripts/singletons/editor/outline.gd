extends Node2D
class_name Outline

var drawNormal:RID

# see outlineViewport.gd for how this works

func _ready() -> void:
	drawNormal = %outlineViewport2.createChild()

func draw() -> void:
	RenderingServer.canvas_item_clear(drawNormal)
	if Game.playState == Game.PLAY_STATE.PLAY: return
	if Game.editor.settingsOpen:
		if Game.editor.settingsMenu.levelSettings.visible: drawOutline(Game.editor.levelBoundsObject,Color.GREEN)
	else: 
		if Game.editor.focusDialog.focused: drawOutline(Game.editor.focusDialog.focused,Color("#0f0a"))
		if Game.editor.focusDialog.componentFocused: drawOutline(Game.editor.focusDialog.componentFocused,Color.RED)
		if Game.editor.multiselect.state == Multiselect.STATE.HOLDING:
			if Game.editor.objectHovered and Game.editor.objectHovered != Game.editor.focusDialog.focused: drawOutline(Game.editor.objectHovered,Color("#0f05"))
			if Game.editor.componentHovered and Game.editor.componentHovered != Game.editor.focusDialog.componentFocused: drawOutline(Game.editor.componentHovered,Color("#f008"))

func drawOutline(component:GameComponent,color:Color) -> void:
	var pos:Vector2 = component.getDrawPosition()
	if component.get_script() in Game.RECTANGLE_COMPONENTS:
		RenderingServer.canvas_item_add_rect(drawNormal,Rect2(pos,component.getDrawSize()),color)
	else:
		RenderingServer.canvas_item_add_texture_rect(drawNormal,Rect2(pos,component.getDrawSize()),component.outlineTex(),false,color)

func _process(_delta) -> void:
	draw()
