extends MenuButton
class_name FileMenu

@onready var menu:PopupMenu = get_popup()

func _ready() -> void:
	menu.theme_type_variation = &"PopupMenuFiles"
	menu.id_pressed.connect(optionPressed)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(2, KEY_MASK_CMD_OR_CTRL | KEY_S)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(3, KEY_MASK_CMD_OR_CTRL | KEY_MASK_SHIFT | KEY_S)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(4, KEY_MASK_CMD_OR_CTRL | KEY_E)

func optionPressed(id:int) -> void:
	match id:
		# FILE
		0: pass # new
		1: pass # open
		2: pass # save
		3: pass # save as
		4: pass # export
		# CONFIG
		6: mods.openModsWindow()
