class_name BattleAi
extends RefCounted
## The CPU player: the next move of a side from what that side may see (its own hand, both boards, both heroes).
## It looks for lethal first, then plays the most expensive useful card, then attacks with each ready minion: it takes
## trades that kill without dying, removes big threats, and otherwise hits the enemy hero. A `face` side takes no trade
## but a big threat, and aims its damage spells at the enemy hero. Deterministic.

## The next move of `side`. End turn when nothing useful is left.
static func next_action(sim: BattleSim, side: int) -> BattleAction:
	if sim.over or sim.active != side:
		return BattleAction.end_turn()
	var lethal: BattleAction = _lethal(sim, side)
	if lethal != null:
		return lethal
	var play: BattleAction = _best_play(sim, side)
	if play != null:
		return play
	var hit: BattleAction = _best_attack(sim, side)
	if hit != null:
		return hit
	return BattleAction.end_turn()


## A move toward killing the enemy hero this turn: a direct damage card that finishes it, an attack on its hero when
## the ready attack is enough, or the removal of the guard in the way.
static func _lethal(sim: BattleSim, side: int) -> BattleAction:
	var enemy: int = sim.other(side)
	var enemy_side: BattleSide = sim.sides[enemy]
	var health: int = enemy_side.hero_health
	var own: BattleSide = sim.sides[side]
	for i: int in own.hand.size():
		var row: GameData.CardRow = BattleSim.card(own.hand[i])
		if sim.check_play(side, i) != BattleSim.PlayCheck.OK:
			continue
		if row.effect == GameData.CardEffect.DAMAGE_TARGET and row.amount >= health:
			return BattleAction.play(i, enemy, BattleSim.HERO)
		if row.effect == GameData.CardEffect.DAMAGE_ENEMY_HERO and row.trigger == GameData.CardTrigger.PLAY \
				and row.amount >= health:
			return BattleAction.play(i, BattleSim.NO_SIDE, BattleSim.HERO)
	var ready: int = sim.ready_attack(side)
	if ready < health:
		return null
	if not enemy_side.has_guard():
		for m: BattleMinion in own.board:
			if m.can_attack():
				return BattleAction.attack(m.uid, enemy, BattleSim.HERO)
		return null
	if enemy_side.board.size() != _guard_count(enemy_side):
		return null
	var guards_health: int = 0
	for m: BattleMinion in enemy_side.board:
		guards_health += m.health
	if ready < health + guards_health:
		return null
	return _attack_guard(sim, side)


static func _guard_count(s: BattleSide) -> int:
	var count: int = 0
	for m: BattleMinion in s.board:
		if m.guard:
			count += 1
	return count


## The most expensive playable card that does something useful now, with its target.
static func _best_play(sim: BattleSim, side: int) -> BattleAction:
	var own: BattleSide = sim.sides[side]
	var best: BattleAction = null
	var best_cost: int = -1
	var best_minion: bool = false
	for i: int in own.hand.size():
		if sim.check_play(side, i) != BattleSim.PlayCheck.OK:
			continue
		var action: BattleAction = _play_of(sim, side, i)
		if action == null:
			continue
		var row: GameData.CardRow = BattleSim.card(own.hand[i])
		var minion: bool = row.kind == GameData.CardKind.MINION
		if row.cost > best_cost or (row.cost == best_cost and minion and not best_minion):
			best_cost = row.cost
			best_minion = minion
			best = action
	return best


## How to play the hand card at `index` usefully, or `null` to keep it.
static func _play_of(sim: BattleSim, side: int, index: int) -> BattleAction:
	var own: BattleSide = sim.sides[side]
	var enemy: int = sim.other(side)
	var enemy_side: BattleSide = sim.sides[enemy]
	var row: GameData.CardRow = BattleSim.card(own.hand[index])
	if row.trigger != GameData.CardTrigger.PLAY or row.effect == GameData.CardEffect.NONE:
		return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO)
	match row.effect:
		GameData.CardEffect.DAMAGE_TARGET:
			if own.face and row.kind == GameData.CardKind.SPELL:
				return BattleAction.play(index, enemy, BattleSim.HERO)
			var target: BattleMinion = _best_kill(enemy_side, row.amount)
			if target != null:
				return BattleAction.play(index, enemy, target.uid)
			if row.kind == GameData.CardKind.SPELL and own.hand.size() > GameSetting.ai_draw_hand_limit():
				return BattleAction.play(index, enemy, BattleSim.HERO)
			return null
		GameData.CardEffect.DAMAGE_ALL_ENEMY_MINIONS:
			if row.kind == GameData.CardKind.MINION:
				return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO)
			return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO) \
				if _kills(enemy_side, row.amount) >= GameSetting.ai_area_kills() else null
		GameData.CardEffect.DRAW_CARDS:
			if row.kind == GameData.CardKind.MINION or own.hand.size() < GameSetting.ai_draw_hand_limit():
				return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO)
			return null
		GameData.CardEffect.BUFF_FRIENDLY_MINION:
			var strongest: BattleMinion = _strongest(own)
			return null if strongest == null else BattleAction.play(index, side, strongest.uid)
		GameData.CardEffect.BUFF_OTHER_FRIENDLY_ATTACK:
			return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO)
	return BattleAction.play(index, BattleSim.NO_SIDE, BattleSim.HERO)


