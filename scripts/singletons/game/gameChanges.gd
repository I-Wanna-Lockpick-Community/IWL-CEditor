extends Node
class_name GameChanges

var game:Game

var undoStack:Array[RefCounted] = []
var saveBuffered:bool = false

# handles the undo system for the game
# a lot is copied over from changes

func start() -> void:
	undoStack = []
	undoStack.append(UndoSeparator.new(game.player.position))

func bufferSave() -> void:
	await get_tree().process_frame # maybe race condition? it seems to be able to get stuck sometimes with keys
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	undoStack.append(change)
	return change

func _process(_delta) -> void:
	if saveBuffered and game.player.is_on_floor() and !game.player.nearDoor:
		saveBuffered = false
		if undoStack[-1] is not UndoSeparator: # could happen if something buffers save on the frame before a reset
			undoStack.append(UndoSeparator.new(game.player.position))

func undo() -> bool:
	if len(undoStack) == 1: return false
	if undoStack[-1] is UndoSeparator: undoStack.pop_back()
	saveBuffered = false
	game.player.pauseFrame = true
	while true:
		if undoStack[-1] is UndoSeparator:
			game.player.position = undoStack[-1].position
			game.player.dropMaster()
			for object in game.objects.values(): if object is Door and object.type == Door.TYPE.GATE: object.gateBufferCheck = null
			game.player.checkKeys()
			return true
		var change = undoStack.pop_back()
		change.undo()
	return true # unreachable

static func copy(value:Variant) -> Variant:
	if value is C || value is Q: return value.copy()
	else: return value

class Change extends RefCounted:
	var game:Game
	var cancelled:bool = false
	# is a singular recorded change
	# do() subsumed to _init()
	func undo() -> void: pass

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack; also saves the player's position at that point
	var position:Vector2

	func _init(_position:Vector2) -> void:
		position = _position

class ColorChange extends Change:
	# a change to something in an array of player indexed by colors
	# like key and star
	static func array() -> StringName: return &""

	var color:Game.COLOR
	var before:Variant

	func _init(_game:Game, _color:Game.COLOR, after:Variant) -> void:
		game = _game
		color = _color
		before = GameChanges.copy(game.player.get(array())[color])
		if before == after:
			cancelled = true
			return
		game.player.get(array())[color] = GameChanges.copy(after)
		game.player.checkKeys()
	
	func undo() -> void: game.player.get(array())[color] = GameChanges.copy(before)

class KeyChange extends ColorChange:
	# C major -> A minor, for example
	static func array() -> StringName: return &"key"

	func _init(_game:Game, _color:Game.COLOR, after:Variant) -> void:
		if _game.player.star[_color]:
			cancelled = true
			return
		super(_game,_color,after)
		for object in game.objects.values(): if object is Door and object.type == Door.TYPE.GATE: object.gateCheck(game.player)

class StarChange extends ColorChange:
	# a change to the starred state
	static func array() -> StringName: return &"star"

class CurseChange extends ColorChange:
	# a change to the starred state
	static func array() -> StringName: return &"curse"


class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var type:GDScript
	
	func _init(_game:Game,component:GameComponent,_property:StringName,after:Variant) -> void:
		game = _game
		id = component.id
		property = _property
		before = Changes.copy(component.get(property))
		if before == after:
			cancelled = true
			return
		type = component.get_script()
		assert(before != after)
		changeValue(Changes.copy(after))

	func undo() -> void: changeValue(Changes.copy(before))
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		match type:
			Lock: component = game.components[id]
			_: component = game.objects[id]
		component.set(property, value)
		component.propertyGameChangedDo(property)
		component.queue_redraw()
		if component is Door:
			for lock in component.locks: lock.queue_redraw()
	
	func _to_string() -> String:
		return "<PropetyChange:"+str(id)+"."+str(before)+"->"+str(property)+">"
