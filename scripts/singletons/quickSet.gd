extends RichTextLabel
class_name QuickSet
# handles the blender-like keyboard input for setting properties
# we will call this a "quickset" or a "quick" because it sounds cool

@onready var editor:Editor = get_node("/root/editor")

var COLORS_ONELETTER:MatchSet = MatchSet.new(MATCH_RULE.EQUALS, [
									["X", Game.COLOR.MASTER],	["W", Game.COLOR.WHITE],	["O", Game.COLOR.ORANGE],	["P", Game.COLOR.PURPLE],	["R", Game.COLOR.RED],		["G", Game.COLOR.GREEN],	["B", Game.COLOR.BLUE],
	["I", Game.COLOR.PINK],			["Y", Game.COLOR.CYAN],		["K", Game.COLOR.BLACK],	["N", Game.COLOR.BROWN],	["U", Game.COLOR.PURE],		["L", Game.COLOR.GLITCH],	["S", Game.COLOR.STONE],	["D", Game.COLOR.DYNAMITE],
	["Q", Game.COLOR.QUICKSILVER],	["A", Game.COLOR.MAROON],	["F", Game.COLOR.FOREST],	["V", Game.COLOR.NAVY],		["C", Game.COLOR.ICE],		["M", Game.COLOR.MUD],		["T", Game.COLOR.GRAFFITI]
])
var COLORS_NAME:MatchSet = MatchSet.new(MATCH_RULE.FROM_START, [
	["MASTER", Game.COLOR.MASTER], ["GOLD", Game.COLOR.MASTER],
	["WHITE", Game.COLOR.WHITE],
	["ORANGE", Game.COLOR.ORANGE],
	["PURPLE", Game.COLOR.PURPLE],
	["RED", Game.COLOR.RED],
	["GREEN", Game.COLOR.GREEN],
	["BLUE", Game.COLOR.BLUE],
	["PINK", Game.COLOR.PINK],
	["CYAN", Game.COLOR.CYAN],
	["BLACK", Game.COLOR.BLACK],
	["BROWN", Game.COLOR.BROWN],
	["PURE", Game.COLOR.PURE],
	["GLITCH", Game.COLOR.GLITCH],
	["STONE", Game.COLOR.STONE],
	["DYNAMITE", Game.COLOR.DYNAMITE], ["EXPLOSION", Game.COLOR.DYNAMITE],
	["QUICKSILVER", Game.COLOR.QUICKSILVER], ["SILVER", Game.COLOR.QUICKSILVER],
	["MAROON", Game.COLOR.MAROON],
	["FOREST", Game.COLOR.FOREST],
	["NAVY", Game.COLOR.NAVY],
	["ICE", Game.COLOR.ICE],
	["MUD", Game.COLOR.MUD],
	["GRAFFITI", Game.COLOR.GRAFFITI], ["INK", Game.COLOR.GRAFFITI],
])

enum QUICK {NONE, COLOR}
enum MATCH_RULE {EQUALS, FROM_START}

const INPUT_CHAR_LIMIT = 12 # that should be enough characters for whatever; increase if necessary

var quick:QUICK = QUICK.NONE
var component:GameComponent # the component whose properties that we are setting

var input:String
var matched:int = -1
var matchComment:String = ""
var completeMatch:String = "" # if this is a partial match, display the complete name

func updateText() -> void:
	var string:String = ""
	if quick  == QUICK.NONE: text = ""; return
	match quick:
		QUICK.COLOR:
			if component is Door and (component.type == Door.TYPE.COMBO or !editor.focusDialog.colorLink.button_pressed): string += "SPEND COLOR: "
			elif component is Lock and (component.parent.type == Door.TYPE.COMBO or !editor.focusDialog.colorLink.button_pressed): string += "LOCK COLOR: "
			else: string += "COLOR: "
	if completeMatch:
		string += input
		string += "[color=#999999]" + completeMatch.right(completeMatch.length()-input.length()).rpad(INPUT_CHAR_LIMIT-input.length()) + "[/color]"
	else:
		string += input.rpad(INPUT_CHAR_LIMIT)
	if matched != -1:
		string += " // " + Game.COLOR.keys()[matched] + " " + matchComment
	text = string

func startQuick(_quick:QUICK, _component:GameComponent) -> void:
	quick = _quick
	component = _component
	matched = -1
	input = ""
	updateText()

func cancel() -> void:
	quick = QUICK.NONE
	text = ""

func evaluateQuick() -> void:
	matched = -1
	matchComment = ""
	completeMatch = ""
	match quick:
		QUICK.COLOR:
			if matchesId(Game.COLORS): matched = input.to_int(); matchComment = "(id)"
			elif COLORS_ONELETTER.check(input): matched = COLORS_ONELETTER.result; matchComment = "(abbreviation)"
			elif COLORS_NAME.check(input): matched = COLORS_NAME.result; matchComment = "(name)"; completeMatch = COLORS_NAME.completeMatch

func receiveKey(event:InputEventKey) -> void:
	if event.keycode >= 32 and event.keycode < 128:
		input += char(event.unicode).to_upper()
		input = input.right(INPUT_CHAR_LIMIT)
	else:
		match event.keycode:
			KEY_BACKSPACE:
				if Input.is_key_pressed(KEY_CTRL): input = ""
				input = input.left(input.length()-1)
			KEY_TAB, KEY_ENTER:
				if matched != -1: apply()
				quick = QUICK.NONE
			KEY_ESCAPE: quick = QUICK.NONE
	evaluateQuick()
	updateText()

func apply() -> void:
	match quick:
		QUICK.COLOR:
			if component is KeyBulk: editor.focusDialog._keyColorSelected(matched)
			if component is Door or component is Lock: editor.focusDialog._doorColorSelected(matched)

func matchesId(values:int) -> bool: return input.is_valid_int() and input.to_int() >= 0 and input.to_int() < values

class MatchSet extends RefCounted:
	var rule:MATCH_RULE
	var matches:Array[Array]

	var completeMatch:String
	var result:int

	func _init(_rule:MATCH_RULE, _matches:Array[Array]) -> void:
		rule = _rule
		matches = _matches

	func check(string:String) -> bool: # checks if the string matches this set; puts the match in result
		for match in matches:
			match rule:
				MATCH_RULE.EQUALS:
					if match[0] == string.to_upper():
						result = match[1]
						return true
				MATCH_RULE.FROM_START:
					if match[0].find(string.to_upper()) == 0:
						completeMatch = match[0]
						result = match[1]
						return true
		return false