## The enemy minion `damage` kills that is worth most (attack plus health), guards first. `null` if none dies.
static func _best_kill(enemy: BattleSide, damage: int) -> BattleMinion:
	var best: BattleMinion = null
	var best_value: int = -1
	for m: BattleMinion in enemy.board:
		if m.ward or m.health > damage:
			continue
		var value: int = m.attack + m.health + (1 if m.guard else 0)
		if value > best_value:
			best_value = value
			best = m
	return best


static func _kills(enemy: BattleSide, damage: int) -> int:
	var count: int = 0
	for m: BattleMinion in enemy.board:
		if not m.ward and m.health <= damage:
			count += 1
	return count


## The own minion with the most attack, the ones that can attack first, then the most health.
static func _strongest(own: BattleSide) -> BattleMinion:
	var best: BattleMinion = null
	for m: BattleMinion in own.board:
		if best == null or _stronger(m, best):
			best = m
	return best


static func _stronger(a: BattleMinion, b: BattleMinion) -> bool:
	if a.can_attack() != b.can_attack():
		return a.can_attack()
	if a.attack != b.attack:
		return a.attack > b.attack
	return a.health > b.health


## The next attack: on a guard when there is one, a good trade, a big threat, or the enemy hero.
static func _best_attack(sim: BattleSim, side: int) -> BattleAction:
	var own: BattleSide = sim.sides[side]
	var enemy: int = sim.other(side)
	var enemy_side: BattleSide = sim.sides[enemy]
	if enemy_side.has_guard():
		return _attack_guard(sim, side)
	for m: BattleMinion in own.board:
		if not m.can_attack():
			continue
		var trade: BattleMinion = _threat_for(m, enemy_side) if own.face else _trade_for(m, enemy_side)
		if trade != null:
			return BattleAction.attack(m.uid, enemy, trade.uid)
		return BattleAction.attack(m.uid, enemy, BattleSim.HERO)
	return null


## A target for `attacker`: an enemy it kills and survives, the most valuable one; else a threat it kills.
static func _trade_for(attacker: BattleMinion, enemy: BattleSide) -> BattleMinion:
	var best: BattleMinion = null
	var best_value: int = -1
	for target: BattleMinion in enemy.board:
		var kills: bool = not target.ward and target.health <= attacker.attack
		var survives: bool = attacker.ward or target.attack < attacker.health
		if not kills:
			continue
		var value: int = target.attack + target.health
		if survives and value > best_value:
			best_value = value
			best = target
	if best != null:
		return best
	return _threat_for(attacker, enemy)


## A big threat `attacker` kills, or `null`.
static func _threat_for(attacker: BattleMinion, enemy: BattleSide) -> BattleMinion:
	for target: BattleMinion in enemy.board:
		var kills: bool = not target.ward and target.health <= attacker.attack
		if kills and target.attack >= GameSetting.ai_threat_attack() and target.attack >= attacker.attack:
			return target
	return null


## An attack on an enemy guard: one the attacker kills, else the guard with the least health.
static func _attack_guard(sim: BattleSim, side: int) -> BattleAction:
	var own: BattleSide = sim.sides[side]
	var enemy: int = sim.other(side)
	var enemy_side: BattleSide = sim.sides[enemy]
	for m: BattleMinion in own.board:
		if not m.can_attack():
			continue
		var target: BattleMinion = null
		for g: BattleMinion in enemy_side.board:
			if not g.guard:
				continue
			if not g.ward and g.health <= m.attack:
				target = g
				break
			if target == null or g.health < target.health:
				target = g
		if target != null:
			return BattleAction.attack(m.uid, enemy, target.uid)
	return null
