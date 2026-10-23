class_name BattleSim
extends RefCounted
## The rules of one battle between the player and a CPU opponent. The player always goes first. Every change appends a
## `BattleEvent`; the view plays them in order. Integer only and its one random only shuffles the decks, so the same
## loadout and moves give the same battle.

enum PlayCheck { OK, NOT_YOUR_TURN, NO_MANA, BOARD_FULL, NO_TARGET, OVER }

const PLAYER: int = 0
const CPU: int = 1
const NO_SIDE: int = -1
## Target uid of a hero.
const HERO: int = 0

var sides: Array[BattleSide] = []
## The side whose turn it is.
var active: int = PLAYER
## Turns started so far, both sides counted. The player's first turn is 1.
var turn: int = 0
var over: bool = false
## The winner once `over`: `PLAYER`, `CPU`, or `NO_SIDE` when both heroes fell or the turn limit was reached.
var winner: int = NO_SIDE
var conceded: bool = false
## Cards the player played.
var cards_played: int = 0
var events: Array[BattleEvent] = []

var _random: UtilRandom = null
var _next_uid: int = 1
var _max_mana: int = 0
var _board_size: int = 0
var _hand_size: int = 0
var _max_turns: int = 0


## A battle from the decks (card ID values, one per copy), the hero health of each side and the seed. Call `start`.
func _init(player_deck: PackedInt32Array, cpu_deck: PackedInt32Array, player_health: int, cpu_health: int, seed_value: int) -> void:
	_random = UtilCore.create_random(UtilCore.make_purpose_seed("play_session_simulation", seed_value))
	_max_mana = GameSetting.max_mana()
	_board_size = GameSetting.board_size()
	_hand_size = GameSetting.hand_size()
	_max_turns = GameSetting.max_turns()
	sides.append(_new_side(player_deck, player_health))
	sides.append(_new_side(cpu_deck, cpu_health))


## Shuffles both decks, deals the opening hands and starts the player's first turn. The opening hands make no events.
func start() -> void:
	for side: BattleSide in sides:
		side.deck = _shuffled(side.deck)
	_deal_opening(sides[PLAYER], GameSetting.start_hand_first())
	_deal_opening(sides[CPU], GameSetting.start_hand_second())
	events.clear()
	_start_turn(PLAYER)


func other(side: int) -> int:
	return CPU if side == PLAYER else PLAYER


## Takes the events since the last call, oldest first.
func take_events() -> Array[BattleEvent]:
	var out: Array[BattleEvent] = events
	events = []
	return out


static func card(card_id: int) -> GameData.CardRow:
	return GameData.CardTable.get_row(card_id)


static func is_minion(card_id: int) -> bool:
	return card(card_id).kind == GameData.CardKind.MINION


## Whether playing `card_id` needs a chosen target.
static func needs_target(card_id: int) -> bool:
	var row: GameData.CardRow = card(card_id)
	if row.trigger != GameData.CardTrigger.PLAY:
		return false
	return row.effect == GameData.CardEffect.DAMAGE_TARGET or row.effect == GameData.CardEffect.BUFF_FRIENDLY_MINION


## Why `side` can or cannot play its hand card at `hand_index` now.
func check_play(side: int, hand_index: int) -> PlayCheck:
	if over:
		return PlayCheck.OVER
	if side != active:
		return PlayCheck.NOT_YOUR_TURN
	var s: BattleSide = sides[side]
	if hand_index < 0 or hand_index >= s.hand.size():
		return PlayCheck.NO_TARGET
	var card_id: int = s.hand[hand_index]
	var row: GameData.CardRow = card(card_id)
	if row.cost > s.mana:
		return PlayCheck.NO_MANA
	if row.kind == GameData.CardKind.MINION and s.board.size() >= _board_size:
		return PlayCheck.BOARD_FULL
	if needs_target(card_id) and not has_play_target(side, card_id):
		return PlayCheck.NO_TARGET
	return PlayCheck.OK


func has_play_target(side: int, card_id: int) -> bool:
	for target_side: int in 2:
		if is_play_target(side, card_id, target_side, HERO):
			return true
		for m: BattleMinion in sides[target_side].board:
			if is_play_target(side, card_id, target_side, m.uid):
				return true
	return false


## Whether `card_id` of `side` may target the character `target_uid` (0 for the hero) of `target_side`.
func is_play_target(side: int, card_id: int, target_side: int, target_uid: int) -> bool:
	if target_side != PLAYER and target_side != CPU:
		return false
	if target_uid != HERO and sides[target_side].index_of(target_uid) < 0:
		return false
	var row: GameData.CardRow = card(card_id)
	match row.effect:
		GameData.CardEffect.DAMAGE_TARGET:
			return true
		GameData.CardEffect.BUFF_FRIENDLY_MINION:
			return target_side == side and target_uid != HERO
	return false


