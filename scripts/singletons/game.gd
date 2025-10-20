extends Node2D
class_name Game

const KEYTYPE_TEXTURE_OFFSETS:Array[int] = [0,1,2,3,0,0,0,0,0]

const COLORS:int = 22
enum COLOR {MASTER, WHITE, ORANGE, PURPLE, RED, GREEN, BLUE, PINK, CYAN, BLACK, BROWN, PURE, GLITCH, STONE, DYNAMITE, QUICKSILVER, MAROON, FOREST, NAVY, ICE, MUD, GRAFFITI}

static func isAnimated(color:COLOR) -> bool: return color in [COLOR.MASTER, COLOR.PURE, COLOR.DYNAMITE, COLOR.QUICKSILVER]

const MASTER_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/master0.png"),
	preload("res://assets/game/colorTexture/master1.png"),
	preload("res://assets/game/colorTexture/master2.png"),
	preload("res://assets/game/colorTexture/master3.png")
]
func masterTex() -> Texture2D: return MASTER_TEXTURE[goldIndex%4]
const MASTER_KEY_TEXTURE:Array[Texture2D] = [ # move this to keybulk probably
	preload("res://assets/game/key/master/normal0.png"),
	preload("res://assets/game/key/master/normal1.png"),
	preload("res://assets/game/key/master/normal2.png"),
	preload("res://assets/game/key/master/normal3.png"),
	preload("res://assets/game/key/master/exact0.png"),
	preload("res://assets/game/key/master/exact1.png"),
	preload("res://assets/game/key/master/exact2.png"),
	preload("res://assets/game/key/master/exact3.png"),
	preload("res://assets/game/key/master/star0.png"),
	preload("res://assets/game/key/master/star1.png"),
	preload("res://assets/game/key/master/star2.png"),
	preload("res://assets/game/key/master/star3.png"),
	preload("res://assets/game/key/master/unstar0.png"),
	preload("res://assets/game/key/master/unstar1.png"),
	preload("res://assets/game/key/master/unstar2.png"),
	preload("res://assets/game/key/master/unstar3.png"),
]
func masterKeyTex(type:KeyBulk.TYPE) -> Texture2D: return MASTER_KEY_TEXTURE[goldIndex%4 + KEYTYPE_TEXTURE_OFFSETS[type]*4]


const PURE_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/pure0.png"),
	preload("res://assets/game/colorTexture/pure1.png"),
	preload("res://assets/game/colorTexture/pure2.png"),
	preload("res://assets/game/colorTexture/pure3.png"),
]
func pureTex() -> Texture2D: return PURE_TEXTURE[goldIndex%4]
const PURE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/pure/normal0.png"),
	preload("res://assets/game/key/pure/normal1.png"),
	preload("res://assets/game/key/pure/normal2.png"),
	preload("res://assets/game/key/pure/normal3.png"),
	preload("res://assets/game/key/pure/exact0.png"),
	preload("res://assets/game/key/pure/exact1.png"),
	preload("res://assets/game/key/pure/exact2.png"),
	preload("res://assets/game/key/pure/exact3.png"),
	preload("res://assets/game/key/pure/star0.png"),
	preload("res://assets/game/key/pure/star1.png"),
	preload("res://assets/game/key/pure/star2.png"),
	preload("res://assets/game/key/pure/star3.png"),
	preload("res://assets/game/key/pure/unstar0.png"),
	preload("res://assets/game/key/pure/unstar1.png"),
	preload("res://assets/game/key/pure/unstar2.png"),
	preload("res://assets/game/key/pure/unstar3.png"),
]
func pureKeyTex(type:KeyBulk.TYPE) -> Texture2D: return PURE_KEY_TEXTURE[goldIndex%4 + KEYTYPE_TEXTURE_OFFSETS[type]*4]


func stoneTex() -> Texture2D: return preload("res://assets/game/colorTexture/stone.png")
const STONE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/stone/normal.png"),
	preload("res://assets/game/key/stone/exact.png"),
	preload("res://assets/game/key/stone/star.png"),
	preload("res://assets/game/key/stone/unstar.png"),
]
func stoneKeyTex(type:KeyBulk.TYPE) -> Texture2D: return STONE_KEY_TEXTURE[KEYTYPE_TEXTURE_OFFSETS[type]]


