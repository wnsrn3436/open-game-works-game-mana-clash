class_name ContentBoot
extends ContentEntry
## Content entry of the game. The game registers no core hook. A user without a finished battle starts in the battle
## against the first opponent instead of the lobby, so the first play needs no start press.


func content_init() -> bool:
	return true


func content_release() -> void:
	pass


func select_first_scene() -> String:
	if CommonProgress.battles() == 0:
		return ResourceKey.SCENE__BATTLE__BATTLE
	return BootstrapCore.get_first_scene()
