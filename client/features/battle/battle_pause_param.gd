class_name BattlePauseParam
extends UIParam
## Param of the pause popup: what the battle does after the popup closed.

var on_resume: Callable = Callable()
var on_concede: Callable = Callable()