const DYNAMITE_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/dynamite0.png"),
	preload("res://assets/game/colorTexture/dynamite1.png"),
	preload("res://assets/game/colorTexture/dynamite2.png"),
	preload("res://assets/game/colorTexture/dynamite3.png"),
	preload("res://assets/game/colorTexture/dynamite4.png"),
	preload("res://assets/game/colorTexture/dynamite5.png"),
	preload("res://assets/game/colorTexture/dynamite6.png"),
	preload("res://assets/game/colorTexture/dynamite7.png"),
	preload("res://assets/game/colorTexture/dynamite8.png"),
	preload("res://assets/game/colorTexture/dynamite9.png"),
	preload("res://assets/game/colorTexture/dynamite10.png"),
	preload("res://assets/game/colorTexture/dynamite11.png")
]
func dynamiteTex() -> Texture2D: return DYNAMITE_TEXTURE[goldIndex]
const DYNAMITE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/dynamite/normal0.png"), preload("res://assets/game/key/dynamite/normal1.png"), preload("res://assets/game/key/dynamite/normal2.png"), preload("res://assets/game/key/dynamite/normal3.png"), preload("res://assets/game/key/dynamite/normal4.png"), preload("res://assets/game/key/dynamite/normal5.png"), preload("res://assets/game/key/dynamite/normal6.png"), preload("res://assets/game/key/dynamite/normal7.png"), preload("res://assets/game/key/dynamite/normal8.png"), preload("res://assets/game/key/dynamite/normal9.png"), preload("res://assets/game/key/dynamite/normal10.png"), preload("res://assets/game/key/dynamite/normal11.png"),
	preload("res://assets/game/key/dynamite/exact0.png"), preload("res://assets/game/key/dynamite/exact1.png"), preload("res://assets/game/key/dynamite/exact2.png"), preload("res://assets/game/key/dynamite/exact3.png"), preload("res://assets/game/key/dynamite/exact4.png"), preload("res://assets/game/key/dynamite/exact5.png"), preload("res://assets/game/key/dynamite/exact6.png"), preload("res://assets/game/key/dynamite/exact7.png"), preload("res://assets/game/key/dynamite/exact8.png"), preload("res://assets/game/key/dynamite/exact9.png"), preload("res://assets/game/key/dynamite/exact10.png"), preload("res://assets/game/key/dynamite/exact11.png"),
	preload("res://assets/game/key/dynamite/star0.png"), preload("res://assets/game/key/dynamite/star1.png"), preload("res://assets/game/key/dynamite/star2.png"), preload("res://assets/game/key/dynamite/star3.png"), preload("res://assets/game/key/dynamite/star4.png"), preload("res://assets/game/key/dynamite/star5.png"), preload("res://assets/game/key/dynamite/star6.png"), preload("res://assets/game/key/dynamite/star7.png"), preload("res://assets/game/key/dynamite/star8.png"), preload("res://assets/game/key/dynamite/star9.png"), preload("res://assets/game/key/dynamite/star10.png"), preload("res://assets/game/key/dynamite/star11.png"),
	preload("res://assets/game/key/dynamite/unstar0.png"), preload("res://assets/game/key/dynamite/unstar1.png"), preload("res://assets/game/key/dynamite/unstar2.png"), preload("res://assets/game/key/dynamite/unstar3.png"), preload("res://assets/game/key/dynamite/unstar4.png"), preload("res://assets/game/key/dynamite/unstar5.png"), preload("res://assets/game/key/dynamite/unstar6.png"), preload("res://assets/game/key/dynamite/unstar7.png"), preload("res://assets/game/key/dynamite/unstar8.png"), preload("res://assets/game/key/dynamite/unstar9.png"), preload("res://assets/game/key/dynamite/unstar10.png"), preload("res://assets/game/key/dynamite/unstar11.png")
]
func dynamiteKeyTex(type:KeyBulk.TYPE) -> Texture2D: return DYNAMITE_KEY_TEXTURE[goldIndex + KEYTYPE_TEXTURE_OFFSETS[type]*12]


const QUICKSILVER_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/silver0.png"),
	preload("res://assets/game/colorTexture/silver1.png"),
	preload("res://assets/game/colorTexture/silver2.png"),
	preload("res://assets/game/colorTexture/silver3.png")
]
func quicksilverTex() -> Texture2D: return QUICKSILVER_TEXTURE[goldIndex%4]
const QUICKSILVER_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/silver/normal0.png"),
	preload("res://assets/game/key/silver/normal1.png"),
	preload("res://assets/game/key/silver/normal2.png"),
	preload("res://assets/game/key/silver/normal3.png")
	# awaiting
]
func quicksilverKeyTex(_type:KeyBulk.TYPE) -> Texture2D: return QUICKSILVER_KEY_TEXTURE[goldIndex%4]


const ICE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/ice/normal.png"),
	preload("res://assets/game/key/ice/exact.png"),
	preload("res://assets/game/key/ice/star.png"),
	preload("res://assets/game/key/ice/unstar.png"),
]
func iceKeyTex(type:KeyBulk.TYPE) -> Texture2D: return ICE_KEY_TEXTURE[KEYTYPE_TEXTURE_OFFSETS[type]]


