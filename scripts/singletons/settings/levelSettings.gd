extends MarginContainer
class_name LevelSettings

func opened(configFile:ConfigFile) -> void:
	updateLevelSettingsPosition()
	%levelNumber.text = Game.level.number
	%levelName.text = Game.level.name
	%levelAuthor.text = Game.level.author
	%levelDescription.text = Game.level.description
	%levelShortNumber.text = Game.level.shortNumber
	%levelRevision.value = Game.level.revision
	%thumbnailHideDescription.button_pressed = configFile.get_value("Game.editor", "thumbnailHideDescription", false)
	%thumbnailEntireLevel.button_pressed = configFile.get_value("Game.editor", "thumbnailEntireLevel", true)
	%thumbnailWithText.button_pressed = configFile.get_value("Game.editor", "thumbnailWithText", true)

func closed(configFile:ConfigFile) -> void:
	configFile.set_value("Game.editor", "thumbnailHideDescription", %thumbnailHideDescription.button_pressed)
	configFile.set_value("Game.editor", "thumbnailEntireLevel", %thumbnailEntireLevel.button_pressed)
	configFile.set_value("Game.editor", "thumbnailWithText", %thumbnailWithText.button_pressed)

func updateLevelSettingsPosition() -> void:
	%followWorld.worldOffset = Game.editor.levelStartCameraCenter()

func _levelNumberSet(string:String) -> void:
	Game.level.number = string
	Game.anyChanges = true
	queue_redraw()

func _levelNameSet(string:String) -> void:
	Game.level.name = string if string else "Unnamed Level"
	Game.anyChanges = true
	queue_redraw()

func _levelAuthorSet(string:String) -> void:
	Game.level.author = string
	Game.anyChanges = true
	queue_redraw()

func _levelDescriptionSet():
	Game.level.description = %levelDescription.text
	Game.anyChanges = true

func _levelShortNumberSet(string:String) -> void:
	Game.level.shortNumber = string
	Game.anyChanges = true
	queue_redraw()

func _defocus() -> void:
	if !%levelName.text:
		%levelName.text = "Unnamed Level"
		_levelNameSet(%levelName.text)

func _levelRevisionSet(value:float) -> void:
	Game.level.revision = int(value)
	Game.anyChanges = true

func _generateThumbnail() -> void:
	Game.editor.outline.visible = false
	await Game.editor.takeThumbnailScreenshot(Game.editor.thumbnailWithText)
	Game.editor.outline.visible = true

func _thumbnailHideDescriptionSet(toggled_on:bool) -> void:
	Game.editor.thumbnailHideDescription = toggled_on

func _thumbnailEntireLevelSet(toggled_on:bool) -> void:
	Game.editor.thumbnailEntireLevel = toggled_on

func _thumbnailWithText(toggled_on: bool) -> void:
	Game.editor.thumbnailWithText = toggled_on
