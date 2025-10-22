extends Handler
class_name LockHandler

@onready var colorLink:Button = %colorLink

var door:Door

func setup(_door:Door) -> void:
	door = _door
	deleteButtons()
	for lock in door.locks:
		var button:LockHandlerButton = LockHandlerButton.new(len(buttons), self, lock)
		buttons.append(button)
		add_child(button)
	remove_child(add)
	remove_child(remove)
	remove_child(colorLink)
	add_child(add)
	add_child(remove)
	add_child(colorLink)
	colorLink.visible = door.type == Door.TYPE.SIMPLE

func _addElement() -> void:
	var lock:Lock = editor.changes.addChange(Changes.CreateComponentChange.new(editor.game,Lock,{&"position":getFirstFreePosition(),&"parentId":door.id})).result
	if len(door.locks) == 1: editor.focusDialog._doorTypeSelected(Door.TYPE.SIMPLE)
	elif door.type != Door.TYPE.GATE: editor.focusDialog._doorTypeSelected(Door.TYPE.COMBO)
	colorLink.visible = door.type == Door.TYPE.SIMPLE
	var button:LockHandlerButton = LockHandlerButton.new(len(buttons), self, lock)
	addButton(button)
	remove_child(colorLink)
	add_child(colorLink)
	editor.changes.bufferSave()

func _removeElement() -> void: # -1 for automatic
	editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,door.locks[selected]))
	if door.type != Door.TYPE.GATE: editor.focusDialog._doorTypeSelected(Door.TYPE.COMBO)
	colorLink.visible = false
	super()

func _select(button:Button) -> void:
	if button is not LockHandlerButton: return
	super(button)
	if !manuallySetting: editor.focusDialog.focusComponent(door.locks[selected])

func getFirstFreePosition() -> Vector2:
	var x:float = 0
	while true:
		for y in floor(door.size.y/32):
			var rect:Rect2 = Rect2(Vector2(32*x+7,32*y+7), Vector2(32,32))
			var overlaps:bool = false
			for lock in door.locks:
				if Rect2(lock.position-lock.getOffset(), lock.size).intersects(rect):
					overlaps = true
					break
			if overlaps: continue
			return Vector2(32*x,32*y)
		x += 1
	return Vector2.ZERO # unreachable

class LockHandlerButton extends HandlerButton:
	const ICONS:Array[Texture2D] = [
		preload("res://assets/ui/focusDialog/lockHandler/normal.png"), preload("res://assets/ui/focusDialog/lockHandler/imaginary.png"),
		preload("res://assets/ui/focusDialog/lockHandler/blank.png"), preload("res://assets/ui/focusDialog/lockHandler/blank.png"),
		preload("res://assets/ui/focusDialog/lockHandler/blast.png"), preload("res://assets/ui/focusDialog/lockHandler/blasti.png"),
		preload("res://assets/ui/focusDialog/lockHandler/all.png"), preload("res://assets/ui/focusDialog/lockHandler/all.png"),
		preload("res://assets/ui/focusDialog/lockHandler/exact.png"), preload("res://assets/ui/focusDialog/lockHandler/exacti.png"),
	]

	var lock:Lock

	var drawMain:RID

	func _init(_index:int,_selector:LockHandler, _lock:Lock) -> void:
		super(_index, _selector)
		lock = _lock
	
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