## Plays the hand card at `hand_index` of `side` on the target (`target_side` -1 for none). False when not allowed.
func play_card(side: int, hand_index: int, target_side: int, target_uid: int) -> bool:
	if check_play(side, hand_index) != PlayCheck.OK:
		return false
	var s: BattleSide = sides[side]
	var card_id: int = s.hand[hand_index]
	var targeted: bool = needs_target(card_id)
	if targeted and not is_play_target(side, card_id, target_side, target_uid):
		return false
	if not targeted:
		target_side = NO_SIDE
		target_uid = HERO
	var row: GameData.CardRow = card(card_id)
	s.mana -= row.cost
	s.hand.remove_at(hand_index)
	if side == PLAYER:
		cards_played += 1
	var played: BattleEvent = _event(BattleEvent.Kind.PLAY_CARD, side)
	played.card_id = card_id
	played.index = hand_index
	played.target_side = target_side
	played.target_uid = target_uid
	var minion_uid: int = HERO
	if row.kind == GameData.CardKind.MINION:
		minion_uid = _summon(side, card_id)
	if row.trigger == GameData.CardTrigger.PLAY:
		_apply_effect(side, row, minion_uid, target_side, target_uid)
	_resolve()
	return true


## Whether the minion `uid` of `side` may attack now.
func can_attack(side: int, uid: int) -> bool:
	if over or side != active:
		return false
	var m: BattleMinion = sides[side].minion(uid)
	return m != null and m.can_attack()


## Whether the minion `attacker_uid` of `side` may attack the enemy character `target_uid` (0 for the hero). An enemy
## guard minion must be attacked first.
func is_attack_target(side: int, attacker_uid: int, target_side: int, target_uid: int) -> bool:
	if not can_attack(side, attacker_uid) or target_side != other(side):
		return false
	var enemy: BattleSide = sides[target_side]
	if target_uid == HERO:
		return not enemy.has_guard()
	var target: BattleMinion = enemy.minion(target_uid)
	if target == null:
		return false
	return target.guard or not enemy.has_guard()


func attack(side: int, attacker_uid: int, target_side: int, target_uid: int) -> bool:
	if not is_attack_target(side, attacker_uid, target_side, target_uid):
		return false
	var attacker: BattleMinion = sides[side].minion(attacker_uid)
	attacker.attacks_left -= 1
	var hit: BattleEvent = _event(BattleEvent.Kind.ATTACK, side)
	hit.uid = attacker_uid
	hit.card_id = attacker.card_id
	hit.target_side = target_side
	hit.target_uid = target_uid
	var strike: int = attacker.attack
	var back: int = 0
	if target_uid != HERO:
		back = sides[target_side].minion(target_uid).attack
	_damage(target_side, target_uid, strike)
	if back > 0:
		_damage(side, attacker_uid, back)
	_resolve()
	return true


func end_turn() -> void:
	if over:
		return
	_start_turn(other(active))


## `side` gives up: the other side wins.
func concede(side: int) -> void:
	if over:
		return
	conceded = side == PLAYER
	_finish(other(side))


## The attack of every minion of `side` that can attack now.
func ready_attack(side: int) -> int:
	var total: int = 0
	for m: BattleMinion in sides[side].board:
		if m.can_attack():
			total += m.attack
	return total


func _new_side(deck: PackedInt32Array, health: int) -> BattleSide:
	var s: BattleSide = BattleSide.new()
	s.deck = deck.duplicate()
	s.hero_health = health
	s.hero_max_health = health
	return s


func _shuffled(deck: PackedInt32Array) -> PackedInt32Array:
	var order: PackedInt64Array = UtilCore.shuffle_indices(_random, deck.size())
	var out: PackedInt32Array = PackedInt32Array()
	for i: int in order:
		out.push_back(deck[i])
	return out


## Draws `count` cards, then makes sure of a move on each of the first two turns. When none of the cards is a minion
## that costs at most `[opening_cheap_cost]`, the first such minion of the deck comes in; a deck without one brings in
## its first card of that cost instead, unless the hand already has one. Then, when the hand has fewer than two minions
## that cost at most `[opening_curve_cost]`, the first such minion of the deck comes in too. A card that comes in takes
## the place of the most expensive hand card these rules do not keep, which goes to the bottom of the deck.
func _deal_opening(s: BattleSide, count: int) -> void:
	for i: int in mini(count, s.deck.size()):
		s.hand.push_back(s.deck[0])
		s.deck.remove_at(0)
	var cheap: int = GameSetting.opening_cheap_cost()
	if not _has_cheap(s.hand, cheap, true) and not _swap_cheap(s, cheap, true):
		if not _has_cheap(s.hand, cheap, false):
			_swap_cheap(s, cheap, false)
	if _cheap_minions(s.hand, GameSetting.opening_curve_cost()) < 2:
		_swap_cheap(s, GameSetting.opening_curve_cost(), true)


