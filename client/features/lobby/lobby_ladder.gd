class_name LobbyLadder
extends RefCounted
## The opponent ladder rule the lobby shows: which opponents are open.


## Whether the opponent of ladder `order` is open: the first one always, any other once the one before it is beaten.
# ogw:shared lobby.opponent_unlocked
static func opponent_unlocked(order: int, cleared_orders: PackedInt32Array) -> bool:
	return order <= 1 or cleared_orders.has(order - 1)


static func is_open(opponent_id: int) -> bool:
	return opponent_unlocked(GameData.OpponentTable.get_row(opponent_id).order, CommonProgress.cleared_orders())
