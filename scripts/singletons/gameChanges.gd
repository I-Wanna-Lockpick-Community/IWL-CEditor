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
	saveBuffered = true

func addChange(change:Change) -> Change:
	undoStack.append(change)
	return change

func _process(_delta) -> void:
	if saveBuffered and game.player.is_on_floor():
		saveBuffered = false
		assert(undoStack[-1] is not UndoSeparator)
		undoStack.append(UndoSeparator.new(game.player.position))

func undo() -> bool:
	if len(undoStack) == 1: return false
	if undoStack[-1] is UndoSeparator: undoStack.pop_back()
	saveBuffered = false
	while true:
		if undoStack[-1] is UndoSeparator:
			game.player.position = undoStack[-1].position
			return true
		var change = undoStack.pop_back()
		change.undo()
	return true # unreachable

static func copy(value:Variant) -> Variant:
	if value is C || value is Q: return value.copy()
	else: return value

class Change extends RefCounted:
	var game:Game
	# is a singular recorded change
	# do() subsumed to _init()
	func undo() -> void: pass

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack; also saves the player's position at that point
	var position:Vector2

	func _init(_position:Vector2) -> void:
		position = _position

class KeyChange extends Change:
	# C major -> A minor, for example

	var color:Game.COLOR
	var before:C

	func _init(_game:Game, _color:Game.COLOR, after:C) -> void:
		game = _game
		color = _color
		before = GameChanges.copy(game.player.keys[color])
		game.player.keys[color] = GameChanges.copy(after)
	
	func undo() -> void: game.player.keys[color] = GameChanges.copy(before)

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
		component.propertyGameChanged(property)
		component.queue_redraw()
	
	func _to_string() -> String:
		return "<PropetyChange:"+str(id)+"."+str(before)+"->"+str(property)+">"
