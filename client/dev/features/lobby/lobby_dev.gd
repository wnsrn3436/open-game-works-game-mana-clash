class_name LobbyDev
extends RefCounted
## DEV registration of the lobby feature: the screen commands and the record invariant.


static func register() -> void:
	QACore.register_command("lobby.open_lobby", "Opens the lobby scene with its root panel on top.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await LobbyDev.open_lobby())
	QACore.register_command("lobby.open_deck", "Opens the deck panel over the lobby.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await LobbyDev.open_over_lobby(ResourceKey.PREFAB__LOBBY__DECK_PANEL))
	QACore.register_command("lobby.open_option", "Opens the option panel over the lobby.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await LobbyDev.open_over_lobby(ResourceKey.PREFAB__LOBBY__OPTION_PANEL))
	QACore.register_invariant("lobby.record_not_negative", func() -> bool: return LobbyDev.record_not_negative())


static func open_lobby() -> RunCommandResult:
	UICore.close_all_popups()
	if SceneCore.current_scene_key() != ResourceKey.SCENE__LOBBY__LOBBY:
		if not await SceneCore.change_scene(ResourceKey.SCENE__LOBBY__LOBBY, null):
			return _result(false)
	return _result(await UICore.close_panels_to(ResourceKey.PREFAB__LOBBY__LOBBY_PANEL))


static func open_over_lobby(panel_key: String) -> RunCommandResult:
	var lobby: RunCommandResult = await open_lobby()
	if not lobby.ok:
		return lobby
	return _result(await UICore.open_panel(panel_key, null, false))


static func record_not_negative() -> bool:
	return CommonProgress.wins() >= 0 and CommonProgress.losses() >= 0 and CommonProgress.win_streak() >= 0 \
		and CommonProgress.win_streak() <= CommonProgress.wins()


static func _result(ok: bool) -> RunCommandResult:
	var out: RunCommandResult = RunCommandResult.new()
	out.ok = ok
	out.result = "" if ok else "\"the screen did not open\""
	return out
