extends Node2D
class_name PDA

const PDA_BACKING:Texture2D = preload("res://assets/game/gameUI/PDA.png")

const JOKES:Array[String] = [
	"Why was 6 afraid of 7? Because 7 mod 2 = 1, and that usually means the puzzle is gonna have Blank Doors.",
	"A key a day keeps the doors away! Specifically, bipedal doors which don't want to be opened.",
	"P.D.A., in this case, stands for 'Personal Digital Assistant.' Do not be led astray into thinking it stands for 'Personal Dersonal Arsenal.'",
	"Remember to keep your eyes on the invariants! If you don't, then mathematicians can't write a paper about the puzzles you're solving!",
	"This PDA serves two functions: Keeping your key counts within an arm's distance, and pestering you with lukewarm comedy. We hope you enjoy it!",
	"The PDA was made as a collaborative effort between Kina, the God of Keys, and Spindles, the God of Precision. Be sure to give them your regards.",
	"Do not enter hub doors if you are sensitive to constant spatial confusion, or your hippocampus has been replaced with wood.",
	"99 Green Rotor Keys on the wall, 99 Green Rotor Keys, Take one down, pass it around, 99i Green Rotor Keys on the wall!",
	"The heating effects of Red Keys are for use in these puzzles only. Do not take one home and use it as a heating pad.",
	"Imaginary Keys are not, in fact, a figment of your imagination. The proverbial 'Key to the Puzzle', though, *is* an abstraction, and any indication otherwise should be ignored.",
	"Unfortunately, Skeleton Keys will not be encountered on your journey, as we could not source the necessary skeleton parts. At least, not legally.",
	"If you wait long enough at Mooncloud Lake, the time of day will change. You might not have known that if you solve puzzles about as fast as a bomb decimates the sound barrier.",
	"Because of their special time properties, you can't bring any keys or doors outside this place. You'll have to settle for a replica, if you can even find one.",
	"The reason Combo Doors make the sound of a camera shutter is because they want to remember the occasion. Who wouldn't?",
	"In the grand scheme of things, carrying around 50,000 keys is a rather trivial task. It's only five digits you have to worry about!"
]

var jokeIndex:int = 0
var colors:Array[C.olors]
var page:int = 0
var pages:int = 1
var screenSize:Vector2

var drawMain:RID
var drawGlitch:RID

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain, %draw.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch, %draw.get_canvas_item())
	reset()

func changedMods() -> void:
	colors = Mods.pdaColors()
	pages = ceil(len(colors)/14.0)

func _process(_delta) -> void:
	queue_redraw()

func reset() -> void:
	page = 0
	jokeIndex = randi_range(0, len(JOKES)-1)

func open() -> void:
	if visible: return
	AudioManager.play(preload("res://resources/sounds/sndDrop.wav"), 0.7, 1.5)
	visible = true

func close() -> void:
	if !visible: return
	AudioManager.play(preload("res://resources/sounds/sndDrop.wav"), 0.7, 1)
	visible = false

func nextPage() -> void:
	if pages == 1: return
	page = (page + 1) % pages
	AudioManager.play(preload("res://resources/sounds/sndDrop.wav"), 0.7, 1.5)

func _draw() -> void:
	var rect:Rect2 = Rect2((screenSize-Vector2(400,544))/2,Vector2(400,544))
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_add_rect(drawMain, Rect2(Vector2.ZERO, screenSize), Color(Color.BLACK, 0.5))
	RenderingServer.canvas_item_add_texture_rect(drawMain,rect,PDA_BACKING)
	RenderingServer.canvas_item_add_line(drawMain, rect.position+Vector2(21,349), rect.position+Vector2(365,349), Color.GREEN)
	%jokes.position = rect.position+Vector2(20,366)
	%jokes.text = "Door Facts: " + JOKES[jokeIndex]
	for x in 2:
		for y in 7:
			var index:int = page*14 + x*7 + y
			if index >= len(colors): continue
			if colors[index] == C.olors.NONE: continue
			var drawPosition:Vector2 = rect.position+Vector2(20+184*x,20+48*y)
			KeyBulk.drawKey(drawGlitch, drawMain, drawPosition, colors[index])
			Game.FPDA.draw_string(drawMain, drawPosition+Vector2(36, 25), "x"+M.str(Game.player.key[colors[index]]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GREEN)
			if y != 6: RenderingServer.canvas_item_add_line(drawMain, drawPosition+Vector2(-1,41), drawPosition+Vector2(161,41), Color.GREEN)
	if pages > 1:
		for pageI in pages:
			RenderingServer.canvas_item_add_circle(drawMain, rect.position+Vector2(206+pageI*12-pages*6,471), 3, Color.GREEN if page == pageI else Color("#007200"))
		Game.FTALKSMALL.draw_string(drawMain, rect.position+Vector2(204+pages*6,480), "[%s]"% InputMap.action_get_events(&"gameAction")[0].as_text_physical_keycode(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.GREEN)
