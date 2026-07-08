class_name QuickSwitcher
extends Node2D

var timer:float = 2
var text:String
var lastToggle:bool = false
var pitch:float

var drawMain:RID
var drawGradient:RID

var gameSettings:GameSettings
var configFile:ConfigFile

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawGradient = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGradient, Game.TEXT_GRADIENT_MATERIAL)
	RenderingServer.canvas_item_set_parent(drawMain, get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGradient, get_canvas_item())

func toggleAutoRun() -> void:
	Game.autoRun = !Game.autoRun
	if Game.autoRun:
		text = "[%s] Auto-Run is on" % Explainer.hotkeyMap(&"gameAutoRun")
		pitch = 1.0
	else:
		text = "[%s] Auto-Run is off" % Explainer.hotkeyMap(&"gameAutoRun")
		pitch = 0.7
	lastToggle = Game.autoRun
	toggled_()

func toggleMixedFractions() -> void:
	Game.mixedFractions = !Game.mixedFractions
	if Game.mixedFractions:
		text = "[%s] Mixed Fractions is on" % Explainer.hotkeyMap(&"gameMixedFractionsSwitch")
		pitch = 0.9
	else:
		text = "[%s] Mixed Fractions is off" % Explainer.hotkeyMap(&"gameMixedFractionsSwitch")
		pitch = 0.6
	lastToggle = Game.mixedFractions
	toggled_()

func toggled_() -> void:
	AudioManager.play(preload("res://resources/sounds/autoRun.wav"), 1.0, pitch)
	timer = 0
	gameSettings.closed(configFile)
	configFile.save("user://config.ini")

func _process(delta:float) -> void:
	if timer < 2:
		timer += delta
		queue_redraw()
		if timer >= 2: timer = 2

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGradient)
	var alpha:float = abs(sin(timer*PI))
	if alpha > 0:
		TextDraw.outlinedGradient(Game.FMINIID,drawMain,drawGradient,text,
			Color(Color("#e6ffe6") if lastToggle else Color("#dcffe6"),alpha),
			Color(Color("#e6c896") if lastToggle else Color("#64dc8c"),alpha),
			Color(Color.BLACK,alpha),12,Vector2(4,20)
		)
