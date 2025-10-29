extends HFlowContainer
class_name Handler

@onready var editor:Editor = get_node("/root/editor")
@export var buttonGroup:ButtonGroup

var buttons:Array[HandlerButton] = []
var add:Button
var remove:Button
var selected:int

var manuallySetting:bool = false # dont send signal (hacky)

func _ready() -> void:
	add = Button.new()
	add.theme_type_variation = &"SelectorButton"
	add.icon = preload("res://assets/ui/focusDialog/handler/add.png")
	add.connect(&"pressed", addComponent)
	add_child(add)
	remove = Button.new()
	remove.theme_type_variation = &"SelectorButton"
	remove.icon = preload("res://assets/ui/focusDialog/handler/remove.png")
	remove.connect(&"pressed", removeComponent)
	add_child(remove)

	buttonGroup.connect("pressed", _select)

func addComponent() -> void: pass
func removeComponent() -> void: pass

func deleteButtons() -> void:
	for button in buttons:
		button.deleted = true
		button._draw()
		button.queue_free()
	buttons = []

func setSelect(index:int) -> void:
	manuallySetting = true
	buttons[index].button_pressed = true
	manuallySetting = false
	selected = index

func _select(button:Button) -> void: # not necessarily HandlerButton since lockhandler's buttongroup is shared with %spend
	selected = button.index

static func buttonType() -> GDScript: return HandlerButton

func addButton(index:int=len(buttons)) -> void:
	var button:HandlerButton = buttonType().new(index, self)
	buttons.append(button)
	add_child(button)
	move_child(add, -1)
	move_child(remove, -1)
	button.button_pressed = true
	remove.visible = true

func removeButton(index:int=selected) -> void:
	var button:HandlerButton = buttons.pop_at(index)
	button.deleted = true
	button._draw()
	button.queue_free()
	for i in range(index, len(buttons)):
		buttons[i].index -= 1
	if len(buttons) == 0: remove.visible = false
	else: setSelect(len(buttons)-1)
	changes.bufferSave()

func redrawButton(index:int) -> void:
	buttons[index].queue_redraw()

class HandlerButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")
	
	var index:int
	var selector:Handler
	
	var deleted:bool=false

	func _init(_index:int,_selector:Handler) -> void:
		custom_minimum_size = Vector2(16,16)
		index = _index
		selector = _selector
		button_group = selector.buttonGroup
		toggle_mode = true
		z_index = 1
		theme_type_variation = &"SelectorButton"
