class_name BattleBoardPanel
extends UIPanel
## Root panel of the battle: both heroes, both board rows, the player's hand, the mana, the deck and hand counts, the
## end turn button, the hint line, the turn banner, the summary of the last CPU turn and the end banner. It plays each
## `BattleFxEvent` in order on its own drawing of the battle (a played card flies from the hand, a minion lunges, a
## number pops, a burst of particles at the hit), then draws the battle from `BattleStateChangedEvent` and reports
## `BattleFxIdleEvent`. A press on a part of the board dips that part and becomes a `BattleInputEvent`; the back input
## and the pause button ask for the pause popup. A refused press says why over the pressed part.
##
## A minion keeps its place (its slot and anchor) from its landing until its death, so a death in the row does not
## renumber the others; a new minion takes the next free place right of the used ones. The places close up left to
## right when the player's turn starts.

@export var shake_root: Control
@export var hand_root: Control
@export var own_row: Control
@export var enemy_row: Control
@export var own_hero: BattleHeroSlot
@export var enemy_hero: BattleHeroSlot
@export var own_mana_label: Label
@export var own_crystals: Control
@export var enemy_mana_label: Label
@export var own_deck_label: Label
@export var enemy_deck_label: Label
@export var enemy_hand_label: Label
@export var enemy_backs: Control
@export var end_turn_button: Button
@export var end_turn_click: UIButton
@export var end_turn_glow: Control
@export var pause_button: Button
@export var pause_click: UIButton
@export var backdrop_click: UIButton
@export var hint_root: Control
@export var hint_label: Label
@export var banner: Control
@export var banner_label: Label
@export var turn_label: Label
@export var status_label: Label
@export var reveal: CommonCardView
@export var summary_root: Control
@export var summary_title_label: Label
@export var summary_lines: Control
@export var end_banner: Control
@export var end_banner_label: Label
@export var end_banner_portrait: TextureRect
@export var dust_ring: Control
@export var refusal: Control
@export var refusal_label: Label
@export var impact_ring: Control

var _hand_slots: Array[BattleHandSlot] = []
var _own_slots: Array[BattleMinionSlot] = []
var _enemy_slots: Array[BattleMinionSlot] = []
var _crystals: Array[Control] = []
var _backs: Array[Control] = []
## The drawing of the battle while effects play: the uids of each row, the player's hand, the enemy hand size.
var _own_uids: PackedInt32Array = PackedInt32Array()
var _enemy_uids: PackedInt32Array = PackedInt32Array()
var _hand: PackedInt32Array = PackedInt32Array()
var _enemy_hand: int = 0
var _queue: Array[BattleEvent] = []
var _draining: bool = false
var _state: BattleStateChangedEvent = null
var _sim: BattleSim = null
var _drain: Callable = Callable()
var _format_args: FormatArgs = FormatArgs.new()
var _lunge: TweenDefinition = TweenDefinition.new()
var _return: TweenDefinition = TweenDefinition.new()
## The attacker going back to its place while its hits play, and where it goes.
var _returning: BattleMinionSlot = null
var _return_handle: int = 0
var _return_to: Vector2 = Vector2.ZERO
## Particle key the next hits burst with: an attack or a minion card hits with `impact`, a spell with `spell_burst`.
var _hit_burst: String = ""
## Particle instances of every burst key: the ones of a key are `_burst_count` from `_burst_first`, used in turn.
var _bursts: Array[GPUParticles2D] = []
var _burst_first: Dictionary[String, int] = {}
var _burst_count: Dictionary[String, int] = {}
var _burst_next: Dictionary[String, int] = {}
var _hand_y: float = 0.0
var _glow_handle: int = 0
var _shown_mana: int = 0
var _shown_max_mana: int = 0
var _subscribed: bool = false
var _fly: TweenDefinition = TweenDefinition.new()
var _reveal_after_fly: TweenDefinition = TweenDefinition.new()
## Where the played card is shown big, from the prefab.
var _reveal_home: Vector2 = Vector2.ZERO
## What the CPU did in its turn, counted as its events arrive: the cards it played, the damage to the player hero,
## the player minions it killed and its hero healing. Shown when the player's turn after it starts.
var _turn_side: int = BattleSim.PLAYER
var _cpu_cards: PackedInt32Array = PackedInt32Array()
var _cpu_hero_damage: int = 0
var _cpu_minions_lost: int = 0
var _cpu_heal: int = 0
## Damage the CPU did to the player minions and the CPU minions that fell in its turn.
var _cpu_minion_damage: int = 0
var _cpu_minions_fell: int = 0
var _summary_lines: Array[Label] = []
## The height the prefab gives the summary: room for every line.
var _summary_max_height: float = 0.0
## Shockwave rings at hits, used in turn.
var _rings: Array[Control] = []
var _ring_next: int = 0
## The uid each slot of a row shows, by slot; 0 for an empty slot.
var _own_places: PackedInt32Array = PackedInt32Array()
var _enemy_places: PackedInt32Array = PackedInt32Array()
var _lift: TweenDefinition = TweenDefinition.new()
var _refusal_handle: int = 0
## The end turn text color the prefab gives; it turns green while the button glows.
var _end_turn_color: Color = Color.WHITE


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	if _hand_slots.is_empty():
		_collect()
	_drain = _drain_queue
	LocalizationCore.bind_text(end_turn_button, ReservedString.battle_end_turn())
	LocalizationCore.bind_text(pause_button, ReservedString.battle_pause_title())
	LocalizationCore.bind_text(own_hero.name_label, ReservedString.battle_you())
	own_hero.portrait.texture = CommonCardView.texture(ResourceKey.IMAGE__HERO_PLAYER, scope)
	end_turn_click.set_on_click(_on_end_turn)
	pause_click.set_on_click(_on_pause)
	backdrop_click.set_on_click(_on_backdrop)
	own_hero.click.set_on_click(_on_own_hero)
	enemy_hero.click.set_on_click(_on_enemy_hero)
	for i: int in _hand_slots.size():
		_hand_slots[i].click.set_on_click(_on_hand.bind(i))
	for i: int in _own_slots.size():
		_own_slots[i].click.set_on_click(_on_own_minion.bind(i))
	for i: int in _enemy_slots.size():
		_enemy_slots[i].click.set_on_click(_on_enemy_minion.bind(i))
	if not _subscribed:
		_subscribed = true
		EventCore.subscribe(BattleStateChangedEvent, _on_state)
		EventCore.subscribe(BattleFxEvent, _on_fx)
		EventCore.subscribe(BattleRefusedEvent, _on_refused)
	banner.visible = false
	reveal.visible = false
	dust_ring.visible = false
	refusal.visible = false
	summary_root.visible = false
	end_banner.visible = false
	LocalizationCore.bind_text(summary_title_label, ReservedString.battle_cpu_summary_title())
	end_turn_glow.visible = false
	EventCore.publish(EventCore.acquire(BattleViewReadyEvent))
	return true


func on_back() -> void:
	EventCore.publish(EventCore.acquire(BattlePauseRequestedEvent))


func _exit_tree() -> void:
	EventCore.unsubscribe_all(self)


