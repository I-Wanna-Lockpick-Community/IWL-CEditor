extends HFlowContainer
class_name LockSelector

@onready var editor:Editor = get_node("/root/editor")
@onready var addLock:Button = %addLock
@onready var colorLink:Button = %colorLink

var selected:int
var buttons:Array[LockSelectorButton] = []
var door:Door

var manuallySetting:bool = false # dont send signal (hacky)
@export var buttonGroup:ButtonGroup

func _ready() -> void:
	buttonGroup.connect("pressed", _select)

func setSelect(index:int) -> void:
	manuallySetting = true
	buttons[index].button_pressed = true
	manuallySetting = false
	selected = index

func _select(button:Button):
	if button is LockSelectorButton:
		selected = button.index
		if !manuallySetting: editor.focusDialog.focusComponent(door.locks[selected])

func setup(_door:Door) -> void:
	door = _door
	for button in buttons:
		button.deleted = true
		button._draw()
		button.queue_free()
	buttons = []
	remove_child(addLock)
	remove_child(colorLink)
	for lock in door.locks:
		var button:LockSelectorButton = LockSelectorButton.new(len(buttons), self, lock)
		buttons.append(button)
		add_child(button)
	add_child(addLock)
	add_child(colorLink)
	colorLink.visible = door.type == Door.TYPE.SIMPLE

func redrawButtons() -> void: for button in buttons: button.queue_redraw()
func redrawButton(index:int) -> void:
	buttons[index].queue_redraw()

func _addLock():
	var lock:Lock = editor.changes.addChange(Changes.CreateComponentChange.new(editor.game,Lock,{&"position":Vector2i.ZERO,&"doorId":door.id})).result
	if len(door.locks) == 1: editor.focusDialog._doorTypeSelected(Door.TYPE.SIMPLE)
	elif door.type != Door.TYPE.GATE: editor.focusDialog._doorTypeSelected(Door.TYPE.COMBO)
	colorLink.visible = door.type == Door.TYPE.SIMPLE
	var button:LockSelectorButton = LockSelectorButton.new(len(buttons), self, lock)
	buttons.append(button)
	add_child(button)
	remove_child(addLock)
	remove_child(colorLink)
	add_child(addLock)
	add_child(colorLink)
	button.button_pressed = true

func _removeLock(lock:Lock):
	editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,lock))
	if door.type != Door.TYPE.GATE: editor.focusDialog._doorTypeSelected(Door.TYPE.COMBO)
	colorLink.visible = false
	var button:Button = buttons.pop_at(lock.index)
	button.deleted = true
	button._draw()
	button.queue_free()

class LockSelectorButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")

	const ICONS:Array[Texture2D] = [
		preload("res://assets/ui/lockSelect/normal.png"), preload("res://assets/ui/lockSelect/imaginary.png"),
		preload("res://assets/ui/lockSelect/blank.png"), preload("res://assets/ui/lockSelect/blank.png"),
		preload("res://assets/ui/lockSelect/blast.png"), preload("res://assets/ui/lockSelect/blasti.png"),
		preload("res://assets/ui/lockSelect/all.png"), preload("res://assets/ui/lockSelect/all.png"),
		preload("res://assets/ui/lockSelect/exact.png"), preload("res://assets/ui/lockSelect/exacti.png"),
	]

	var index:int
	var selector:LockSelector
	var lock:Lock
	var deleted:bool=false

	var drawMain:RID

	func _init(_index:int,_selector:LockSelector, _lock:Lock) -> void:
		index = _index
		selector = _selector
		lock = _lock
		button_group = selector.buttonGroup
		toggle_mode = true
		z_index = 1
		theme_type_variation = &"SelectorButton"
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		connect(&"item_rect_changed",queue_redraw) # control positioning jank

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		if deleted: return
		var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		match lock.color:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[lock.color])
		icon = ICONS[lock.type*2 + int(lock.count.isNonzeroImag())]
