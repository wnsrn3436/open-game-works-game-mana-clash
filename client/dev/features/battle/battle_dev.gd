class_name BattleDev
extends RefCounted
## DEV registration of the battle feature: the bot, the screen commands, the row simulation, the invariants, the
## content state and the telemetry marks. The lambdas hold the one `BattleBot` of this boot until QACore releases them.


static func register() -> void:
	var bot: BattleBot = BattleBot.new()
	QACore.register_command("battle.bot_next_input", "Returns the next input of the bot player: start, play, attack, end turn, next.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return bot.next_input(args))
	QACore.register_command("battle.open_battle", "Opens the battle scene against the next opponent; a new battle starts.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return await bot.open_battle(args))
	QACore.register_command("battle.open_result", "Opens the result panel of a won first battle with its reward cards.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return await bot.open_result(args))
	QACore.register_command("battle.open_reward", "Opens the full screen reward of a won first battle before its result.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return await bot.open_reward(args))
	QACore.register_command("battle.open_defeat", "Opens the result panel of a lost battle with its tip and the cards a win adds.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return await bot.open_defeat(args))
	QACore.register_command("battle.open_pause", "Opens the pause popup over a running battle.", PackedStringArray(),
		func(args: PackedStringArray) -> RunCommandResult: return await bot.open_pause(args))
	QACore.register_command("battle.simulate_opponent", "Plays one battle against the opponent row with the seed, bot against CPU.",
		PackedStringArray(["opponent", "seed"]), func(args: PackedStringArray) -> RunCommandResult: return bot.simulate_opponent(args))
	QACore.register_invariant("battle.limits_hold", func() -> bool: return bot.limits_hold())
	QACore.register_invariant("battle.minions_alive", func() -> bool: return bot.minions_alive())
	QACore.set_content_state(func() -> String: return BattleDev.content_state())
	EventCore.subscribe(BattleFinishedEvent, bot.on_finished)
	EventCore.subscribe(BattleStartedEvent, bot.on_started)
	EventCore.subscribe(BattleRewardShownEvent, bot.on_reward)
	EventCore.subscribe(BattleRespondedEvent, bot.on_responded)


## The stored progress: what a restart keeps.
static func content_state() -> String:
	return JSON.stringify({
		"wins": CommonProgress.wins(),
		"losses": CommonProgress.losses(),
		"win_streak": CommonProgress.win_streak(),
		"cleared": CommonProgress.cleared_orders().size(),
		"deck": CommonProgress.deck().size(),
	})