func _collect() -> void:
	for child: Node in hand_root.get_children():
		if child is BattleHandSlot:
			_hand_slots.append(child as BattleHandSlot)
	for child: Node in own_row.get_children():
		if child is BattleMinionSlot:
			_own_slots.append(child as BattleMinionSlot)
	for child: Node in enemy_row.get_children():
		if child is BattleMinionSlot:
			_enemy_slots.append(child as BattleMinionSlot)
	_own_places.resize(_own_slots.size())
	_enemy_places.resize(_enemy_slots.size())
	for child: Node in own_crystals.get_children():
		if child is Control:
			_crystals.append(child as Control)
	for child: Node in enemy_backs.get_children():
		if child is Control:
			_backs.append(child as Control)
	_rings.append(impact_ring)
	for i: int in BattleConstants.BURST_POOL - 1:
		var ring: Control = impact_ring.duplicate() as Control
		impact_ring.get_parent().add_child(ring)
		_rings.append(ring)
	for ring: Control in _rings:
		ring.visible = false
		ring.z_index = BattleConstants.HIT_Z
	for hero: BattleHeroSlot in [own_hero, enemy_hero]:
		hero.number_label.z_index = BattleConstants.HIT_Z
	for slot: BattleMinionSlot in _own_slots + _enemy_slots:
		slot.number_label.z_index = BattleConstants.HIT_Z
	for child: Node in summary_lines.get_children():
		if child is Label:
			_summary_lines.push_back(child as Label)
	_summary_max_height = summary_root.size.y
	if not _hand_slots.is_empty():
		_hand_y = _hand_slots[0].position.y
	_reveal_home = reveal.position
	_end_turn_color = end_turn_button.get_theme_color("font_color")
	for key: String in BattleBoardPanel.burst_keys():
		_burst_first[key] = _bursts.size()
		_add_bursts(key)
		_burst_count[key] = _bursts.size() - _burst_first[key]
		_burst_next[key] = 0


## Lays the `count` shown enemy card backs out as a hand held across the table: fanned around the middle, hanging just
## under the top edge with every back whole on screen, the outer ones lower and leaning out.
func _fan_backs(count: int) -> void:
	var middle: float = enemy_backs.size.x * 0.5
	for i: int in count:
		var back: Control = _backs[i]
		var t: float = float(i) - float(count - 1) * 0.5
		var lean: float = t / maxf(float(_backs.size() - 1) * 0.5, 1.0)
		back.pivot_offset = Vector2(back.size.x * 0.5, 0.0)
		back.rotation = deg_to_rad(-lean * BattleConstants.BACK_FAN_DEGREES)
		back.position = Vector2(middle + t * BattleConstants.BACK_STEP - back.size.x * 0.5,
			BattleConstants.BACK_TOP + absf(lean) * BattleConstants.BACK_DROP)


## The particle effects of the board, loaded by the battle scene.
static func burst_keys() -> PackedStringArray:
	return PackedStringArray([
		ResourceKey.PARTICLE__BATTLE__SUMMON_BURST, ResourceKey.PARTICLE__BATTLE__IMPACT,
		ResourceKey.PARTICLE__BATTLE__SPELL_BURST, ResourceKey.PARTICLE__BATTLE__BUFF_SPARKLE,
		ResourceKey.PARTICLE__BATTLE__HERO_SHATTER])


## Adds `BattleConstants.BURST_POOL` instances of the particle `key` to the board, above the rows and the hand.
func _add_bursts(key: String) -> void:
	if not ResourceCore.is_loaded(key, ResourceCore.BaseKind.PACKED_SCENE):
		return
	var packed: PackedScene = ResourceCore.get_loaded(key, ResourceCore.BaseKind.PACKED_SCENE, scope) as PackedScene
	if packed == null:
		return
	for i: int in BattleConstants.BURST_POOL:
		var particles: GPUParticles2D = packed.instantiate() as GPUParticles2D
		if particles == null:
			continue
		particles.emitting = false
		particles.z_index = BattleConstants.HIT_Z
		shake_root.add_child(particles)
		_bursts.append(particles)


# --- input -----------------------------------------------------------------------------------------------------------

func _on_hand(index: int) -> void:
	_send(BattleInputEvent.Kind.HAND, index)


func _on_own_minion(index: int) -> void:
	_send(BattleInputEvent.Kind.OWN_MINION, index)


func _on_enemy_minion(index: int) -> void:
	_send(BattleInputEvent.Kind.ENEMY_MINION, index)


func _on_own_hero() -> void:
	_send(BattleInputEvent.Kind.OWN_HERO, -1)


func _on_enemy_hero() -> void:
	_send(BattleInputEvent.Kind.ENEMY_HERO, -1)


func _on_end_turn() -> void:
	_send(BattleInputEvent.Kind.END_TURN, -1)


func _on_backdrop() -> void:
	_send(BattleInputEvent.Kind.BACKDROP, -1)


func _on_pause() -> void:
	EventCore.publish(EventCore.acquire(BattlePauseRequestedEvent))


func _send(kind: BattleInputEvent.Kind, index: int) -> void:
	var target: Control = _pressed(kind, index)
	if kind == BattleInputEvent.Kind.BACKDROP and end_banner.visible:
		target = end_banner
	_press_pop(target)
	var event: BattleInputEvent = EventCore.acquire(BattleInputEvent) as BattleInputEvent
	event.kind = kind
	event.index = index
	event.uid = 0
	event.card_id = 0
	var slot: BattleMinionSlot = target as BattleMinionSlot
	if slot != null and slot.visible:
		event.uid = slot.uid
	if kind == BattleInputEvent.Kind.HAND and index >= 0 and index < _hand.size():
		event.card_id = _hand[index]
	EventCore.publish(event)


## The part of the board a press of `kind` at `index` landed on, or `null`.
func _pressed(kind: BattleInputEvent.Kind, index: int) -> Control:
	match kind:
		BattleInputEvent.Kind.HAND:
			return _hand_slots[index] if index >= 0 and index < _hand_slots.size() else null
		BattleInputEvent.Kind.OWN_MINION:
			return _own_slots[index] if index >= 0 and index < _own_slots.size() else null
		BattleInputEvent.Kind.ENEMY_MINION:
			return _enemy_slots[index] if index >= 0 and index < _enemy_slots.size() else null
		BattleInputEvent.Kind.OWN_HERO:
			return own_hero
		BattleInputEvent.Kind.ENEMY_HERO:
			return enemy_hero
		BattleInputEvent.Kind.END_TURN:
			return end_turn_button
	return null


func _press_pop(target: Control) -> void:
	if target == null or not target.is_visible_in_tree():
		return
	target.pivot_offset = target.size * 0.5
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__PRESS_POP, scope, target)


## A press that could not act: the reason pops in over the pressed part (beside it when that part is at the top
## edge) and goes away, the pressed card or minion wobbles, the mana count flashes when mana was short and the enemy guards pulse
## when one stands in the way.
func _on_refused(event: BattleRefusedEvent) -> void:
	LocalizationCore.bind_text(refusal_label, event.text_key)
	var target: Control = _pressed(event.kind, event.index)
	if target == null or not target.is_visible_in_tree():
		target = end_turn_button
	var rect: Rect2 = target.get_global_rect()
	var hud: Control = refusal.get_parent() as Control
	var to_hud: Transform2D = hud.get_global_transform().affine_inverse()
	var top_left: Vector2 = to_hud * rect.position
	var bottom_right: Vector2 = to_hud * rect.end
	var gap: float = BattleConstants.REFUSAL_GAP
	var edge: float = BattleConstants.REFUSAL_EDGE
	var x: float = (top_left.x + bottom_right.x - refusal.size.x) * 0.5
	var y: float = top_left.y - gap - refusal.size.y
	if y < BattleConstants.REFUSAL_TOP:
		y = (top_left.y + bottom_right.y - refusal.size.y) * 0.5
		x = bottom_right.x + gap
		if x + refusal.size.x > hud.size.x - edge:
			x = top_left.x - gap - refusal.size.x
	x = clampf(x, edge, hud.size.x - edge - refusal.size.x)
	refusal.position = Vector2(_clear_of_heroes(x, y, to_hud), y)
	refusal.pivot_offset = refusal.size * 0.5
	refusal.visible = true
	if _refusal_handle != 0:
		TweenCore.stop(_refusal_handle)
	var handle: int = TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__REFUSAL_POP, scope, refusal)
	_refusal_handle = handle
	var shaken: Control = null
	if target is BattleHandSlot:
		shaken = (target as BattleHandSlot).card
	elif target is BattleMinionSlot:
		shaken = (target as BattleMinionSlot).body
	if shaken != null:
		shaken.pivot_offset = shaken.size * 0.5
		TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__REFUSE_SHAKE, scope, shaken)
	if event.mana:
		TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__MANA_FLASH, scope, own_mana_label)
	if event.guard:
		for slot: BattleMinionSlot in _enemy_slots:
			if slot.visible and slot.guard_frame.visible:
				slot.guard_frame.pivot_offset = slot.guard_frame.size * 0.5
				TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__STAT_POP, scope, slot.guard_frame)
	await _wait(handle)
	if _refusal_handle == handle and is_inside_tree():
		refusal.visible = false
		_refusal_handle = 0


