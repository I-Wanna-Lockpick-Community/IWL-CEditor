extends Node2D
class_name Game

enum KEY {NORMAL, EXACT, ORDINAL, STAR, UNSTAR, SIGNFLIP, POSROTOR, NEGROTOR, CURSE, UNCURSE}
enum LOCK {NORMAL, BLANK, BLAST, ALL, EXACT}

enum COLOR {MASTER, WHITE, ORANGE, PURPLE, RED, GREEN, BLUE, PINK, CYAN, BLACK, BROWN, PURE, GLITCH, STONE, DYNAMITE, SILVER, MAROON, FOREST, NAVY, ICE, MUD, GRAFFITI}

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

var keys:Dictionary[int,oKey] = {}

var gameBounds:Rect2i = Rect2i(0,0,800,608):
	set(value):
		gameBounds = value
		editor.gameViewportCont.material.set_shader_material("gameSize",gameBounds.size)
