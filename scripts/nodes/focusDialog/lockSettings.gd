extends HBoxContainer
class_name LockSettings

func changedMods() -> void:
	%lockSettingsSep.visible = mods.active(&"C1")
	%lockNegated.visible = mods.active(&"C1")