## The left of a refusal at (`x`, `y`) moved beside a hero it would cover, to the side its center is on (the other side
## when that one is off the screen).
func _clear_of_heroes(x: float, y: float, to_hud: Transform2D) -> float:
	var hud: Control = refusal.get_parent() as Control
	var edge: float = BattleConstants.REFUSAL_EDGE
	var gap: float = BattleConstants.REFUSAL_GAP
	for hero: BattleHeroSlot in [own_hero, enemy_hero]:
		var rect: Rect2 = hero.get_global_rect()
		var hero_rect: Rect2 = Rect2(to_hud * rect.position, rect.size)
		if not Rect2(Vector2(x, y), refusal.size).intersects(hero_rect):
			continue
		var left: float = hero_rect.position.x - gap - refusal.size.x
		var right: float = hero_rect.end.x + gap
		var go_left: bool = x + refusal.size.x * 0.5 < hero_rect.get_center().x
		if go_left and left < edge:
			go_left = false
		elif not go_left and right + refusal.size.x > hud.size.x - edge:
			go_left = true
		x = left if go_left else right
	return x


# --- state -----------------------------------------------------------------------------------------------------------

func _on_state(event: BattleStateChangedEvent) -> void:
	_state = event
	if _sim != event.sim:
		_sim = event.sim
		_queue.clear()
		_draining = false
		_returning = null
		_return_handle = 0
		_hit_burst = ""
		_turn_side = BattleSim.PLAYER
		_cpu_cards.clear()
		summary_root.visible = false
		end_banner.visible = false
		reveal.visible = false
		_own_places.fill(0)
		_enemy_places.fill(0)
		_sync_from_sim()
	if not _draining:
		_draw_state()


## Copies the battle into the drawing: rows, hand, heroes, mana and counts.
func _sync_from_sim() -> void:
	_own_uids.clear()
	_enemy_uids.clear()
	_hand.clear()
	_enemy_hand = 0
	var opponent: GameData.OpponentRow = GameData.OpponentTable.get_row(_state.opponent_id)
	LocalizationCore.bind_text(enemy_hero.name_label, opponent.name)
	enemy_hero.portrait.texture = CommonCardView.texture(opponent.portrait, scope)
	for hero: BattleHeroSlot in [own_hero, enemy_hero]:
		hero.body.modulate = Color.WHITE
		hero.body.scale = Vector2.ONE
		hero.body.rotation = 0.0
		hero.number_label.visible = false
	_set_counts_visible(_sim != null)
	if _sim == null:
		own_hero.set_health(GameSetting.hero_health(), GameSetting.hero_health())
		enemy_hero.set_health(opponent.hero_health, opponent.hero_health)
		_set_mana(0, 0)
		_bind_rows()
		_bind_hand()
		return
	var own: BattleSide = _sim.sides[BattleSim.PLAYER]
	var enemy: BattleSide = _sim.sides[BattleSim.CPU]
	for m: BattleMinion in own.board:
		_own_uids.push_back(m.uid)
	for m: BattleMinion in enemy.board:
		_enemy_uids.push_back(m.uid)
	_hand = own.hand.duplicate()
	_enemy_hand = enemy.hand.size()
	own_hero.set_health(own.hero_health, own.hero_max_health)
	enemy_hero.set_health(enemy.hero_health, enemy.hero_max_health)
	_set_mana(own.mana, own.max_mana)
	_bind_rows()
	_bind_hand()
	_layout_all()


## Draws what the state says beyond the drawing: picks, outlines, hint, end turn button, status.
func _draw_state() -> void:
	if _state == null:
		return
	var starting: bool = _state.stage == BattleScene.Stage.STARTING
	status_label.visible = starting
	if starting:
		LocalizationCore.bind_text(status_label, ReservedString.battle_starting())
	var player_turn: bool = _state.stage == BattleScene.Stage.PLAYER_TURN and _sim != null and not _sim.over
	end_turn_button.disabled = not player_turn
	LocalizationCore.bind_text(end_turn_button,
		ReservedString.battle_enemy_thinking() if _state.stage == BattleScene.Stage.CPU_TURN else ReservedString.battle_end_turn())
	hint_root.visible = not _state.hint.is_empty()
	if hint_root.visible:
		LocalizationCore.bind_text(hint_label, _state.hint)
	if _sim != null:
		_sync_from_sim()
		_format_args.clear()
		_format_args.set_int("turn", _sim.turn)
		turn_label.text = LocalizationCore.format(ReservedString.battle_turn(), _format_args)
	_draw_outlines(player_turn)


func _draw_outlines(player_turn: bool) -> void:
	var any_move: bool = false
	for i: int in _hand_slots.size():
		var slot: BattleHandSlot = _hand_slots[i]
		if not slot.visible:
			continue
		var picked: bool = player_turn and _state.pick == BattleScene.Pick.HAND and _state.pick_hand == i
		var playable: bool = player_turn and _sim.check_play(BattleSim.PLAYER, i) == BattleSim.PlayCheck.OK
		any_move = any_move or playable
		slot.card.set_glow(picked or playable, CommonConstants.CARD_PICKED_COLOR if picked else CommonConstants.CARD_PLAYABLE_COLOR)
		slot.card.set_waiting(player_turn and not picked and not playable)
		slot.position.y = _hand_y - (BattleConstants.PICK_RISE if picked else 0.0)
		slot.card.pivot_offset = slot.card.size * 0.5
		slot.card.scale = Vector2.ONE * (BattleConstants.PICK_SCALE if picked else 1.0)
		slot.z_index = 1 if picked else 0
	for i: int in _own_slots.size():
		var slot: BattleMinionSlot = _own_slots[i]
		if not slot.visible:
			continue
		var target: bool = player_turn and _is_target(BattleSim.PLAYER, slot.uid)
		var picked: bool = player_turn and _state.pick == BattleScene.Pick.ATTACKER and _state.pick_uid == slot.uid
		var ready: bool = player_turn and _state.pick == BattleScene.Pick.NONE and _sim.can_attack(BattleSim.PLAYER, slot.uid)
		any_move = any_move or (player_turn and _sim.can_attack(BattleSim.PLAYER, slot.uid))
		_outline(slot.glow, picked or target or ready,
			BattleConstants.PICKED_COLOR if picked else (BattleConstants.TARGET_COLOR if target else BattleConstants.READY_COLOR))
		var minion: BattleMinion = _sim.sides[BattleSim.PLAYER].minion(slot.uid)
		slot.sleep_label.visible = minion != null and minion.sleeping and minion.attack > 0
	for slot: BattleMinionSlot in _enemy_slots:
		if slot.visible:
			_outline(slot.glow, player_turn and _is_target(BattleSim.CPU, slot.uid), BattleConstants.TARGET_COLOR)
			slot.sleep_label.visible = false
	_outline(own_hero.glow, player_turn and _is_target(BattleSim.PLAYER, BattleSim.HERO), BattleConstants.TARGET_COLOR)
	_outline(enemy_hero.glow, player_turn and _is_target(BattleSim.CPU, BattleSim.HERO), BattleConstants.TARGET_COLOR)
	_set_end_turn_glow(player_turn and not any_move)


