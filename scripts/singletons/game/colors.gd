extends Node
class_name C

var COLORS:int = 0
var DEFINITIONS:Array[ColorDef] = []

# reference this as C.olors so that it can be a constant expression, but reference everything else as Colors.[thing]
enum olors {MASTER, WHITE, ORANGE, PURPLE, RED, GREEN, BLUE, PINK, CYAN, BLACK, BROWN, PURE, GLITCH, STONE, DYNAMITE, QUICKSILVER, MAROON, FOREST, NAVY, ICE, MUD, GRAFFITI, NONE, ERROR, COSMIC, FIRE, WATER, EARTH, AIR}

func _init() -> void:
	# only add at the end, please!
	defineColor("Master",		Color("#e7bf98"), Color("#d68f49"), Color("#9c6023")).animatedKeys(4).animatedDoors(4)
	defineColor("White",		Color("#edeae7"), Color("#d6cfc9"), Color("#bbaea4"))
	defineColor("Orange",		Color("#e7bf98"), Color("#d68f49"), Color("#9c6023"))
	defineColor("Purple",		Color("#bfa4db"), Color("#8f5fc0"), Color("#603689"))

	defineColor("Red",			Color("#c83737"), Color("#8f1b1b"), Color("#480d0d")) \
				   .brightTones(Color("#eb3737"), Color("#a11b1b"), Color("#6b0d0d"))
	defineColor("Green",		Color("#70cf88"), Color("#359f50"), Color("#1b5028"))
	defineColor("Blue",			Color("#8795b8"), Color("#5f71a0"), Color("#3a4665"))

	defineColor("Pink",			Color("#e4afca"), Color("#cf709f"), Color("#af3a75"))
	defineColor("Cyan",			Color("#8acaca"), Color("#50afaf"), Color("#357575")) \
				   .brightTones(Color("#8acaf8"), Color("#50afd1"), Color("#357592"))
	defineColor("Black",		Color("#554b40"), Color("#363029"), Color("#181512"))

	defineColor("Brown",		Color("#aa6015"), Color("#704010"), Color("#382007"))
	defineColor("Pure",			Color("#edeae7"), Color("#d6cfc9"), Color("#bbaea4")).animatedKeys(4).animatedDoors(4)
	defineColor("Glitch",		Color("#78be00"), Color("#b49600"), Color("#dc6e00")).unconfigurableTone()
	defineColor("Stone",		Color("#96a0a5"), Color("#647378"), Color("#3c4b50")).texturedKeys().texturedDoors()

	# MODDED

	defineColor("Dynamite",		Color("#d18866"), Color("#d34728"), Color("#7a3117")).animatedKeys(12).animatedDoors(12, true)
	defineColor("Quicksilver",	Color("#ffffff"), Color("#b8b8b8"), Color("#818181")).animatedKeys(4).animatedDoors(4)

	defineColor("Maroon",		Color("#6d4040"), Color("#583232"), Color("#3b1f1f"))
	defineColor("Forest",		Color("#3f5c3f"), Color("#2c3b2c"), Color("#1b5028"))
	defineColor("Navy",			Color("#49496b"), Color("#333352"), Color("#262633"))
	
	defineColor("Ice",			Color("#d1ffff"), Color("#82f0ff"), Color("#62b6c1")).texturedKeys()
	defineColor("Mud",			Color("#b57ea7"), Color("#966489"), Color("#7f4972")).texturedKeys()
	defineColor("Graffiti",		Color("#f2e380"), Color("#e2c961"), Color("#c6af51")).texturedKeys()

	defineColor("None",			Color("#0000"),   Color("#0000"),   Color("#0000")  ).unconfigurableTone()
	defineColor("Error",		Color("#ffffff"), Color("#006dff"), Color("#006dff")).texturedKeys().texturedDoors(true)
	defineColor("Cosmic",		Color("#240a44"), Color("#19072f"), Color("#110521")).texturedKeys().animatedDoors(8, true) \
				   .brightTones(Color("#340e62"), Color("#240a44"), Color("#19072f"))

	defineColor("Fire",		Color("#a79437"), Color("#ad511b"), Color("#8e0d0d"))
	defineColor("Water",	Color("#54a7ff"), Color("#3d95f5"), Color("#166ccc"))
	defineColor("Earth",	Color("#99bb00"), Color("#779900"), Color("#664400"))
	defineColor("Air",		Color("#a6ccee"), Color("#86accc"), Color("#688cac"))

func getDef(color:C.olors) -> ColorDef: return DEFINITIONS[color]
func getName(color:C.olors) -> String: return DEFINITIONS[color].name


func defineColor(_name:String, _highTone:Color, _mainTone:Color, _darkTone:Color) -> ColorDef:
	var color:ColorDef = ColorDef.new()
	color.id = COLORS
	color.name = _name
	color.highTone = _highTone
	color.mainTone = _mainTone
	color.darkTone = _darkTone
	color.DEFAULT_HIGH = _highTone
	color.DEFAULT_MAIN = _mainTone
	color.DEFAULT_DARK = _darkTone
	color.BRIGHT_HIGH = _highTone
	color.BRIGHT_MAIN = _mainTone
	color.BRIGHT_DARK = _darkTone
	DEFINITIONS.append(color)
	COLORS += 1
	return color

class ColorDef extends RefCounted:
	var id:int
	var name:String
	
	var highTone:Color
	var mainTone:Color
	var darkTone:Color
	var DEFAULT_HIGH:Color
	var DEFAULT_MAIN:Color
	var DEFAULT_DARK:Color
	var BRIGHT_HIGH:Color
	var BRIGHT_MAIN:Color
	var BRIGHT_DARK:Color

	var toneConfigurable:bool = true

	var keyTexture:bool = false
	var keyTextureFrames:int = 1

	var doorTexture:bool = false
	var doorTextureTile:bool = false
	var doorTextureFrames:int = 1

	func brightTones(_highTone:Color, _mainTone:Color, _darkTone:Color) -> ColorDef:
		BRIGHT_HIGH = _highTone
		BRIGHT_MAIN = _mainTone
		BRIGHT_DARK = _darkTone
		return self
	
	func unconfigurableTone() -> ColorDef:
		toneConfigurable = false
		return self

	func texturedKeys() -> ColorDef:
		if doorTexture: toneConfigurable = false
		keyTexture = true
		return self

	func animatedKeys(frames:int) -> ColorDef:
		if doorTexture: toneConfigurable = false
		keyTexture = true
		keyTextureFrames = frames
		return self
	
	func texturedDoors(tiled:bool=false) -> ColorDef:
		if keyTexture: toneConfigurable = false
		doorTexture = true
		doorTextureTile = tiled
		return self

	func animatedDoors(frames:int, tiled:bool=false) -> ColorDef:
		if keyTexture: toneConfigurable = false
		doorTexture = true
		doorTextureFrames = frames
		doorTextureTile = tiled
		return self