const MUD_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/mud/normal.png"),
	preload("res://assets/game/key/mud/exact.png"),
	preload("res://assets/game/key/mud/star.png"),
	preload("res://assets/game/key/mud/unstar.png"),
]
func mudKeyTex(type:KeyBulk.TYPE) -> Texture2D: return MUD_KEY_TEXTURE[KEYTYPE_TEXTURE_OFFSETS[type]]


const GRAFFITI_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/graffiti/normal.png"),
	preload("res://assets/game/key/graffiti/exact.png"),
	preload("res://assets/game/key/graffiti/star.png"),
	preload("res://assets/game/key/graffiti/unstar.png"),
]
func graffitiKeyTex(type:KeyBulk.TYPE) -> Texture2D: return GRAFFITI_KEY_TEXTURE[KEYTYPE_TEXTURE_OFFSETS[type]]



const highTone:Array[Color] = [
	Color8(231,191,152),
	Color8(237,234,231),
	Color8(231,191,152),
	Color8(191,164,219),
	Color8(200,55,55),
	Color8(112,207,136),
	Color8(135,149,184),
	Color8(228,175,202),
	Color8(138,202,202),
	Color8(85,75,64),
	Color8(170,96,21),
	Color8(237,234,231),
	Color8(120,190,0),
	Color8(150,160,165),
	Color8(209,136,102),
	Color8(255,255,255),
	Color8(107,32,32),
	Color8(29,92,44),
	Color8(32,50,107),
	Color8(204,231,237),
	Color8(148,89,80),
	Color8(145,163,94)
]

const mainTone:Array[Color] = [
	Color8(214,143,73),
	Color8(214,207,201),
	Color8(214,143,73),
	Color8(143,95,192),
	Color8(143,27,27),
	Color8(53,159,80),
	Color8(95,113,160),
	Color8(207,112,159),
	Color8(80,175,175),
	Color8(54,48,41),
	Color8(112,64,16),
	Color8(214,207,201),
	Color8(180,150,0),
	Color8(100,115,120),
	Color8(211,71,40),
	Color8(255,255,255),
	Color8(70,20,21),
	Color8(22,59,33),
	Color8(24,37,82),
	Color8(152,216,234),
	Color8(116,65,56),
	Color8(113,132,62)
]

const darkTone:Array[Color] = [
	Color8(156,96,35),
	Color8(187,174,164),
	Color8(156,96,35),
	Color8(96,54,137),
	Color8(72,13,13),
	Color8(27,80,40),
	Color8(58,70,101),
	Color8(175,58,117),
	Color8(53,117,117),
	Color8(24,21,18),
	Color8(56,32,7),
	Color8(187,174,164),
	Color8(220,110,0),
	Color8(60,75,80),
	Color8(122,49,23),
	Color8(255,255,255),
	Color8(46,12,12),
	Color8(10,43,20),
	Color8(16,24,51),
	Color8(94,189,204),
	Color8(86,42,37),
	Color8(78,92,39)
]

@onready var editor:Editor = get_node("/root/editor")
@onready var tiles:TileMapLayer = %tiles
@onready var editorCamera:Camera2D = %editorCamera
@onready var objects:Node = %objects

var objIdIter:int = 0 # for creating objects
var lockIdIter:int = 0 # for creating locks
var goldIndex:int = 0 # youve seen this before
var goldIndexFloat:float = 0
signal goldIndexChanged

var keys:Dictionary[int,KeyBulk] = {}
var doors:Dictionary[int,Door] = {}
var locks:Dictionary[int,Lock] = {}
var otherObjects:Dictionary[int,GameObject] = {}

var levelBounds:Rect2i = Rect2i(0,0,800,608):
	set(value):
		levelBounds = value
		editor.gameViewportCont.material.set_shader_material("gameSize",levelBounds.size)

const GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/glitchDrawMaterial.tres")
const PIXELATED_MATERIAL:ShaderMaterial = preload("res://resources/pixelatedDrawMaterial.tres")

const FKEYX:Font = preload("res://resources/fonts/fKeyX.tres")
const FTALK:Font = preload("res://resources/fonts/fTalk.fnt")

var levelStart:PlayerSpawn
var player:Player

func _process(delta:float) -> void:
	goldIndexFloat += delta*6 # 0.1 per frame, 60fps
	if goldIndexFloat > 12: goldIndexFloat -= 12
	if goldIndex != int(goldIndexFloat):
		goldIndex = int(goldIndexFloat)
		goldIndexChanged.emit()
	RenderingServer.global_shader_parameter_set(&"NOISE_OFFSET", Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000)))
	RenderingServer.global_shader_parameter_set(&"RCAMERA_ZOOM", 1/editorCamera.zoom.x)

func playtest(spawn:PlayerSpawn) -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.position = spawn.position + Vector2(17, 23)
