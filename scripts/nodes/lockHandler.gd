extends Handler
class_name LockHandler

@onready var colorLink:Button = %colorLink

var door:Door

func setup(_door:Door) -> void:
	door = _door
	deleteButtons()
	for index in len(door.locks):
		var button:LockHandlerButton = LockHandlerButton.new(index, self)
		buttons.append(button)
		add_child(button)
	move_child(add, -1)
	move_child(remove, -1)
	move_child(colorLink, -1)
	colorLink.visible = door.type == Door.TYPE.SIMPLE
	remove.visible = len(buttons) > 0

func addComponent() -> void: door.addLock()
func removeComponent() -> void: door.removeLock(selected)

static func buttonType() -> GDScript: return LockHandlerButton

func addButton(index:int=len(buttons)) -> void:
	super(index)
	move_child(colorLink, -1)

func removeButton(index:int=selected) -> void:
	super(index)
	colorLink.visible = false

func _select(button:Button) -> void:
	if button is not LockHandlerButton: return
	super(button)
	if !manuallySetting: editor.focusDialog.focusComponent(door.locks[selected])

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

	func _init(_index:int,_selector:LockHandler) -> void:
		super(_index, _selector)
		lock = selector.door.locks[index]
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		await get_tree().process_frame # control positioning jank. figure out some way to fix this
		queue_redraw()

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