func _outline(glow: Control, on: bool, color: Color) -> void:
	glow.visible = on
	glow.self_modulate = color


func _set_end_turn_glow(on: bool) -> void:
	if on == end_turn_glow.visible:
		return
	end_turn_glow.visible = on
	end_turn_glow.self_modulate = BattleConstants.READY_COLOR
	if on:
		end_turn_button.add_theme_color_override("font_color", BattleConstants.READY_COLOR)
	else:
		end_turn_button.add_theme_color_override("font_color", _end_turn_color)
	if on:
		_glow_handle = TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__GLOW_PULSE, scope, end_turn_glow)
	elif _glow_handle != 0:
		TweenCore.stop(_glow_handle)
		_glow_handle = 0


## Whether the character is a target of the waiting pick.
func _is_target(side: int, uid: int) -> bool:
	if _state.pick == BattleScene.Pick.HAND:
		var hand: PackedInt32Array = _sim.sides[BattleSim.PLAYER].hand
		if _state.pick_hand < 0 or _state.pick_hand >= hand.size():
			return false
		return _sim.is_play_target(BattleSim.PLAYER, hand[_state.pick_hand], side, uid)
	if _state.pick == BattleScene.Pick.ATTACKER:
		return _sim.is_attack_target(BattleSim.PLAYER, _state.pick_uid, side, uid)
	return false


# --- binding and layout ----------------------------------------------------------------------------------------------

func _bind_rows() -> void:
	_bind_row(BattleSim.PLAYER, _own_uids, _own_slots)
	_bind_row(BattleSim.CPU, _enemy_uids, _enemy_slots)


func _bind_row(side: int, uids: PackedInt32Array, slots: Array[BattleMinionSlot]) -> void:
	var places: PackedInt32Array = _places(side)
	BattleBoardPanel._assign_places(places, uids)
	for i: int in slots.size():
		var slot: BattleMinionSlot = slots[i]
		slot.visible = places[i] != 0
		if not slot.visible or _sim == null:
			continue
		var m: BattleMinion = _sim.sides[side].minion(places[i])
		if m == null:
			continue
		slot.show_minion(m.uid, m.card_id, m.attack, m.health, m.max_health, m.guard, m.ward,
			m.sleeping and side == BattleSim.PLAYER, scope)
		slot.glow.visible = false


func _bind_hand() -> void:
	for i: int in _hand_slots.size():
		var slot: BattleHandSlot = _hand_slots[i]
		slot.visible = i < _hand.size()
		if slot.visible and slot.card.card_id != _hand[i]:
			slot.card.show_card(_hand[i], scope)
		if slot.visible:
			slot.card.modulate = Color.WHITE
			slot.card.scale = Vector2.ONE
	for i: int in _backs.size():
		_backs[i].visible = i < _enemy_hand
	_fan_backs(mini(_enemy_hand, _backs.size()))
	_format_args.clear()
	_format_args.set_int("count", _enemy_hand)
	enemy_hand_label.text = LocalizationCore.format(ReservedString.battle_hand_count(), _format_args)


func _layout_all() -> void:
	_layout_row(BattleSim.PLAYER)
	_layout_row(BattleSim.CPU)
	_layout_hand()
	if _sim != null:
		_set_counts()


## Puts each minion of the row of `side` at its place in the row order, centered on the board.
func _layout_row(side: int) -> void:
	var uids: PackedInt32Array = _own_uids if side == BattleSim.PLAYER else _enemy_uids
	var slots: Array[BattleMinionSlot] = _own_slots if side == BattleSim.PLAYER else _enemy_slots
	var places: PackedInt32Array = _places(side)
	var count: int = uids.size()
	for i: int in count:
		var at: int = places.find(uids[i])
		if at < 0:
			continue
		var slot: BattleMinionSlot = slots[at]
		slot.position.x = BattleConstants.ROW_CENTER_X + (float(i) - float(count - 1) * 0.5) * BattleConstants.MINION_STEP \
			- slot.size.x * 0.5


## The slot uids of the row of `side`.
func _places(side: int) -> PackedInt32Array:
	return _own_places if side == BattleSim.PLAYER else _enemy_places


## Frees the slots of the uids no longer in `uids` and gives each new uid the first free slot right of the used ones,
## or the first free slot when none is free there.
static func _assign_places(places: PackedInt32Array, uids: PackedInt32Array) -> void:
	for i: int in places.size():
		if places[i] != 0 and not uids.has(places[i]):
			places[i] = 0
	for uid: int in uids:
		if places.has(uid):
			continue
		var last: int = -1
		for i: int in places.size():
			if places[i] != 0:
				last = i
		var at: int = -1
		for i: int in range(last + 1, places.size()):
			if places[i] == 0:
				at = i
				break
		if at < 0:
			at = places.find(0)
		if at >= 0:
			places[at] = uid


## Gives the minions the slots in row order again, left to right.
func _close_up_places() -> void:
	for side: int in [BattleSim.PLAYER, BattleSim.CPU]:
		var places: PackedInt32Array = _places(side)
		var uids: PackedInt32Array = _own_uids if side == BattleSim.PLAYER else _enemy_uids
		places.fill(0)
		for i: int in mini(uids.size(), places.size()):
			places[i] = uids[i]
		_rebind_row(side)


## The anchor number of the minion `uid` of `side` (its slot from 1), or 0 when it is not on the board.
func anchor_number(side: int, uid: int) -> int:
	return _places(side).find(uid) + 1


## Lays the hand out side by side around the board center. A hand too wide for that moves left up to
## `BattleConstants.HAND_LEFT`; the cards overlap only when even that is too narrow.
func _layout_hand() -> void:
	var count: int = mini(_hand.size(), _hand_slots.size())
	if count == 0:
		return
	var card_width: float = _hand_slots[0].size.x
	var span: float = BattleConstants.HAND_RIGHT - BattleConstants.HAND_LEFT
	var step: float = BattleConstants.HAND_STEP_MAX
	if count > 1:
		step = minf(step, (span - card_width) / float(count - 1))
	var width: float = float(count - 1) * step + card_width
	var left: float = clampf(BattleConstants.ROW_CENTER_X - width * 0.5, BattleConstants.HAND_LEFT,
		BattleConstants.HAND_RIGHT - width)
	for i: int in count:
		var slot: BattleHandSlot = _hand_slots[i]
		slot.position.x = left + float(i) * step
		slot.position.y = _hand_y


func _set_mana(mana: int, max_mana: int) -> void:
	_shown_mana = mana
	_shown_max_mana = max_mana
	_format_args.clear()
	_format_args.set_int("mana", mana)
	_format_args.set_int("max", max_mana)
	own_mana_label.text = LocalizationCore.format(ReservedString.battle_mana(), _format_args)
	for i: int in _crystals.size():
		_crystals[i].visible = i < max_mana
		_crystals[i].self_modulate = BattleConstants.MANA_FULL_COLOR if i < mana else BattleConstants.MANA_SPENT_COLOR


## Shows the turn, the enemy mana and the deck and hand counts, which only a running battle has.
func _set_counts_visible(on: bool) -> void:
	for label: Label in [turn_label, enemy_mana_label, own_deck_label, enemy_deck_label, enemy_hand_label]:
		label.visible = on


