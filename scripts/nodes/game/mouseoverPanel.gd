extends PanelContainer
class_name MouseoverPanel

const LOCK_TYPES = ["", "Blank ", "Blast ", "All ", "Exact ", "Glistening ", "Remainder "]

func describe(object:GameObject) -> void:
	var string:String = ""
	match object.get_script():
		KeyBulk:
			match object.collectType:
				Player.KEYCHANGE_TYPE.NONE: string += "Weak "
				Player.KEYCHANGE_TYPE.STAR: string += "Starry "
				Player.KEYCHANGE_TYPE.ALL: string += "Forceful "
			match object.type:
				KeyBulk.TYPE.EXACT: string += "Exact "
				KeyBulk.TYPE.STAR:
					match object.boolType:
						KeyBulk.BOOL_TYPE.ENABLE: string += "Star "
						KeyBulk.BOOL_TYPE.DISABLE: string += "Unstar "
						KeyBulk.BOOL_TYPE.TOGGLE: string += "Starflip "
				KeyBulk.TYPE.ROTOR:
					if M.eq(object.count, M.nONE()): string += "Signflip "
					elif M.eq(object.count, M.I()): string += "Rotor (i) "
					elif M.eq(object.count, M.nI()): string += "Rotor (-i) "
					if object.reciprocal: string += "Reciprocal "
				KeyBulk.TYPE.CURSE:
					match object.boolType:
						KeyBulk.BOOL_TYPE.ENABLE: string += "Curse "
						KeyBulk.BOOL_TYPE.DISABLE: string += "Uncurse "
						KeyBulk.BOOL_TYPE.TOGGLE: string += "Curseflip "
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
			if object.color == C.olors.GLITCH or object.altColor == C.olors.GLITCH: string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.color == C.olors.ERROR or object.altColor == C.olors.GLITCH: string += "\nMimic: " + Colors.getName(object.errorMimic)
			if object.glistening:
				string += "\n- Effects -\nGlistening!"
		Door:
			if object.type == Door.TYPE.SIMPLE:
				match object.locks[0].spendType:
					Lock.SPEND_TYPE.NONE: string += "Weak "
					Lock.SPEND_TYPE.STAR: string += "Starry "
					Lock.SPEND_TYPE.ALL: string += "Forceful "
				if object.oscillate: string += "Oscillating "
				string += LOCK_TYPES[object.locks[0].type] + Colors.getName(object.colorSpend) + " Door"
				var additional:String = lockAdditionalInfo(object.locks[0], object)
				if additional: string += " (Lock " + additional + ")"
				if object.armament: string += " (Spend Armament)"
				string += "\nCost: " + lockCost(object.locks[0])
				if object.locks[0].color != object.colorSpend: 
					if object.locks[0].type != Lock.TYPE.REMAINDER: # do NOT append the color to the end if its a remainder lock
						string += " " + Colors.getName(object.locks[0].color)
			else:
				if object.type == Door.TYPE.COMBO:
					string += Colors.getName(object.colorSpend)
					string += " Lockless Door" if len(object.locks) == 0 else " Combo Door"
				else: string += "Empty Gate" if len(object.locks) == 0 else "Gate"
				if object.armament: string += " (Spend Armament)"
				for lock in object.locks:
					string += "\nLock: " + LOCK_TYPES[lock.type] + Colors.getName(lock.color) + ", Cost: "
					match lock.spendType:
						Lock.SPEND_TYPE.NONE: string += "Weak "
						Lock.SPEND_TYPE.STAR: string += "Starry "
						Lock.SPEND_TYPE.ALL: string += "Forceful "
					string += lockCost(lock)
					var additional:String = lockAdditionalInfo(lock, object)
					if additional: string += " (" + additional + ")"
			if object.hasInitialColor(C.olors.GLITCH): string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.hasInitialColor(C.olors.ERROR): string += "\nMimic: " + Colors.getName(object.errorMimic)
			string += effects(object)
			
		RemoteLock:
			match object.spendType:
				Lock.SPEND_TYPE.NONE: string += "Weak "
				Lock.SPEND_TYPE.STAR: string += "Starry "
				Lock.SPEND_TYPE.ALL: string += "Forceful "
			string += LOCK_TYPES[object.type] + Colors.getName(object.color) + " Remote Lock\n"
			string += ("S" if object.satisfied else "Uns") + "atisfied, Cost: " + lockCost(object)
			if object.type == Lock.TYPE.GLISTENING: string += " Glistening"
			if object.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]: string += " (" + M.str(object.cost) + ")"
			if object.armament: string += " (Armament)"
			if object.color == C.olors.GLITCH: string += "\nMimic: " + Colors.getName(object.glitchMimic)
			elif object.color == C.olors.ERROR: string += "\nMimic: " + Colors.getName(object.errorMimic)
			string += effects(object)
		_: return
	%text.text = string
	size = Vector2.ZERO

func lockAdditionalInfo(lock:Lock, door:Door) -> String:
	var additional:Array[String] = []
	if lock.armament: additional.append("Armament")
	if Colors.getDef(door.colorSpend).isMimic and Colors.getDef(lock.color).isMimic and lock.getColor(Lock.COLOR_STEP.EFFECTIVE) != door.getColor(Door.COLOR_STEP.EFFECTIVE): additional.append("Mimic: " + Colors.getName(lock.getColor(Lock.COLOR_STEP.EFFECTIVE)))
	if additional: return ", ".join(additional)
	else: return ""

func lockCost(lock:GameComponent) -> String:
	var string:String = ""
	if lock.negated: string += "Not "
	match lock.type:
		Lock.TYPE.NORMAL: string += M.str(lock.count) if M.ex(lock.count) else "None"
		Lock.TYPE.BLANK: string += "None"
		Lock.TYPE.BLAST, Lock.TYPE.ALL:
			string += "["
			var numerator:PackedInt64Array = lock.count
			var divideThrough:bool = !M.isComplex(lock.denominator) and (!M.isComplex(numerator) or !lock.isPartial)
			if divideThrough: numerator = M.divide(numerator,M.saxis(lock.denominator))
			if M.neq(numerator, M.ONE()): string += M.str(numerator)
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
		if object.curseColor == C.olors.BROWN: string += "\nCursed!"
		else:
			string += "\nCursed " + Colors.getName(object.curseColor) + "!"
			if object.curseColor == C.olors.GLITCH: string += " (Mimic: " + Colors.getName(object.curseMimic) + ")"
			elif object.curseColor == C.olors.ERROR: string += " (Mimic: " + Colors.getName(object.curseMimic) + ")"
	if object.gameFrozen: string += "\nFrozen! (1xRed)"
	if object.gameCrumbled: string += "\nEroded! (5xGreen)"
	if object.gamePainted: string += "\nPainted! (3xBlue)"
	if object is Door:
		match object.starred:
			Door.STAR_STATE.STARRED_UNLOCKED: string += "\nStarred! (Unlocked,"
			Door.STAR_STATE.STARRED_LOCKED: string += "\nStarred! (Locked,"
		if object.starred != Door.STAR_STATE.UNSTARRED:
			string += "\nSpends " + M.str(object.starredSpendKey)
			if M.ex(object.starredSpendGlisten):
				string += "(" + M.str(object.starredSpendGlisten) + ")"
			if object.hasArmamentLocks(): string += " (+ Armament locks)"
			string += " " + Colors.getName(object.starredColor) + ")"
	if string: string = "\n- Effects -" + string
	return string
