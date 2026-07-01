extends MarginContainer
class_name HotkeySetting
var definition:EditorSettingss.Hotkey
var input:InputEvent

var buttons:Array[HotkeySettingButton]

var invisibleOverride:bool = false

func overrideVisibility() -> void:
	invisibleOverride = true
	visible = false

func _ready() -> void:
	%label.text = definition.label + (" (held modifier)" if definition.held else "")
	InputMap.add_action(definition.action)

func changedMods() -> void:
	visible = (!definition.prerequisite or Mods.active(definition.prerequisite)) and !invisibleOverride
	for button in buttons: button.check()

func _hover() -> void: %label.add_theme_color_override("font_color", Color("#ffffff")); %hover.visible = true
func _unhover() -> void: %label.add_theme_color_override("font_color", Color("#bfbfbf")); %hover.visible = false

func _add():
	var button:HotkeySettingButton = HotkeySettingButton.new(self)
	button._startSet()
	%buttons.add_child(button)
	%buttons.move_child(button, 1)
	buttons.append(button)

func updateReset() -> void:
	%reset.disabled = equalToDefault()

func equalToDefault() -> bool:
	var events:Array[InputEvent] = InputMap.action_get_events(definition.action)
	if len(definition.defaultEvents) != len(events): return false
	for i in len(definition.defaultEvents):
		if !definition.defaultEvents[i].is_match(events[i]): return false
	return true

func _reset(to:Array[InputEvent]=definition.defaultEvents):
	for button in buttons.duplicate(): button.remove()
	buttons.clear()
	InputMap.action_erase_events(definition.action)
	for event in to:
		InputMap.action_add_event(definition.action, event)
		var button:HotkeySettingButton = HotkeySettingButton.new(self)
		button.event = event
		%buttons.add_child(button)
		buttons.append(button)
	updateReset()

class HotkeySettingButton extends Button:
	var hotkey:HotkeySetting
	var event:InputEvent

	var changed:bool = false
	var setting:bool = false # current changing this one
	var conflictingButtons:Array[HotkeySettingButton] = []

	func _init(_hotkey:HotkeySetting) -> void:
		hotkey = _hotkey
		theme_type_variation = &"RadioButtonText"
		custom_minimum_size.x = 180
		toggle_mode = true
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _ready() -> void:
		mouse_entered.connect(func(): if !setting: text = "(RMB to remove)")
		mouse_exited.connect(_cancelSet)
		setText()

	func _process(_delta:float) -> void:
		if setting: setText()

	func setText() -> void:
		if setting:
			text = ""
			if Input.is_key_pressed(KEY_CTRL): text += "Ctrl+"
			if Input.is_key_pressed(KEY_SHIFT): text += "Shift+"
			if Input.is_key_pressed(KEY_ALT): text += "Alt+"
			if !text: text = "(Unhover to cancel)"
			elif hotkey.definition.held: text = text.left(-1)
		else:
			assert(event is InputEventKey)
			text = event.as_text_physical_keycode()
	
	func _startSet() -> void:
		button_pressed = true
		setting = true
		if event: InputMap.action_erase_event(hotkey.definition.action, event)
		setText()
	
	func _cancelSet() -> void:
		button_pressed = false
		setting = false
		if !event: remove()
		else:
			InputMap.action_add_event(hotkey.definition.action, event)
			setText()
		if changed:
			changed = false
			check()

	func _gui_input(_event:InputEvent) -> void:
		if _event is InputEventMouseButton and _event.pressed:
			if !setting:
				match _event.button_index:
					MOUSE_BUTTON_LEFT: _startSet()
					MOUSE_BUTTON_RIGHT:
						if event:
							InputMap.action_erase_event(hotkey.definition.action, event)
							check()
						remove()
					_: return
			else: _cancelSet()
			get_viewport().set_input_as_handled()
 
	func _input(_event:InputEvent) -> void:
		if !setting or _event is InputEventMouse or !_event.pressed: return
		if _event is InputEventKey and _event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META] and !hotkey.definition.held: return
		_event.keycode = 0
		_event.unicode = 0
		_event.pressed = false
		for checkEvent in InputMap.action_get_events(hotkey.definition.action):
			if checkEvent.is_match(_event): return
		event = _event
		changed = true
		get_viewport().set_input_as_handled()
		_cancelSet()

	func remove() -> void:
		mouse_exited.disconnect(_cancelSet) # sneaky
		clearConflicts()
		hotkey.buttons.erase(self)
		queue_free()

	func check() -> void:
		hotkey.updateReset()
		clearConflicts()
		if !hotkey.visible: return
		for checkHotkey in hotkey.get_parent().get_children():
			if checkHotkey is not HotkeySetting: continue
			if !checkHotkey.visible: continue
			for button in checkHotkey.buttons:
				if button == self: continue
				if button.event.is_match(event):
					conflictingButtons.append(button)
					button.conflictingButtons.append(self)
					theme_type_variation = &"ConflictedHotkeySettingButton"
					button.theme_type_variation = &"ConflictedHotkeySettingButton"

	func clearConflicts() -> void:
		for button in conflictingButtons:
			button.conflictingButtons.erase(self)
			if len(button.conflictingButtons) == 0: button.theme_type_variation = &"RadioButtonText"
		theme_type_variation = &"RadioButtonText"
		conflictingButtons.clear()
