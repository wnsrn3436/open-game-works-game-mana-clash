class_name BattleResultParam
extends UIParam
## Param of the result panel: the finished battle, the record after it, the first-win reward and the ways on.

var won: bool = false
## The server counted the battle.
var saved: bool = false
var opponent_id: int = 0
var turns: int = 0
var wins: int = 0
var losses: int = 0
var win_streak: int = 0
## Cards this first win added to the deck; empty otherwise.
var reward_cards: PackedInt32Array = PackedInt32Array()
## Cards this first win took out of the deck, one per added card; empty otherwise.
var swap_out_cards: PackedInt32Array = PackedInt32Array()
## After a loss to an opponent not beaten yet: the cards a first win over it adds. Empty otherwise.
var stake_cards: PackedInt32Array = PackedInt32Array()
## After a loss: the translation key of the opponent's tip. Empty otherwise.
var tip: String = ""
## The opponent this win opened, or 0.
var next_opponent: int = 0
## This win beat the last opponent of the ladder for the first time.
var all_cleared: bool = false
## Called after the panel closed for a new battle with the same opponent.
var on_retry: Callable = Callable()
## Called after the panel closed for a battle with `next_opponent`.
var on_next: Callable = Callable()
## Called for the lobby.
var on_lobby: Callable = Callable()
