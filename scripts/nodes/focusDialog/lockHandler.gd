extends Handler
class_name LockHandler

@onready var colorLink:Button = %colorLink

var door:Door

func _ready() -> void:
	super()
	Explainer.addControl(add,ControlExplanation.new("[%s]Add lock",[&"focusDoorAddLock"]))

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

func addComponent() -> void:
	if door.type == Door.TYPE.SIMPLE: Changes.addChange(Changes.PropertyChange.new(door,&"type",Door.TYPE.COMBO)) # precoerce so that lock sizes are accurate for placing
	door.addLock()
func removeComponent() -> void: door.removeLock(selected)

static func buttonType() -> GDScript: return LockHandlerButton

func addButton(index:int=len(buttons),select:bool=true) -> void:
	super(index,select)
	move_child(colorLink, -1)

func removeButton(index:int=selected,select:bool=true) -> void:
	super(index,select)
	colorLink.visible = false

func _select(button:Button) -> void:
	if button is not LockHandlerButton: return
	super(button)
	if !manuallySetting: Game.editor.focusDialog.focusComponent(door.locks[selected])

class LockHandlerButton extends HandlerButton:
	const ICONS:Array[Texture2D] = [
		preload("res://assets/ui/focusDialog/lockHandler/normal.png"), preload("res://assets/ui/focusDialog/lockHandler/imaginary.png"),
		preload("res://assets/ui/focusDialog/lockHandler/blank.png"), preload("res://assets/ui/focusDialog/lockHandler/blank.png"),
		preload("res://assets/ui/focusDialog/lockHandler/blast.png"), preload("res://assets/ui/focusDialog/lockHandler/blasti.png"),
		preload("res://assets/ui/focusDialog/lockHandler/all.png"), preload("res://assets/ui/focusDialog/lockHandler/all.png"),
		preload("res://assets/ui/focusDialog/lockHandler/exact.png"), preload("res://assets/ui/focusDialog/lockHandler/exacti.png"),
		preload("res://assets/ui/focusDialog/lockHandler/glistening.png"), preload("res://assets/ui/focusDialog/lockHandler/glisteningi.png"),
		preload("res://assets/ui/focusDialog/lockHandler/remainder.png"), preload("res://assets/ui/focusDialog/lockHandler/remainder.png"),
	]

	var lock:Lock

	var drawMain:RID

	func _init(_index:int,_handler:LockHandler) -> void:
		super(_index, _handler)
		lock = handler.door.locks[index]
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		Game.connect(&"goldIndexChanged",queue_redraw)
		queue_redraw()

	func _freed() -> void:
		RenderingServer.free_rid(drawMain)

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		if deleted or !lock: return
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		if lock.color == C.olors.GLITCH: RenderingServer.canvas_item_set_material(drawMain, Game.GLITCH_MATERIAL)
		else: RenderingServer.canvas_item_set_material(drawMain, Game.NO_MATERIAL)
		if Colors.getDef(lock.color).doorTexture: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,Game.COLOR_TEXTURES.current([lock.color]))
		else: RenderingServer.canvas_item_add_rect(drawMain,rect,Game.mainTone[lock.color])
		icon = ICONS[lock.type*2 + int(M.isNonzeroImag(lock.count))]
