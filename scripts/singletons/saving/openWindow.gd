extends Window
class_name OpenWindow

var level:Level

var screenshot:Image

var mods:Array[StringName]
var modpack:Mods.Modpack = null
var version:Mods.Version = null
var fileVersion:FileVersion

var path:String
var loader:GDScript
var file:FileAccess

var levelStart:int

func _ready() -> void:
	%name.text = level.name
	if level.description: %desc.text = level.description
	if level.author: %author.text = level.author
	%revision.text = "Rev. " + str(level.revision)
	%image.texture = ImageTexture.create_from_image(screenshot)
	if modpack: %modpack.texture = modpack.iconSmall
	else: %modpack.visible = false
	%mods.text = textifyMods(mods,modpack,version)
	if levelStart == -1:
		%play.disabled = true
		%play.text = "Play (disabled; no level start)"
	await get_tree().process_frame
	grab_focus()

static func textifyMods(activeMods:Array[StringName], activeModpack:Mods.Modpack, activeVersion:Mods.Version) -> String:
	var string:String = ""
	if activeMods: string = ", ".join(activeMods.filter(func(mod): return Mods.mods[mod].disclosatory).map(func(mod): return Mods.mods[mod].name))
	if string: string += ", "
	if activeModpack:
		var modpackMods:String = ", ".join(activeVersion.mods.map(func(mod): return Mods.mods[mod].name)) + ")"
		string += activeModpack.name + " (" + activeVersion.name + (": " + modpackMods if modpackMods != ")" else ")")
	else: string += ", ". join(activeMods.filter(func(mod): return !Mods.mods[mod].disclosatory).map(func(mod): return Mods.mods[mod].name))
	return string

func _close() -> void:
	file.close()
	queue_free()

func _play() -> void:
	await get_tree().process_frame
	Game.playSaved(self)

func _edit() -> void: resolve()

func resolve() -> void:
	Saving.clear()
	Saving.savePath = path
	level.activate()
	if Game.editor: Game.editor.screenshot = screenshot
	for mod in mods: Mods.mods[mod].active = true
	Mods.activeModpack = modpack
	Mods.activeVersion = version
	Mods.updateNumberSystem()
	loader.loadFile(file, fileVersion)
	if levelStart != -1:
		Game.levelStart = Game.objects[levelStart]
		if Game.editor:
			Game.editor.home()
			Game.editor.topBar._updateButtons()
	_close()
