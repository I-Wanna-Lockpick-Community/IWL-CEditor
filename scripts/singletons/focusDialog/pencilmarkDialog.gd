class_name PencilmarkDialog
extends SubDialog

func _process(_delta) -> void:
	%weirdButtons.visible = Game.playState == Game.PLAY_STATE.PLAY

func focus(focused:Pencilmark, _new:bool, _dontRedirect:bool, skipInput:Control) -> void:
	%pencilmarkColorSelector.setSelect(focused.color)
	%pencilmarkTypeSelector.setSelect(focused.type)
	%pencilmarkSymbolSelector.setSelect(focused.symbol)
	%pencilmarkSymbolSelector.visible = focused.type == Pencilmark.TYPE.SYMBOL
	%pencilmarkNumberEdit.visible = focused.type == Pencilmark.TYPE.NUMBER
	%pencilmarkTextEdit.visible = focused.type == Pencilmark.TYPE.TEXT
	if skipInput != %pencilmarkNumberEdit: %pencilmarkNumberEdit.setValue(focused.number)
	if skipInput != %pencilmarkTextEdit: %pencilmarkTextEdit.text = focused.text
	if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()

func receiveKey(event:InputEventKey) -> bool:
	if Editor.eventIs(event, &"quicksetPencilmarkColor"): Game.editor.quickSet.startQuick(&"quicksetPencilmarkColor", main.focused)
	elif Editor.eventIs(event, &"focusPencilmarkSymbol"): _pencilmarkTypeSelected(Pencilmark.TYPE.SYMBOL)
	elif Editor.eventIs(event, &"focusPencilmarkNumber"): _pencilmarkTypeSelected(Pencilmark.TYPE.NUMBER)
	elif Editor.eventIs(event, &"focusPencilmarkText"): _pencilmarkTypeSelected(Pencilmark.TYPE.TEXT)
	elif main.focused.type == Pencilmark.TYPE.SYMBOL:
		if Editor.eventIs(event, &"focusPencilmarkSymbolCheck"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.CHECK)
		elif Editor.eventIs(event, &"focusPencilmarkSymbolCross"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.CROSS)
		elif Editor.eventIs(event, &"focusPencilmarkSymbolCircle"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.CIRCLE)
		elif Editor.eventIs(event, &"focusPencilmarkSymbolSquare"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.SQUARE)
		elif Editor.eventIs(event, &"focusPencilmarkSymbolBang"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.BANG)
		elif Editor.eventIs(event, &"focusPencilmarkSymbolInterro"): _pencilmarkSymbolSelected(Pencilmark.SYMBOL.INTERRO)
		else: return false
	else: return false
	return true

func _pencilmarkColorSelected(color:C.olors) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"color",color))
	Changes.bufferSave()

func _pencilmarkTypeSelected(type:Pencilmark.TYPE) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	Changes.bufferSave()

func _pencilmarkSymbolSelected(symbol:Pencilmark.SYMBOL) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"symbol",symbol))
	Changes.bufferSave()

func _pencilmarkNumberSet(value:PackedInt64Array) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"number",value,%pencilmarkNumberEdit))
	Changes.bufferSave()

func _pencilmarkTextSet(value:String) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"text",value,%pencilmarkTextEdit))
	Changes.bufferSave()

func _done() -> void:
	AudioManager.play(preload("res://resources/sounds/sndSelectMade.wav"), 0.75, 1.2)
	AudioManager.play(preload("res://resources/sounds/sndConfirmMark.wav"), 0.75, 1)
	main.defocus()

func _erase() -> void:
	AudioManager.play(preload("res://resources/sounds/sndSelectMade.wav"), 0.75, 1.2)
	main.deleteFocused()