## Whether `cards` has a card (a minion when `minion_only`) that costs at most `cheap`.
func _has_cheap(cards: PackedInt32Array, cheap: int, minion_only: bool) -> bool:
	for card_id: int in cards:
		if card(card_id).cost <= cheap and (not minion_only or is_minion(card_id)):
			return true
	return false


func _cheap_minions(cards: PackedInt32Array, cheap: int) -> int:
	var count: int = 0
	for card_id: int in cards:
		if is_minion(card_id) and card(card_id).cost <= cheap:
			count += 1
	return count


## Puts the first deck card (a minion when `minion_only`) that costs at most `cheap` in place of the hand card
## `_swap_out_index` picks, which goes to the bottom of the deck. False when the deck has none or no hand card may go.
func _swap_cheap(s: BattleSide, cheap: int, minion_only: bool) -> bool:
	var out: int = _swap_out_index(s.hand, true)
	if out < 0:
		out = _swap_out_index(s.hand, false)
	if out < 0:
		return false
	for i: int in s.deck.size():
		var card_id: int = s.deck[i]
		if card(card_id).cost <= cheap and (not minion_only or is_minion(card_id)):
			var swapped: int = s.hand[out]
			s.hand[out] = card_id
			s.deck.remove_at(i)
			s.deck.push_back(swapped)
			return true
	return false


## The most expensive hand card the opening may give back (the first one of that cost): not a card of at most
## `[opening_cheap_cost]` and, when `keep_curve`, not a minion of at most `[opening_curve_cost]`. -1 when none may go.
func _swap_out_index(hand: PackedInt32Array, keep_curve: bool) -> int:
	var cheap: int = GameSetting.opening_cheap_cost()
	var curve: int = GameSetting.opening_curve_cost()
	var out: int = -1
	var out_cost: int = -1
	for i: int in hand.size():
		var row: GameData.CardRow = card(hand[i])
		if row.cost <= cheap or (keep_curve and row.kind == GameData.CardKind.MINION and row.cost <= curve):
			continue
		if row.cost > out_cost:
			out_cost = row.cost
			out = i
	return out


func _start_turn(side: int) -> void:
	active = side
	turn += 1
	if turn > _max_turns:
		_finish(NO_SIDE)
		return
	var s: BattleSide = sides[side]
	s.max_mana = mini(s.max_mana + 1, _max_mana)
	s.mana = s.max_mana
	for m: BattleMinion in s.board:
		m.sleeping = false
		m.attacks_left = 1
	var started: BattleEvent = _event(BattleEvent.Kind.TURN_START, side)
	started.value = turn
	started.value2 = s.max_mana
	_draw(side)
	_resolve()


func _draw(side: int) -> void:
	var s: BattleSide = sides[side]
	if s.deck.is_empty():
		s.fatigue += 1
		var tired: BattleEvent = _event(BattleEvent.Kind.FATIGUE, side)
		tired.amount = s.fatigue
		_damage(side, HERO, s.fatigue)
		return
	var card_id: int = s.deck[0]
	s.deck.remove_at(0)
	if s.hand.size() >= _hand_size:
		var burned: BattleEvent = _event(BattleEvent.Kind.BURN, side)
		burned.card_id = card_id
		return
	s.hand.push_back(card_id)
	var drew: BattleEvent = _event(BattleEvent.Kind.DRAW, side)
	drew.card_id = card_id
	drew.index = s.hand.size() - 1


func _summon(side: int, card_id: int) -> int:
	var row: GameData.CardRow = card(card_id)
	var m: BattleMinion = BattleMinion.new()
	m.uid = _next_uid
	_next_uid += 1
	m.card_id = card_id
	m.attack = row.attack
	m.health = row.health
	m.max_health = row.health
	m.guard = row.guard
	m.ward = row.ward
	m.sleeping = not row.charge
	m.attacks_left = 1 if row.charge else 0
	var s: BattleSide = sides[side]
	s.board.append(m)
	var summoned: BattleEvent = _event(BattleEvent.Kind.SUMMON, side)
	summoned.uid = m.uid
	summoned.card_id = card_id
	summoned.index = s.board.size() - 1
	summoned.value = m.attack
	summoned.value2 = m.health
	return m.uid


