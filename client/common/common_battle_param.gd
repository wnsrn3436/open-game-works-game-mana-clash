class_name CommonBattleParam
extends RefCounted
## Param of the battle scene: the opponent to fight. Without it the battle is against the next opponent of the ladder.

var opponent_id: int = 0


static func of(id: int) -> CommonBattleParam:
	var out: CommonBattleParam = CommonBattleParam.new()
	out.opponent_id = id
	return out
