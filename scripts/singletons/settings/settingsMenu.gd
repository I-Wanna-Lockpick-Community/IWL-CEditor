extends PanelContainer
class_name SettingsMenu

@onready var levelSettings:MarginContainer = %levelSettings
@onready var editorSettings:MarginContainer = %editorSettings
@onready var gameSettings:GameSettings = %gameSettings

var configFile:ConfigFile = ConfigFile.new()

func _ready() -> void:
	_tabSelected(0)

func _input(event:InputEvent) -> void:
	if !Game.editor.settingsOpen: return
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ESCAPE:
				Game.editor._toggleSettingsMenu(false)
				get_viewport().set_input_as_handled()

func receiveMouseInput(event:InputEvent) -> void:
	%levelSettings.receiveMouseInput(event)

func _tabSelected(tab:int) -> void:
	%levelSettings.visible = tab == 0
	%editorSettings.visible = tab == 1
	%gameSettings.visible = tab == 2
	mouse_filter = Control.MOUSE_FILTER_PASS if tab == 0 else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_ARROW
	queue_redraw()

func opened() -> void:
	configFile.load("user://config.ini")
	%levelSettings.opened(configFile)
	%editorSettings.opened(configFile)
	%gameSettings.opened(configFile)

func closed() -> void:
	%levelSettings.closed(configFile)
	%editorSettings.closed(configFile)
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")