func _set_counts() -> void:
	var enemy: BattleSide = _sim.sides[BattleSim.CPU]
	_format_args.clear()
	_format_args.set_int("mana", enemy.mana)
	_format_args.set_int("max", enemy.max_mana)
	enemy_mana_label.text = LocalizationCore.format(ReservedString.battle_mana(), _format_args)
	_format_args.clear()
	_format_args.set_int("count", _sim.sides[BattleSim.PLAYER].deck.size())
	own_deck_label.text = LocalizationCore.format(ReservedString.battle_deck_left(), _format_args)
	_format_args.clear()
	_format_args.set_int("count", enemy.deck.size())
	enemy_deck_label.text = LocalizationCore.format(ReservedString.battle_deck_left(), _format_args)


# --- effects ---------------------------------------------------------------------------------------------------------

func _on_fx(event: BattleFxEvent) -> void:
	_count_cpu_turn(event.fx)
	_queue.append(event.fx)
	if not _draining:
		_draining = true
		_hide_outlines()
		_drain.call_deferred()


## Counts what the CPU does in its turn as its events arrive. A CPU turn start begins a new count.
func _count_cpu_turn(e: BattleEvent) -> void:
	match e.kind:
		BattleEvent.Kind.TURN_START:
			_turn_side = e.side
			if e.side == BattleSim.CPU:
				_cpu_cards.clear()
				_cpu_hero_damage = 0
				_cpu_minions_lost = 0
				_cpu_heal = 0
				_cpu_minion_damage = 0
				_cpu_minions_fell = 0
			return
	if _turn_side != BattleSim.CPU:
		return
	match e.kind:
		BattleEvent.Kind.PLAY_CARD:
			if e.side == BattleSim.CPU:
				_cpu_cards.push_back(e.card_id)
		BattleEvent.Kind.DAMAGE:
			if e.side == BattleSim.PLAYER and e.uid == BattleSim.HERO:
				_cpu_hero_damage += e.amount
			elif e.side == BattleSim.PLAYER:
				_cpu_minion_damage += e.amount
		BattleEvent.Kind.DEATH:
			if e.side == BattleSim.PLAYER:
				_cpu_minions_lost += 1
			else:
				_cpu_minions_fell += 1
		BattleEvent.Kind.HEAL:
			if e.side == BattleSim.CPU:
				_cpu_heal += e.amount


## Shows what the CPU did in the turn that just ended: the cards it played, then what the player lost, the CPU minions
## that fell and what the CPU healed. Each line is a label of the summary, colored by what it says.
func _show_summary() -> void:
	var names: PackedStringArray = PackedStringArray()
	for card_id: int in _cpu_cards:
		names.push_back(LocalizationCore.get_text(GameData.CardTable.get_row(card_id).name))
	var lines: PackedStringArray = PackedStringArray()
	var colors: PackedColorArray = PackedColorArray()
	if names.is_empty():
		lines.push_back(LocalizationCore.get_text(ReservedString.battle_cpu_played_none()))
	else:
		_format_args.clear()
		_format_args.set_string("cards", LocalizationCore.get_text(ReservedString.list_separator()).join(names))
		lines.push_back(LocalizationCore.format(ReservedString.battle_cpu_played(), _format_args))
	colors.push_back(BattleConstants.SUMMARY_COLOR)
	var keys: PackedStringArray = PackedStringArray([ReservedString.battle_cpu_hero_damage(),
		ReservedString.battle_cpu_minion_damage(), ReservedString.battle_cpu_minions_lost(),
		ReservedString.battle_cpu_enemy_minions_lost(), ReservedString.battle_cpu_hero_heal()])
	var arg_names: PackedStringArray = PackedStringArray(["amount", "amount", "count", "count", "amount"])
	var values: PackedInt32Array = PackedInt32Array([_cpu_hero_damage, _cpu_minion_damage, _cpu_minions_lost,
		_cpu_minions_fell, _cpu_heal])
	var line_colors: PackedColorArray = PackedColorArray([BattleConstants.SUMMARY_LOSS_COLOR,
		BattleConstants.SUMMARY_LOSS_COLOR, BattleConstants.SUMMARY_LOSS_COLOR, BattleConstants.SUMMARY_GAIN_COLOR,
		BattleConstants.HEAL_COLOR])
	for i: int in keys.size():
		if values[i] <= 0:
			continue
		_format_args.clear()
		_format_args.set_int(arg_names[i], values[i])
		lines.push_back(LocalizationCore.format(keys[i], _format_args))
		colors.push_back(line_colors[i])
	var height: float = 0.0
	for i: int in _summary_lines.size():
		var label: Label = _summary_lines[i]
		label.visible = i < lines.size()
		if i < lines.size():
			label.text = lines[i]
			label.add_theme_color_override("font_color", colors[i])
			height += _wrapped_height(label, summary_lines.size.x)
	summary_root.size.y = minf(summary_lines.position.y + height + BattleConstants.SUMMARY_BOTTOM, _summary_max_height)
	summary_root.visible = true


## The height of the text of `label` wrapped at `width`.
static func _wrapped_height(label: Label, width: float) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return float(maxi(ceili(text_width / maxf(width, 1.0)), 1)) * font.get_height(font_size)


func _hide_outlines() -> void:
	hint_root.visible = false
	_set_end_turn_glow(false)
	for slot: BattleHandSlot in _hand_slots:
		slot.card.set_glow(false, CommonConstants.CARD_PLAYABLE_COLOR)
		slot.position.y = _hand_y
	for slot: BattleMinionSlot in _own_slots:
		slot.glow.visible = false
	for slot: BattleMinionSlot in _enemy_slots:
		slot.glow.visible = false
	own_hero.glow.visible = false
	enemy_hero.glow.visible = false


## Plays the queued events one by one (hits and deaths that come together play together), then draws the battle as
## it is and reports idle.
func _drain_queue() -> void:
	var sim: BattleSim = _sim
	while not _queue.is_empty():
		if not is_inside_tree() or sim != _sim:
			return
		var e: BattleEvent = _queue[0]
		_queue.remove_at(0)
		match e.kind:
			BattleEvent.Kind.DAMAGE, BattleEvent.Kind.WARD_BREAK:
				await _play_hits(e)
			BattleEvent.Kind.DEATH:
				await _settle_return()
				await _play_deaths(e)
			_:
				await _settle_return()
				await _play(e)
	await _settle_return()
	if not is_inside_tree() or sim != _sim:
		return
	_draining = false
	_draw_state()
	EventCore.publish(EventCore.acquire(BattleFxIdleEvent))


func _play(e: BattleEvent) -> void:
	match e.kind:
		BattleEvent.Kind.TURN_START:
			await _play_turn_start(e)
		BattleEvent.Kind.DRAW:
			await _play_draw(e)
		BattleEvent.Kind.BURN:
			var burned: FormatArgs = FormatArgs.new()
			burned.set_string("name", LocalizationCore.get_text(GameData.CardTable.get_row(e.card_id).name))
			MessageCore.show_toast(ReservedString.battle_burned(), burned)
		BattleEvent.Kind.FATIGUE:
			var tired: FormatArgs = FormatArgs.new()
			tired.set_int("amount", e.amount)
			_hit_burst = ResourceKey.PARTICLE__BATTLE__IMPACT
			MessageCore.show_toast(ReservedString.battle_fatigue(), tired)
		BattleEvent.Kind.PLAY_CARD:
			await _play_card(e)
		BattleEvent.Kind.SUMMON:
			await _play_summon(e)
		BattleEvent.Kind.ATTACK:
			await _play_attack(e)
		BattleEvent.Kind.HEAL:
			await _play_heal(e)
		BattleEvent.Kind.BUFF:
			await _play_buff(e)
		BattleEvent.Kind.GAME_OVER:
			await _play_game_over(e)


