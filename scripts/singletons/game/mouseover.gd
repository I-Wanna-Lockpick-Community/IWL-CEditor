extends PanelContainer
class_name Mouseover

const LOCK_TYPES = ["", "Blank ", "Blast ", "All ", "Exact ", "Starry ", "Remainder "]

func describe(object:GameObject, pos:Vector2, screenBottomRight:Vector2) -> void:
	if !object:
		visible = false
		return
	visible = true
	var string:String = ""
	match object.get_script():
		KeyBulk:
			match object.type:
				KeyBulk.TYPE.EXACT: string += "Exact "
				KeyBulk.TYPE.STAR: string += "Unstar " if object.un else "Star "
				KeyBulk.TYPE.ROTOR:
					if M.eq(object.count, M.nONE): string += "Signflip "
					elif M.eq(object.count, M.I): string += "Rotor (i) "
					elif M.eq(object.count, M.nI): string += "Rotor (-i) "
					if object.reciprocal: string += "Reciprocal "
				KeyBulk.TYPE.CURSE: string += "Uncurse " if object.un else "Curse "
				KeyBulk.TYPE.OPERATOR: string += "Operator "
			string += Colors.getName(object.color) + " Key"
			if object.type in [KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT]:
				string += "\nAmount: " + M.str(object.count)
			if object.type == KeyBulk.TYPE.OPERATOR:
				string += "\n"
				match object.operation:
					KeyBulk.OPERATION.SET: string += "Action: Set to "
					KeyBulk.OPERATION.ADD: string += "Action: Add "
					KeyBulk.OPERATION.SUBTRACT: string += "Action: Subtract "
					KeyBulk.OPERATION.MULTIPLY: string += "Action: Multiply by "
					KeyBulk.OPERATION.DIVIDE: string += "Action: Divide by "
					KeyBulk.OPERATION.MODULO: string += "Action: Modulo "
				string += Colors.getName(object.altColor)
			if object.color == Game.COLOR.GLITCH or object.altColor == Game.COLOR.GLITCH: string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.color == Game.COLOR.ERROR or object.altColor == Game.COLOR.GLITCH: string += "\nMimic: " + Colors.getName(object.errorMimic)
			if object.glistening:
				string += "\n- Effects -\nGlistening!"
		Door:
			if object.type == Door.TYPE.SIMPLE:
				string += LOCK_TYPES[object.locks[0].type] + Colors.getName(object.colorSpend) + " Door"
				if object.locks[0].armament:
					string += " (Armament"
					if object.locks[0].glitchMimic != object.glitchMimic: string += ", Mimic: " + Colors.getName(object.locks[0].glitchMimic)
					elif object.locks[0].errorMimic != object.errorMimic: string += ", Mimic: " + Colors.getName(object.locks[0].errorMimic)
					string += ")"
				string += "\nCost: " + lockCost(object.locks[0])
				if object.locks[0].color != object.colorSpend: 
					if object.locks[0] != Lock.TYPE.REMAINDER: # do NOT append the color to the end if its a remainder lock
						string += " " + Colors.getName(object.locks[0].color)
			else:
				if object.type == Door.TYPE.COMBO:
					string += Colors.getName(object.colorSpend)
					string += " Lockless Door" if len(object.locks) == 0 else " Combo Door"
				else: string += "Empty Gate" if len(object.locks) == 0 else "Gate"
				for lock in object.locks:
					string += "\nLock: " + LOCK_TYPES[lock.type] + Colors.getName(lock.color) + ", Cost: " + lockCost(lock)
					if lock.armament:
						string += " (Armament"
						if lock.color == Game.COLOR.GLITCH and lock.glitchMimic != object.glitchMimic: string += ", Mimic: " + Colors.getName(lock.glitchMimic)
						elif lock.color == Game.COLOR.ERROR and lock.errorMimic != object.errorMimic: string += ", Mimic: " + Colors.getName(lock.errorMimic)
						string += ")"
			if object.hasInitialColor(Game.COLOR.GLITCH): string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.hasInitialColor(Game.COLOR.ERROR): string += "\nMimic: " + Colors.getName(object.errorMimic)
			string += effects(object)
			
		RemoteLock:
			string += LOCK_TYPES[object.type] + Colors.getName(object.color) + " Remote Lock\n"
			string += ("S" if object.satisfied else "Uns") + "atisfied, Cost: " + M.str(object.cost)
			if object.type == Lock.TYPE.GLISTENING: string += " Glistening"
			if object.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]: string += " (" + lockCost(object) + ")"
			if object.armament: string += " (Armament)"
			if object.color == Game.COLOR.GLITCH: string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.color == Game.COLOR.ERROR: string += "\nMimic: " + Colors.getName(object.errorMimic)
			string += effects(object)
		_:
			visible = false
			return
	%text.text = string
	size = Vector2.ZERO
	position = pos
	if position.x + size.x > screenBottomRight.x: position.x -= size.x
	if position.y + size.y > screenBottomRight.y: position.y -= size.y

