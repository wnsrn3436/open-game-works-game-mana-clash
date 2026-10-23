class_name CommonProgress
extends RefCounted
## The ladder progress and record of the user, read from the `ProgressUserState` cache. Before the first finished
## battle there is no row: no wins, no losses, nothing cleared, and the deck is the `[starter_deck]` row.


static func wins() -> int:
	var state: GameContract.ProgressUserState = _state()
	return 0 if state == null else state.wins


static func losses() -> int:
	var state: GameContract.ProgressUserState = _state()
	return 0 if state == null else state.losses


static func win_streak() -> int:
	var state: GameContract.ProgressUserState = _state()
	return 0 if state == null else state.win_streak


static func battles() -> int:
	return wins() + losses()


static func is_cleared(opponent_id: int) -> bool:
	var state: GameContract.ProgressUserState = _state()
	return state != null and state.cleared_opponent_ids.has(opponent_id)


## The `order` of every beaten opponent.
static func cleared_orders() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var state: GameContract.ProgressUserState = _state()
	if state == null:
		return out
	for id: int in state.cleared_opponent_ids:
		if GameData.OpponentTable.has_row(id):
			out.push_back(GameData.OpponentTable.get_row(id).order)
	return out


## The player deck: card ID values, one per copy.
static func deck() -> PackedInt32Array:
	var state: GameContract.ProgressUserState = _state()
	if state != null and not state.deck_card_ids.is_empty():
		return state.deck_card_ids
	return GameData.DeckTable.get_row(ReservedId.starter_deck()).cards


## The opponents in ladder order.
static func opponents() -> Array[GameData.OpponentRow]:
	var rows: Array[GameData.OpponentRow] = GameData.OpponentTable.all_rows().duplicate()
	rows.sort_custom(CommonProgress._before)
	return rows


## The first opponent in ladder order not beaten yet, or the last one when all are beaten.
static func next_opponent() -> int:
	var rows: Array[GameData.OpponentRow] = opponents()
	for row: GameData.OpponentRow in rows:
		if not is_cleared(row.id):
			return row.id
	return 0 if rows.is_empty() else rows[rows.size() - 1].id


## Whether every opponent is beaten.
static func all_cleared() -> bool:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		if not is_cleared(row.id):
			return false
	return true


static func _before(a: GameData.OpponentRow, b: GameData.OpponentRow) -> bool:
	return a.order < b.order


static func _state() -> GameContract.ProgressUserState:
	return UserStateCore.get_single(GameContract.ProgressUserState) as GameContract.ProgressUserState