func _play_turn_start(e: BattleEvent) -> void:
	var own: bool = e.side == BattleSim.PLAYER
	if not own:
		summary_root.visible = false
	if own:
		_set_mana(e.value2, e.value2)
		_close_up_places()
		SoundCore.play(ReservedSound.battle_your_turn(), SoundCore.SoundBus.SFX, scope)
	else:
		_format_args.clear()
		_format_args.set_int("mana", e.value2)
		_format_args.set_int("max", e.value2)
		enemy_mana_label.text = LocalizationCore.format(ReservedString.battle_mana(), _format_args)
	_format_args.clear()
	_format_args.set_int("turn", e.value)
	turn_label.text = LocalizationCore.format(ReservedString.battle_turn(), _format_args)
	LocalizationCore.bind_text(banner_label, ReservedString.battle_your_turn() if own else ReservedString.battle_enemy_turn())
	banner.modulate = BattleConstants.WIN_COLOR if own else BattleConstants.LOSE_COLOR
	banner.visible = true
	banner.pivot_offset = banner.size * 0.5
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__TURN_BANNER, scope, banner))
	banner.visible = false
	if own and e.value > 1:
		_show_summary()


func _play_draw(e: BattleEvent) -> void:
	if e.side != BattleSim.PLAYER:
		_enemy_hand += 1
		_bind_hand()
		return
	_hand.push_back(e.card_id)
	_bind_hand()
	_layout_hand()
	var slot: BattleHandSlot = _hand_slots[mini(_hand.size(), _hand_slots.size()) - 1]
	slot.card.pivot_offset = slot.card.size * 0.5
	SoundCore.play(ReservedSound.battle_card_draw(), SoundCore.SoundBus.SFX, scope)
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__HAND_DRAW, scope, slot.card))


## A played card. The player's card is lifted from its hand place with its green glow and flies: a minion to the row place it lands on, a spell to
## the reveal place where it is shown big. A CPU card is shown big at the reveal place.
func _play_card(e: BattleEvent) -> void:
	var row: GameData.CardRow = GameData.CardTable.get_row(e.card_id)
	var own: bool = e.side == BattleSim.PLAYER
	var from: Vector2 = _reveal_home
	if own:
		if e.index >= 0 and e.index < _hand.size():
			if e.index < _hand_slots.size():
				from = _hand_slots[e.index].position
			_hand.remove_at(e.index)
		_set_mana(maxi(_shown_mana - row.cost, 0), _shown_max_mana)
	else:
		_enemy_hand = maxi(_enemy_hand - 1, 0)
	_bind_hand()
	_layout_hand()
	var spell: bool = row.kind == GameData.CardKind.SPELL
	_hit_burst = ResourceKey.PARTICLE__BATTLE__SPELL_BURST if spell else ResourceKey.PARTICLE__BATTLE__IMPACT
	reveal.show_card(e.card_id, scope)
	reveal.set_glow(false, CommonConstants.CARD_PLAYABLE_COLOR)
	reveal.pivot_offset = reveal.size * 0.5
	reveal.modulate = Color.WHITE
	reveal.scale = Vector2.ONE
	reveal.position = from
	reveal.visible = true
	SoundCore.play(ReservedSound.battle_spell_cast() if spell else ReservedSound.battle_card_play(), SoundCore.SoundBus.SFX, scope)
	if own:
		reveal.set_glow(true, CommonConstants.CARD_PLAYABLE_COLOR)
		if _copy_preset(ResourceKey.TWEEN__BATTLE__CARD_LIFT, _lift):
			await _wait(TweenCore.play(_lift, reveal))
	if own and not spell:
		var minion_width: float = _own_slots[0].size.x if not _own_slots.is_empty() else reveal.size.x
		await _fly_to(_landing_place(), minion_width / reveal.size.x)
		reveal.visible = false
		return
	if own:
		await _fly_to(_reveal_home, 1.0)
		reveal.set_glow(false, CommonConstants.CARD_PLAYABLE_COLOR)
		if _copy_preset(ResourceKey.TWEEN__BATTLE__CARD_REVEAL, _reveal_after_fly):
			for change: TweenChange in _reveal_after_fly.steps[0].changes:
				change.use_start_value = false
			await _wait(TweenCore.play(_reveal_after_fly, reveal))
	else:
		await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__CARD_REVEAL, scope, reveal))
	reveal.visible = false


## Flies the shown card to `to` (its top left at scale 1), ending at `end_scale` around its center.
func _fly_to(to: Vector2, end_scale: float) -> void:
	if not _copy_preset(ResourceKey.TWEEN__BATTLE__CARD_FLY, _fly):
		reveal.position = to
		return
	for change: TweenChange in _fly.steps[0].changes:
		if change.property == TweenCore.TweenProperty.POSITION:
			change.use_start_value = true
			change.start_value = Vector4(reveal.position.x, reveal.position.y, 0.0, 0.0)
			change.target_value = Vector4(to.x, to.y, 0.0, 0.0)
		elif change.property == TweenCore.TweenProperty.SCALE:
			change.target_value = Vector4(end_scale, end_scale, 0.0, 0.0)
	await _wait(TweenCore.play(_fly, reveal))


## Where the shown card goes for a minion the player plays: centered on the row place the minion lands on, the next
## place at the right end of the own row.
func _landing_place() -> Vector2:
	var count: int = _own_uids.size()
	var slot_size: Vector2 = _own_slots[0].size if not _own_slots.is_empty() else reveal.size
	var row_top: float = _own_slots[0].position.y if not _own_slots.is_empty() else _reveal_home.y
	var center: Vector2 = Vector2(BattleConstants.ROW_CENTER_X + float(count) * 0.5 * BattleConstants.MINION_STEP,
		row_top + slot_size.y * 0.5)
	return center - reveal.size * 0.5


func _play_summon(e: BattleEvent) -> void:
	var own: bool = e.side == BattleSim.PLAYER
	var uids: PackedInt32Array = _own_uids if own else _enemy_uids
	var index: int = clampi(e.index, 0, uids.size())
	uids.insert(index, e.uid)
	_rebind_row(e.side)
	var slot: BattleMinionSlot = _slot_of(e.side, e.uid)
	if slot == null:
		return
	slot.body.pivot_offset = slot.body.size * 0.5
	SoundCore.play(ReservedSound.battle_card_play(), SoundCore.SoundBus.SFX, scope)
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__SUMMON, scope, slot.body))
	if not is_inside_tree():
		return
	_burst(ResourceKey.PARTICLE__BATTLE__SUMMON_BURST, slot.center())
	_raise_dust(slot)
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__LAND_THUMP, scope, shake_root)
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__SUMMON_SETTLE, scope, slot.body))


## The ring of dust under a minion that just landed spreads out and fades.
func _raise_dust(slot: BattleMinionSlot) -> void:
	var foot: Vector2 = slot.position + Vector2(slot.size.x * 0.5, slot.size.y * BattleConstants.DUST_FOOT)
	dust_ring.position = foot - dust_ring.size * 0.5
	dust_ring.pivot_offset = dust_ring.size * 0.5
	dust_ring.visible = true
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__DUST_RING, scope, dust_ring)