func lockCost(lock:GameComponent) -> String:
	var string:String = ""
	if lock.negated: string += "Not "
	match lock.type:
		Lock.TYPE.NORMAL: string += M.str(lock.count) if M.ex(lock.count) else "None"
		Lock.TYPE.BLANK: string += "None"
		Lock.TYPE.BLAST, Lock.TYPE.ALL:
			string += "["
			var numerator:PackedInt64Array = lock.count
			var divideThrough:bool = !M.isComplex(lock.denominator) and !M.isComplex(numerator)
			if divideThrough: numerator = M.divide(numerator,M.saxis(lock.denominator))
			if M.neq(numerator, M.ONE): string += M.str(numerator)
			string += "All" if lock.type == Lock.TYPE.BLAST else "ALL"
			if lock.type == Lock.TYPE.BLAST and divideThrough: string += (" -" if M.negative(M.sign(lock.denominator)) else " +") + ("i" if M.isNonzeroImag(lock.denominator) else "")
			if lock.isPartial:
				if divideThrough: string += "/" + M.str(M.divide(lock.denominator, M.saxis(lock.denominator)))
				else: string += " / " + M.str(lock.denominator)
			string += "]"
		Lock.TYPE.EXACT:
			string += "Exactly " + M.str(lock.count)
			if lock.zeroI: string += "i"
		Lock.TYPE.GLISTENING:
			string += M.str(lock.count) + " Glistening"
		Lock.TYPE.REMAINDER:
			string += Colors.getName(lock.color) + " % " + M.str(lock.count)
	return string

func effects(object:GameObject) -> String:
	var string:String = ""
	if object.cursed:
		if object.curseColor == Game.COLOR.BROWN: string += "\nCursed!"
		else:
			string += "\nCursed " + Colors.getName(object.curseColor) + "!"
			if object.curseColor == Game.COLOR.GLITCH: string += " (Mimic: " + Colors.getName(object.curseMimic) + ")"
			elif object.curseColor == Game.COLOR.ERROR: string += " (Mimic: " + Colors.getName(object.curseMimic) + ")"
	if object.gameFrozen: string += "\nFrozen! (1xRed)"
	if object.gameCrumbled: string += "\nEroded! (5xGreen)"
	if object.gamePainted: string += "\nPainted! (3xBlue)"
	match object.starred:
		Door.STAR_STATE.STARRED_UNLOCKED: string += "\nStarred! (Unlocked)"
		Door.STAR_STATE.STARRED_LOCKED: string += "\nStarred! (Locked)"
	if object.starred != Door.STAR_STATE.UNSTARRED:
		string += "\n    Spends " + M.str(object.starredSpendKey)
		if M.ex(object.starredSpendGlisten):
			string += "(" + M.str(object.starredSpendGlisten) + ")"
		if object.hasArmamentLocks(): string += " (+ Armament locks)"
		string += " " + Colors.getName(object.starredColor) + ")"
	if string: string = "\n- Effects -" + string
	return string
