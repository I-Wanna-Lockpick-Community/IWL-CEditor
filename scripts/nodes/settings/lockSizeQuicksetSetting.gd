extends QuicksetSetting
class_name LockSizeQuicksetSetting

const OPTIONS:Array[ConfigurationSelector.OPTION] = [
	ConfigurationSelector.OPTION.SpecificA, ConfigurationSelector.OPTION.AnyS, ConfigurationSelector.OPTION.AnyH, ConfigurationSelector.OPTION.AnyV,
	ConfigurationSelector.OPTION.SpecificB, ConfigurationSelector.OPTION.AnyM, ConfigurationSelector.OPTION.AnyL, ConfigurationSelector.OPTION.AnyXL]

const DEFAULT_MATCHES:Array[String] = [
	"Q", "W", "1", "D", "F", "2", "3", "4"
]

static var matches:Array[String] = []

func _ready() -> void:
	columns = 4
	options = OPTIONS
	buttonType = LockSizeQuickSettingButton
	super()

class LockSizeQuickSettingButton extends QuicksetSettingButton:
	
	func _ready() -> void:
		if value == ConfigurationSelector.OPTION.SpecificA:
			custom_minimum_size = Vector2(88,24)
			icon = preload("res://assets/ui/focusDialog/door/lockConfiguration/SpecificAH.png")
		elif value == ConfigurationSelector.OPTION.SpecificB:
			custom_minimum_size = Vector2(88,24)
			icon = preload("res://assets/ui/focusDialog/door/lockConfiguration/SpecificBV.png")
		else:
			custom_minimum_size = Vector2(72,24)
			icon = ConfigurationSelector.ICONS[value]
		super()
