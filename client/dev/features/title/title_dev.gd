class_name TitleDev
extends RefCounted
## DEV registration of the title feature: the screen command.


static func register() -> void:
	QACore.register_command("title.open_title", "Opens the title scene.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await TitleDev.open_title())


static func open_title() -> RunCommandResult:
	UICore.close_all_popups()
	var out: RunCommandResult = RunCommandResult.new()
	out.ok = SceneCore.current_scene_key() == ResourceKey.SCENE__TITLE__TITLE \
		or await SceneCore.change_scene(ResourceKey.SCENE__TITLE__TITLE, null)
	out.result = "" if out.ok else "\"the title scene did not open\""
	return out