## The attacker lunges to its target; it goes back to its place while the hits that follow play.
func _play_attack(e: BattleEvent) -> void:
	_hit_burst = ResourceKey.PARTICLE__BATTLE__IMPACT
	var slot: BattleMinionSlot = _slot_of(e.side, e.uid)
	if slot == null:
		return
	var from: Vector2 = slot.position
	var to: Vector2 = _center_of(e.target_side, e.target_uid) - slot.size * 0.5
	if not _copy_preset(ResourceKey.TWEEN__BATTLE__ATTACK_LUNGE, _lunge) \
			or not _copy_preset(ResourceKey.TWEEN__BATTLE__ATTACK_RETURN, _return):
		return
	var reach: Vector2 = from.lerp(to, BattleConstants.LUNGE_REACH)
	for change: TweenChange in _lunge.steps[0].changes:
		change.use_start_value = true
		change.start_value = Vector4(from.x, from.y, 0.0, 0.0)
		change.target_value = Vector4(reach.x, reach.y, 0.0, 0.0)
	for change: TweenChange in _return.steps[0].changes:
		change.use_start_value = false
		change.target_value = Vector4(from.x, from.y, 0.0, 0.0)
	slot.z_index = 1
	SoundCore.play(ReservedSound.battle_attack(), SoundCore.SoundBus.SFX, scope)
	await _wait(TweenCore.play(_lunge, slot))
	if not is_inside_tree():
		return
	_returning = slot
	_return_to = from
	_return_handle = TweenCore.play(_return, slot)


## Copies the loaded tween preset `key` into `into`. False when it is not loaded or has no step.
func _copy_preset(key: String, into: TweenDefinition) -> bool:
	if not ResourceCore.is_loaded(key, TweenCore.get_preset_kind()):
		return false
	var preset: TweenDefinition = ResourceCore.get_loaded(key, TweenCore.get_preset_kind(), scope) as TweenDefinition
	return preset != null and TweenCore.copy_definition(preset, into) and not into.steps.is_empty()


## Waits for the attacker to be back in its place.
func _settle_return() -> void:
	if _returning == null:
		return
	var slot: BattleMinionSlot = _returning
	await _wait(_return_handle)
	if _returning != slot:
		return
	slot.position = _return_to
	slot.z_index = 0
	_returning = null
	_return_handle = 0


## A damage or ward break, and the ones right after it, together: each bursts at its character and the board jolts
## once, hard when a hero took a big hit.
func _play_hits(first: BattleEvent) -> void:
	var big: bool = _is_big_hit(first)
	var hero_hit: bool = _is_hero_hit(first)
	var last: int = _play_hit(first)
	while not _queue.is_empty() and (_queue[0].kind == BattleEvent.Kind.DAMAGE or _queue[0].kind == BattleEvent.Kind.WARD_BREAK):
		var e: BattleEvent = _queue[0]
		_queue.remove_at(0)
		big = big or _is_big_hit(e)
		hero_hit = hero_hit or _is_hero_hit(e)
		var handle: int = _play_hit(e)
		if handle != 0:
			last = handle
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__BOARD_SHAKE if big else ResourceKey.TWEEN__BATTLE__IMPACT_SHAKE,
		scope, shake_root)
	if hero_hit:
		_flash(ResourceKey.TWEEN__BATTLE__HIT_FLASH)
	_hit_burst = ""
	await _wait(last)
	await _settle_return()


static func _is_big_hit(e: BattleEvent) -> bool:
	return e.kind == BattleEvent.Kind.DAMAGE and e.uid == BattleSim.HERO and e.amount >= BattleConstants.SHAKE_DAMAGE


static func _is_hero_hit(e: BattleEvent) -> bool:
	return e.kind == BattleEvent.Kind.DAMAGE and e.uid == BattleSim.HERO and e.amount > 0


## Flashes the screen with the tween preset `key`.
func _flash(key: String) -> void:
	if not ResourceCore.is_loaded(key, TweenCore.get_preset_kind()):
		return
	var flash: TweenDefinition = ResourceCore.get_loaded(key, TweenCore.get_preset_kind(), scope) as TweenDefinition
	if flash != null:
		ScreenEffectCore.play_preset(ScreenEffectCore.ScreenEffectChannel.WORLD, self, flash)


## A hit lands at `at`: its burst, and for an attack or a minion card a shockwave ring and a puff of dust and sparks.
func _impact(at: Vector2) -> void:
	var key: String = _burst_key()
	_burst(key, at)
	if key != ResourceKey.PARTICLE__BATTLE__IMPACT:
		return
	_burst(ResourceKey.PARTICLE__BATTLE__SUMMON_BURST, at)
	if _rings.is_empty():
		return
	var ring: Control = _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	ring.position = at - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5
	ring.visible = true
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__IMPACT_RING, scope, ring)


func _burst_key() -> String:
	return ResourceKey.PARTICLE__BATTLE__IMPACT if _hit_burst.is_empty() else _hit_burst


func _play_hit(e: BattleEvent) -> int:
	if e.kind == BattleEvent.Kind.WARD_BREAK:
		var warded: BattleMinionSlot = _slot_of(e.side, e.uid)
		if warded == null:
			return 0
		warded.ward.pivot_offset = warded.ward.size * 0.5
		_impact(warded.center())
		SoundCore.play(ReservedSound.battle_ward_break(), SoundCore.SoundBus.SFX, scope)
		return TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__WARD_BREAK, scope, warded.ward)
	if e.uid == BattleSim.HERO:
		var hero: BattleHeroSlot = own_hero if e.side == BattleSim.PLAYER else enemy_hero
		hero.set_health(e.value, hero.max_health)
		hero.show_number(ReservedString.battle_damage(), e.amount, BattleConstants.DAMAGE_COLOR)
		hero.number_label.pivot_offset = hero.number_label.size * 0.5
		TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__NUMBER_POP, scope, hero.number_label)
		_impact(hero.center())
		SoundCore.play(ReservedSound.battle_hero_hit(), SoundCore.SoundBus.SFX, scope)
		return TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__HIT, scope, hero.body)
	var slot: BattleMinionSlot = _slot_of(e.side, e.uid)
	if slot == null:
		return 0
	slot.set_stats(slot.attack, e.value)
	slot.show_number(ReservedString.battle_damage(), e.amount, BattleConstants.DAMAGE_COLOR)
	slot.number_label.pivot_offset = slot.number_label.size * 0.5
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__NUMBER_POP, scope, slot.number_label)
	_impact(slot.center())
	return TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__HIT, scope, slot.body)


## A death, and the deaths right after it, together; then the rows close up.
func _play_deaths(first: BattleEvent) -> void:
	var dying: Array[BattleEvent] = [first]
	while not _queue.is_empty() and _queue[0].kind == BattleEvent.Kind.DEATH:
		dying.append(_queue[0])
		_queue.remove_at(0)
	var last: int = 0
	for e: BattleEvent in dying:
		var slot: BattleMinionSlot = _slot_of(e.side, e.uid)
		if slot == null:
			continue
		slot.body.pivot_offset = slot.body.size * 0.5
		last = TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__DEATH, scope, slot.body)
	SoundCore.play(ReservedSound.battle_minion_death(), SoundCore.SoundBus.SFX, scope)
	await _wait(last)
	for e: BattleEvent in dying:
		var uids: PackedInt32Array = _own_uids if e.side == BattleSim.PLAYER else _enemy_uids
		var at: int = uids.find(e.uid)
		if at >= 0:
			uids.remove_at(at)
	_rebind_row(BattleSim.PLAYER)
	_rebind_row(BattleSim.CPU)


func _play_heal(e: BattleEvent) -> void:
	var hero: BattleHeroSlot = own_hero if e.side == BattleSim.PLAYER else enemy_hero
	hero.set_health(e.value, hero.max_health)
	var text_key: String = ReservedString.battle_heal()
	if e.amount <= 0:
		text_key = ReservedString.battle_heal_full()
	elif e.amount < e.amount2:
		text_key = ReservedString.battle_heal_capped()
	hero.show_number(text_key, e.amount, BattleConstants.HEAL_COLOR)
	hero.number_label.pivot_offset = hero.number_label.size * 0.5
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__NUMBER_POP, scope, hero.number_label)
	_stat_pop(hero.health_label)
	_burst(ResourceKey.PARTICLE__BATTLE__BUFF_SPARKLE, hero.center())
	SoundCore.play(ReservedSound.battle_heal(), SoundCore.SoundBus.SFX, scope)
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__HEAL_POP, scope, hero.body))


