extends UnitTestCase
## The opponent ladder rule (shared formula `lobby.opponent_unlocked`) gives the result of every case of its fixture.
## Each fixture case is one line: `{"name": ..., "input": {"order": n, "cleared_orders": [..]}, "expected": bool}`.

const _CASE: String = "\"name\": \"([^\"]*)\", \"input\": \\{\"order\": (\\d+), \"cleared_orders\": \\[([\\d, ]*)\\]\\}, \"expected\": (true|false)"


func test_opponent_unlocked_matches_the_shared_fixture() -> void:
	var text: String = UnitTestCore.read_shared_fixture("lobby.opponent_unlocked")
	var pattern: RegEx = RegEx.create_from_string(_CASE)
	var matches: Array[RegExMatch] = pattern.search_all(text)
	assert_gt(matches.size(), 0, "the fixture has cases")
	assert_eq(matches.size(), text.count("\"name\""), "every case of the fixture is read")
	for found: RegExMatch in matches:
		var cleared: PackedInt32Array = PackedInt32Array()
		for part: String in found.get_string(3).split(",", false):
			cleared.push_back(part.strip_edges().to_int())
		var expected: bool = found.get_string(4) == "true"
		assert_eq(LobbyLadder.opponent_unlocked(found.get_string(2).to_int(), cleared), expected, found.get_string(1))
