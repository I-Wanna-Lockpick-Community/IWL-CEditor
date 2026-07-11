class_name PencilmarkTypeSelector
extends Selector

const ICONS:Array[Texture2D] = [
	preload("res://assets/game/gameUI/pencilmark/sprMarkUIButtons_0.png"),
	preload("res://assets/game/gameUI/pencilmark/sprMarkUIButtons_1.png"),
	preload("res://assets/game/gameUI/pencilmark/sprMarkUIButtons_2.png"),
]

# func _ready() -> void:
# 	columns = KeyBulk.TYPES
# 	options = range(KeyBulk.TYPES)
# 	defaultValue = KeyBulk.TYPE.NORMAL
# 	buttonType = KeyTypeSelectorButton
# 	super()
# 	for button in buttons:
# 		var explanation:ControlExplanation
# 		match button.value:
# 			KeyBulk.TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal key type", [&"focusKeyNormal"])
# 			KeyBulk.TYPE.EXACT: explanation = ControlExplanation.new("[%s]Set exact key type", [&"focusKeyExact"])
# 			KeyBulk.TYPE.STAR: explanation = ControlExplanation.new("[%s]Toggle star key type", [&"focusKeyStar"])
# 			KeyBulk.TYPE.ROTOR: explanation = ControlExplanation.new("[%s]Advance rotor key type", [&"focusKeyRotor"])
# 			KeyBulk.TYPE.CURSE: explanation = ControlExplanation.new("[%s]Toggle curse key type", [&"focusKeyCurse"])
# 			KeyBulk.TYPE.OPERATOR: explanation = ControlExplanation.new("[%s]Toggle operation key type", [&"focusKeyOperator"])
# 		Explainer.addControl(button,explanation)

# func changedMods() -> void:
# 	var keyTypes:Array[KeyBulk.TYPE] = Mods.keyTypes()
# 	for button in buttons: button.visible = false
# 	for keyType in keyTypes: buttons[keyType].visible = true
# 	columns = len(keyTypes)

# class KeyTypeSelectorButton extends SelectorButton:
# 	var drawMain:RID

# 	func _init(_value:KeyBulk.TYPE, _selector:KeyTypeSelector):
# 		custom_minimum_size = Vector2(16,16)
# 		z_index = 1
# 		super(_value, _selector)
# 		icon = ICONS[value]
