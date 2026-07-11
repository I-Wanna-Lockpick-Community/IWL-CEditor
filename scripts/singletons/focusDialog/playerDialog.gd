extends SubDialog
class_name PlayerDialog

var color:C.olors

func focus(focused:GameObject, new:bool, _dontRedirect:bool, skipInput:Control) -> void:
	%playerSpawnSettings.visible = focused is PlayerSpawn
	%playerStateSettings.visible = focused is PlayerPlaceholderObject or Game.levelStart != focused
	%playerStateColorSettings.visible = %playerStateSettings.visible
	%playerSettings.visible = focused is PlayerPlaceholderObject
	if new: setSelectedColor(C.olors.WHITE, skipInput)
	else: _playerColorSelected(color, skipInput)
	var undoPositions:int = focused.undoStack.reduce(func(accum, change): return accum + 1 if change[0] == GameChanges.TYPE.UndoSeparator else accum, -1)
	%playerUndostack.text = "%s positions in undo history" % undoPositions
	%playerUndostack.visible = undoPositions > 0
	if %playerSpawnSettings.visible:
		if Game.levelStart == focused: %levelStart.button_pressed = true
		else: %savestate.button_pressed = true
	if %playerStateSettings.visible:
		if !main.interacted: main.interact(%playerKeyCountEdit)

func setSelectedColor(toColor:C.olors, skipInput:Control=null) -> void:
	%playerColorSelector.setSelect(toColor)
	_playerColorSelected(toColor, skipInput)

func _playerColorSelected(_color:C.olors, skipInput:Control=null) -> void:
	color = _color
	if main.focused is PlayerPlaceholderObject:
		if skipInput != %playerKeyCountEdit: %playerKeyCountEdit.setValue(Game.player.key[color])
		if skipInput != %playerKeyGlistenEdit: %playerKeyGlistenEdit.setValue(Game.player.glisten[color])
		%playerStar.button_pressed = Game.player.star[color]
		%playerCurse.button_pressed = Game.player.curse[color]
	else:
		if skipInput != %playerKeyCountEdit: %playerKeyCountEdit.setValue(main.focused.key[color])
		if skipInput != %playerKeyGlistenEdit: %playerKeyGlistenEdit.setValue(main.focused.glisten[color])
		%playerStar.button_pressed = main.focused.star[color]
		%playerCurse.button_pressed = main.focused.curse[color]

func receiveKey(event:InputEvent) -> bool:
	if Editor.eventIs(event, &"focusPlayerStart") and %playerSpawnSettings.visible: _playTest()
	elif Editor.eventIs(event, &"focusPlayerStar") and %playerStateSettings.visible: _playerStarSet(!%playerStar.button_pressed)
	elif Editor.eventIs(event, &"focusPlayerCurse") and %playerStateSettings.visible and %playerCurse.visible: _playerCurseSet(!%playerCurse.button_pressed)
	elif Editor.eventIs(event, &"focusPlayerSavestate") and %playerSettings.visible: _leaveSavestate()
	elif Editor.eventIs(event, &"quicksetColor") and %playerStateSettings.visible: Game.editor.quickSet.startQuick(&"quicksetColor", main.focused)
	else: return false
	return true

func changedMods() -> void:
	%playerCurse.visible = Mods.active(&"CurseKeys")
	%playerKeyGlistenCont.visible = Mods.active(&"Glistening")

func _playerKeyCountSet(value:PackedInt64Array) -> void:
	if main.focused is PlayerPlaceholderObject:
		Game.player.key[color] = value
		Game.player.checkKeys()
	else: Changes.addChange(Changes.ArrayElementChange.new(main.focused,&"key",color,value,%playerKeyCountEdit))

func _playerStarSet(toggled_on:bool) -> void:
	if main.focused is PlayerPlaceholderObject:
		Game.player.star[color] = toggled_on
	else: Changes.addChange(Changes.ArrayElementChange.new(main.focused,&"star",color,toggled_on))

func _playerCurseSet(toggled_on:bool) -> void:
	if main.focused is PlayerPlaceholderObject:
		Game.player.curse[color] = toggled_on
		Game.player.checkKeys()
	else: Changes.addChange(Changes.ArrayElementChange.new(main.focused,&"curse",color,toggled_on))

func _playerKeyGlistenSet(value:PackedInt64Array):
	if main.focused is PlayerPlaceholderObject:
		Game.player.glisten[color] = value
	else: Changes.addChange(Changes.ArrayElementChange.new(main.focused,&"glisten",color,value,%playerKeyGlistenEdit))

func _playTest():
	if Game.playState != Game.PLAY_STATE.EDIT:
		await Game.stopTest()
	Game.playTest(main.focused)

func _setLevelStart():
	if main.focused is not PlayerSpawn: return
	if Game.levelStart:
		Game.levelStart.queue_redraw()
	Changes.addChange(Changes.GlobalObjectChange.new(Game,&"levelStart",main.focused))
	main.focused.resetColors()
	main.focused.queue_redraw()
	focus(main.focused, false, false, null)

func _setSavestate():
	if main.focused is not PlayerSpawn: return
	if Game.levelStart == main.focused:
		Changes.addChange(Changes.GlobalObjectChange.new(Game,&"levelStart",null))
		main.focused.queue_redraw()
	focus(main.focused, false, false, null)

func _leaveSavestate(): Game.savestate()