## The effect of `row` played or dying on `side`. `source_uid` is the minion of the card, or 0 for a spell.
func _apply_effect(side: int, row: GameData.CardRow, source_uid: int, target_side: int, target_uid: int) -> void:
	var enemy: int = other(side)
	match row.effect:
		GameData.CardEffect.DAMAGE_TARGET:
			_damage(target_side, target_uid, row.amount)
		GameData.CardEffect.DAMAGE_ENEMY_HERO:
			_damage(enemy, HERO, row.amount)
		GameData.CardEffect.DAMAGE_ALL_ENEMY_MINIONS:
			var uids: PackedInt32Array = PackedInt32Array()
			for m: BattleMinion in sides[enemy].board:
				uids.push_back(m.uid)
			for uid: int in uids:
				_damage(enemy, uid, row.amount)
		GameData.CardEffect.HEAL_OWN_HERO:
			_heal_hero(side, row.amount)
		GameData.CardEffect.DRAW_CARDS:
			for i: int in row.amount:
				_draw(side)
		GameData.CardEffect.BUFF_FRIENDLY_MINION:
			_buff(side, target_uid, row.amount, row.amount2)
		GameData.CardEffect.BUFF_OTHER_FRIENDLY_ATTACK:
			for m: BattleMinion in sides[side].board:
				if m.uid != source_uid:
					_buff(side, m.uid, row.amount, 0)


func _damage(side: int, uid: int, amount: int) -> void:
	if amount <= 0:
		return
	var s: BattleSide = sides[side]
	if uid == HERO:
		s.hero_health = maxi(s.hero_health - amount, 0)
		var hurt: BattleEvent = _event(BattleEvent.Kind.DAMAGE, side)
		hurt.amount = amount
		hurt.value = s.hero_health
		return
	var m: BattleMinion = s.minion(uid)
	if m == null or m.health <= 0:
		return
	if m.ward:
		m.ward = false
		var broke: BattleEvent = _event(BattleEvent.Kind.WARD_BREAK, side)
		broke.uid = uid
		return
	m.health -= amount
	var hit: BattleEvent = _event(BattleEvent.Kind.DAMAGE, side)
	hit.uid = uid
	hit.amount = amount
	hit.value = m.health


## Heals the hero of `side` up to its max health. A heal at full health still makes a `HEAL` event of 0, so the view
## can show that the health was already full; the event keeps the asked healing, so the view can show a cut heal.
func _heal_hero(side: int, amount: int) -> void:
	var s: BattleSide = sides[side]
	var healed: int = maxi(mini(amount, s.hero_max_health - s.hero_health), 0)
	s.hero_health += healed
	var event: BattleEvent = _event(BattleEvent.Kind.HEAL, side)
	event.amount = healed
	event.amount2 = amount
	event.value = s.hero_health


func _buff(side: int, uid: int, attack_bonus: int, health_bonus: int) -> void:
	var m: BattleMinion = sides[side].minion(uid)
	if m == null:
		return
	m.attack += attack_bonus
	m.health += health_bonus
	m.max_health += health_bonus
	var event: BattleEvent = _event(BattleEvent.Kind.BUFF, side)
	event.uid = uid
	event.amount = attack_bonus
	event.amount2 = health_bonus
	event.value = m.attack
	event.value2 = m.health


## Removes dead minions (the player's side first, board order), runs their death effects, and ends the battle when a
## hero fell. Repeats while death effects kill more.
func _resolve() -> void:
	while not over:
		var dead_sides: PackedInt32Array = PackedInt32Array()
		var dead_cards: PackedInt32Array = PackedInt32Array()
		for side: int in 2:
			var s: BattleSide = sides[side]
			var i: int = 0
			while i < s.board.size():
				var m: BattleMinion = s.board[i]
				if m.health > 0:
					i += 1
					continue
				s.board.remove_at(i)
				var died: BattleEvent = _event(BattleEvent.Kind.DEATH, side)
				died.uid = m.uid
				died.card_id = m.card_id
				died.index = i
				dead_sides.push_back(side)
				dead_cards.push_back(m.card_id)
		for i: int in dead_cards.size():
			var row: GameData.CardRow = card(dead_cards[i])
			if row.trigger == GameData.CardTrigger.DEATH:
				_apply_effect(dead_sides[i], row, HERO, NO_SIDE, HERO)
		_check_heroes()
		if dead_cards.is_empty() or over:
			return


func _check_heroes() -> void:
	var player_down: bool = sides[PLAYER].hero_health <= 0
	var cpu_down: bool = sides[CPU].hero_health <= 0
	if player_down and cpu_down:
		_finish(NO_SIDE)
	elif cpu_down:
		_finish(PLAYER)
	elif player_down:
		_finish(CPU)


func _finish(won_by: int) -> void:
	if over:
		return
	over = true
	winner = won_by
	var ended: BattleEvent = _event(BattleEvent.Kind.GAME_OVER, won_by)
	ended.value = turn


func _event(kind: BattleEvent.Kind, side: int) -> BattleEvent:
	var e: BattleEvent = BattleEvent.new()
	e.kind = kind
	e.side = side
	events.append(e)
	return e