## A buff: the minion swells, `+attack/+health` floats over it and each number it raised pops.
func _play_buff(e: BattleEvent) -> void:
	var slot: BattleMinionSlot = _slot_of(e.side, e.uid)
	if slot == null:
		return
	if e.value2 > slot.max_health:
		slot.max_health = e.value2
	slot.set_stats(e.value, e.value2)
	_format_args.clear()
	_format_args.set_int("attack", e.amount)
	_format_args.set_int("health", e.amount2)
	slot.show_text(LocalizationCore.format(ReservedString.battle_buff_amount(), _format_args), CommonConstants.BUFFED_COLOR)
	slot.number_label.pivot_offset = slot.number_label.size * 0.5
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__NUMBER_POP, scope, slot.number_label)
	if e.amount > 0:
		_stat_pop(slot.attack_label)
	if e.amount2 > 0:
		_stat_pop(slot.health_label)
	_burst(ResourceKey.PARTICLE__BATTLE__BUFF_SPARKLE, slot.center())
	slot.body.pivot_offset = slot.body.size * 0.5
	SoundCore.play(ReservedSound.battle_buff(), SoundCore.SoundBus.SFX, scope)
	await _wait(TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__BUFF_POP, scope, slot.body))


func _stat_pop(label: Label) -> void:
	label.pivot_offset = label.size * 0.5
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__STAT_POP, scope, label)


## The fallen hero breaks: its portrait swells red, tilts and fades while shards fly, the board shakes, and the screen
## flashes warm on a win or dark red on a loss.
func _play_game_over(e: BattleEvent) -> void:
	var broken: Array[BattleHeroSlot] = []
	if e.side != BattleSim.PLAYER:
		broken.append(own_hero)
	if e.side != BattleSim.CPU:
		broken.append(enemy_hero)
	if _sim != null and _sim.conceded:
		broken = [own_hero]
	var last: int = 0
	for hero: BattleHeroSlot in broken:
		hero.body.pivot_offset = hero.body.size * 0.5
		hero.number_label.visible = false
		last = TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__HERO_BREAK, scope, hero.body)
		_burst(ResourceKey.PARTICLE__BATTLE__HERO_SHATTER, hero.center())
	SoundCore.play(ReservedSound.battle_hero_hit(), SoundCore.SoundBus.SFX, scope)
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__BOARD_SHAKE, scope, shake_root)
	var flash_key: String = ResourceKey.TWEEN__BATTLE__VICTORY_FLASH if e.side == BattleSim.PLAYER \
		else ResourceKey.TWEEN__BATTLE__DEFEAT_FLASH
	var flash: TweenDefinition = null
	if ResourceCore.is_loaded(flash_key, TweenCore.get_preset_kind()):
		flash = ResourceCore.get_loaded(flash_key, TweenCore.get_preset_kind(), scope) as TweenDefinition
	if flash != null and broken.has(own_hero) != broken.has(enemy_hero):
		ScreenEffectCore.play_preset(ScreenEffectCore.ScreenEffectChannel.WORLD, self, flash)
	await _wait(last)
	if not is_inside_tree():
		return
	_show_end_banner(e.side == BattleSim.PLAYER)


## The end of the battle in big letters over the board, with the player's hero: it pops in and stays until the
## result panel covers it.
func _show_end_banner(won: bool) -> void:
	summary_root.visible = false
	LocalizationCore.bind_text(end_banner_label, ReservedString.battle_end_victory() if won else ReservedString.battle_end_defeat())
	end_banner_label.modulate = BattleConstants.WIN_COLOR if won else BattleConstants.LOSE_COLOR
	end_banner_portrait.texture = own_hero.portrait.texture
	end_banner_portrait.modulate = Color.WHITE if won else BattleConstants.LOST_PORTRAIT_COLOR
	end_banner.pivot_offset = end_banner.size * 0.5
	end_banner.visible = true
	TweenCore.play_preset(ResourceKey.TWEEN__BATTLE__END_BANNER, scope, end_banner)


## Starts the next instance of the particle `key` at `at` in board coordinates.
func _burst(key: String, at: Vector2) -> void:
	var count: int = _burst_count.get(key, 0)
	if count == 0:
		return
	var index: int = _burst_next[key]
	_burst_next[key] = (index + 1) % count
	var particles: GPUParticles2D = _bursts[_burst_first[key] + index]
	if not is_instance_valid(particles):
		return
	particles.position = at
	particles.scale = Vector2.ONE * (BattleConstants.IMPACT_BURST_SCALE if key == ResourceKey.PARTICLE__BATTLE__IMPACT else 1.0)
	particles.restart()
	particles.emitting = true


## Waits for the tween `handle` to end. An invalid handle ends at once.
func _wait(handle: int) -> void:
	if handle == 0:
		return
	await TweenCore.wait_end(handle)


func _rebind_row(side: int) -> void:
	if side == BattleSim.PLAYER:
		_bind_row_from_display(side, _own_uids, _own_slots)
	else:
		_bind_row_from_display(side, _enemy_uids, _enemy_slots)
	_layout_row(side)


## Binds the slots to the drawn uids. A uid the battle no longer has (it died later in the queue) keeps the stats of
## its card until its death plays.
func _bind_row_from_display(side: int, uids: PackedInt32Array, slots: Array[BattleMinionSlot]) -> void:
	var places: PackedInt32Array = _places(side)
	BattleBoardPanel._assign_places(places, uids)
	for i: int in slots.size():
		var slot: BattleMinionSlot = slots[i]
		var uid: int = places[i]
		if uid == 0:
			slot.visible = false
			continue
		if slot.visible and slot.uid == uid:
			continue
		slot.visible = true
		var m: BattleMinion = _sim.sides[side].minion(uid)
		if m != null:
			slot.show_minion(m.uid, m.card_id, m.attack, m.health, m.max_health, m.guard, m.ward,
				m.sleeping and side == BattleSim.PLAYER, scope)
		else:
			_bind_gone(slot, uid)
		slot.glow.visible = false


## A slot of a minion that already died in the battle: drawn with the card stats of the slot that showed it.
func _bind_gone(slot: BattleMinionSlot, uid: int) -> void:
	var other: BattleMinionSlot = _shown_slot(_own_slots, slot, uid)
	if other == null:
		other = _shown_slot(_enemy_slots, slot, uid)
	if other == null:
		return
	var row: GameData.CardRow = GameData.CardTable.get_row(other.card_id)
	slot.show_minion(uid, other.card_id, row.attack, row.health, row.health, row.guard, false, false,
		scope)


func _shown_slot(slots: Array[BattleMinionSlot], except: BattleMinionSlot, uid: int) -> BattleMinionSlot:
	for other: BattleMinionSlot in slots:
		if other != except and other.uid == uid:
			return other
	return null


func _slot_of(side: int, uid: int) -> BattleMinionSlot:
	var slots: Array[BattleMinionSlot] = _own_slots if side == BattleSim.PLAYER else _enemy_slots
	var at: int = _places(side).find(uid)
	if at < 0 or at >= slots.size():
		return null
	return slots[at]


## The center of a character on the board. The rows and the heroes share the board coordinates.
func _center_of(side: int, uid: int) -> Vector2:
	if uid == BattleSim.HERO:
		return (own_hero if side == BattleSim.PLAYER else enemy_hero).center()
	var slot: BattleMinionSlot = _slot_of(side, uid)
	return Vector2.ZERO if slot == null else slot.center()


