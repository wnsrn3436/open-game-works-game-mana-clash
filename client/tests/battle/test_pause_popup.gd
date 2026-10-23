extends UnitTestCase
## The pause popup: resume closes it, and giving up asks once more before the battle is lost.

var _resumes: int = 0
var _concedes: int = 0


func before_each() -> void:
	super()
	_resumes = 0
	_concedes = 0


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


## Inits the modules the popup uses in module list order, loads the data and translation and prepares the UI.
func prepare_ui() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(UserStateCore.init(), "UserStateCore.init")
	assert_true(ResolutionCore.init(), "ResolutionCore.init")
	assert_true(SafeAreaCore.init(), "SafeAreaCore.init")
	assert_true(InputBlockCore.init(), "InputBlockCore.init")
	assert_true(InputCore.init(), "InputCore.init")
	assert_true(LocalizationCore.init(), "LocalizationCore.init")
	assert_true(SoundCore.init(), "SoundCore.init")
	assert_true(TweenCore.init(), "TweenCore.init")
	assert_true(UICore.init(), "UICore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")


func open_popup() -> void:
	var param: BattlePauseParam = BattlePauseParam.new()
	param.on_resume = func() -> void: _resumes += 1
	param.on_concede = func() -> void: _concedes += 1
	UICore.open_popup(ResourceKey.PREFAB__BATTLE__PAUSE_POPUP, param, Callable())
	await UnitTestCore.wait_frames(30)


func find_popup(node: Node) -> BattlePausePopup:
	if node is BattlePausePopup:
		return node as BattlePausePopup
	for child: Node in node.get_children():
		var found: BattlePausePopup = find_popup(child)
		if found != null:
			return found
	return null


func test_concede_asks_once_more_before_the_battle_is_lost() -> void:
	await prepare_ui()
	await open_popup()
	assert_true(UnitTestCore.tap_anchor("pause_concede"), "tap concede")
	await UnitTestCore.wait_frames(30)
	assert_eq(_concedes, 0, "the first tap does not give up")
	var popup: BattlePausePopup = find_popup(UICore.get_layer(UICore.UILayer.POPUP))
	assert_not_null(popup, "the popup is still open")
	if popup != null:
		assert_true(popup.confirm_label.visible, "it asks to confirm")
	UnitTestCore.advance_clock(1000, false)
	assert_true(UnitTestCore.tap_anchor("pause_concede"), "tap concede again")
	await UnitTestCore.wait_frames(30)
	assert_eq(_concedes, 1, "the second tap gives up once")
	assert_eq(_resumes, 0)


func test_resume_after_the_question_keeps_the_battle() -> void:
	await prepare_ui()
	await open_popup()
	assert_true(UnitTestCore.tap_anchor("pause_concede"), "tap concede")
	await UnitTestCore.wait_frames(30)
	UnitTestCore.advance_clock(1000, false)
	assert_true(UnitTestCore.tap_anchor("pause_resume"), "tap resume")
	await UnitTestCore.wait_frames(30)
	assert_eq(_resumes, 1, "the battle goes on")
	assert_eq(_concedes, 0, "no surrender")
