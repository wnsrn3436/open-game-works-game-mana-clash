extends UnitTestCase
## The ladder balance with `BattleAi` on both sides: the first opponent is easy, and every battle ends before the
## turn limit. Prints the bot win rate and median turns of each opponent.

const _SEEDS: int = 40
const _ACTION_LIMIT: int = 5000


func before_each() -> void:
	super()
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func test_every_opponent_battle_ends_and_the_first_one_is_easy() -> void:
	for row: GameData.OpponentRow in GameData.OpponentTable.all_rows():
		var wins: int = 0
		var turns: PackedInt32Array = PackedInt32Array()
		for seed_value: int in range(1, _SEEDS + 1):
			var sim: BattleSim = BattleSimRunner.new_battle(row.id, seed_value)
			BattleSimRunner.play_out(sim, _ACTION_LIMIT)
			assert_true(sim.over, "battle %d of %s ended" % [seed_value, GameDataDev.find_id_name(row.id)])
			if sim.winner == BattleSim.PLAYER:
				wins += 1
			turns.push_back(sim.turn)
		turns.sort()
		print("balance %s: bot wins %d/%d, median turns %d" % [GameDataDev.find_id_name(row.id), wins, _SEEDS,
			turns[UtilCore.floor_div(_SEEDS - 1, 2)]])
		if row.order == 1:
			assert_gt(wins * 1000, _SEEDS * 850, "the first opponent loses to the bot most of the time")
