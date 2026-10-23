## overview

- Genre: single-player turn-based card battle (against the CPU)
- One-line pitch: a short card duel that climbs a ladder of three CPU duelists with 20 minion and spell cards, where new cards enter the deck with each win
- Target platform: macOS (game settings `buildPlatforms`). mouse
- screen orientation: landscape
- base resolution: 1920x1080

## core loop

1. Choose an opponent in the lobby, then `대전 시작` (Start match) (on first launch, the first match starts at once without the lobby)
2. Match: each of my turns adds one mana crystal (up to `[max_mana]`) and draws one card. Spend mana to play minions and spells, attack with awake minions, then `턴 종료` (End Turn). On the CPU turn, the CPU moves while showing one action at a time
3. When one hero's health reaches 0, the match ends and the result is saved to the server. For an opponent beaten for the first time, that opponent's reward cards enter the deck and the next opponent opens
4. On the result screen, one of `다음 상대` (Next opponent), `다시 도전` (Challenge again) and `로비로` (To lobby) returns to 1 or 2

- Target duration of one match: practice opponent 120000ms~420000ms, other opponents 240000ms~720000ms
- Target duration of one of my turns: 10000ms~60000ms

## controls

| input | action | result |
|---|---|---|
| hand card click | play a card | On my turn, a card that can be played now has a thick green glowing border, and a card that cannot be played has dark art. A card that needs no target is played at once. A card that needs a target (`마나 화살` (Mana Bolt), `번개 창` (Lightning Lance), `수호의 축복` (Guardian's Blessing)) becomes selected, and the card rises and grows a little. Pressing the same card again cancels |
| target click (hero, minion) | choose a target | The selected card or the attacking minion goes to that target. Whatever can be a target has a red border |
| my minion click | choose an attacker | A minion that can attack (green border) is selected with a yellow border. Pressing it again cancels |
| empty board spot click | cancel the selection | |
| `턴 종료` (End Turn) button click | pass the turn | The CPU turn starts. When there is nothing more to do, the button glows green and its text is green too |
| `일시정지` (Paused) button, `Esc` (back) | pause popup | `계속하기` (Resume), `항복하기` (Concede) |
| button click on the lobby and result screens | screen change | |

- Differences per platform: none (only macOS is a target)
- Dragging (drag) is not used

## screens

| scene | content | next |
|---|---|---|
| `scene/title/title` | Game name and tagline during boot. For a new user, the terms popup `prefab/common/terms_popup` | After login, a user with no finished match (wins + losses in `ProgressUserState` are 0) goes to `scene/battle/battle` (first opponent); any other user goes to `scene/lobby/lobby` |
| `scene/lobby/lobby` | root panel `prefab/lobby/lobby_panel`: game name, record, win streak or ladder completion line, my hero portrait, selected opponent line, `대전 시작` (Start match), `내 덱` (My Deck) (deck card count), `설정` (Settings), and on the right the opponent ladder (portrait, name, one-line description, hero health, `승리함` (Won)/`도전 가능` (Ready to challenge)/`앞 상대를 이기면 열려요` (Opens when you beat the previous opponent)). Deck panel `prefab/lobby/deck_panel`, settings panel `prefab/lobby/option_panel` | `대전 시작` → `scene/battle/battle` (selected opponent) |
| `scene/battle/battle` | root panel `prefab/battle/board_panel` over the board background: the enemy hero at top center, to its right the enemy card backs fanned out and the hand count, the upper and lower boards in the middle (5 slots each; above the golden center line of the board art is the enemy row, below it is my row, and the rows do not overlap the line), my hero at the bottom left (name plate above the portrait), the hand at bottom center, enemy mana and deck at the top right, `턴 종료` (End Turn) at the right middle, my mana crystals and deck at the bottom right, `일시정지` (Paused) and the turn count at the top left, the `지난 상대 차례` (Last opponent turn) summary below them, and at the left middle the hint line (first match only) and the turn start display (they do not overlap the minion slots of the board). Result panel `prefab/battle/result_panel`, pause popup `prefab/battle/pause_popup` | `로비로` (To lobby) on the result → `scene/lobby/lobby` |

- While a match starts: until the server answers `StartPlaySession`, `대전 준비 중` (Getting the match ready) shows and the board is empty. On failure, core shows an error and goes to the lobby
- Press response: a card, minion, hero or the `턴 종료` button pressed on the board dips slightly and pops back up the moment it is pressed (`tween/battle/press_pop`)
- Input during animation: on my turn, presses on the board (hand card, minion, hero, `턴 종료`, empty spot) while an animation (card reveal, attack, numbers) runs are all remembered in the order pressed (at most `BattleConstants.HELD_PRESS_LIMIT`) and run one by one when the animation ends. When a press that runs starts a new animation, the rest run after that animation ends. A hand press plays the card that was shown at that position at the moment of the press (the same card even when an earlier press shifted the hand). When my turn ends, the remaining presses are discarded. Pressing the board on the CPU turn shows `상대 차례예요. 잠시 기다려 주세요` (It's the opponent's turn. Please wait) like a refusal
- Refusal: when mana is short, the board is full, there is no target, the minion cannot attack this turn, or something else is attacked while there is a Guard minion, an error sound plays and the reason pops out large in a name plate shape right above what was pressed (beside it when above is the screen edge; beside the portrait when it would cover a hero portrait) and disappears after about 1.4 seconds (`tween/battle/refusal_pop`). The pressed card or minion shakes left and right (`tween/battle/refuse_shake`), when mana is short the mana number flashes red (`tween/battle/mana_flash`), and when Guard is the cause the silver frame of the enemy Guard minion swells
- Minion positions: a minion keeps the position (slot and anchor number) it got when it landed on the board until it dies. When a minion on the left dies and the row gathers to the middle, the numbers of the remaining minions stay the same. A new minion gets the empty position to the right of the used positions. When my turn starts, the numbers are assigned again from the left
- Duplicate input: result screen buttons accept only the first press. The lobby `대전 시작` (Start match) also changes scene only once
- First win reward: for an opponent beaten for the first time, before the result screen the whole screen darkens (`tween/battle/fade_in`) and `새 카드를 얻었어요!` (You got a new card!) pops out, and while a large golden oval ring behind the card row (`image/battle/minion_glow`) glows as if breathing, the three reward cards flip out one at a time at 1.5 times the size of a hand card (`tween/battle/reward_reveal`; for each card, a golden oval ring that wraps the card from behind spreads and fades `tween/battle/reward_burst`. No square frame is used). When all are out, `아무 곳이나 눌러 계속하기` (Tap anywhere to continue) blinks. Pressing during the flips shows all at once, and pressing after all are shown closes it and the result screen appears
- Result screen: for an opponent beaten for the first time, the three reward cards lie in a row, under it the cards leaving the deck (`opponent.reward_removes`; the same card is grouped by count) appear in one line, and when there is a newly opened opponent, `다음 상대` (Next opponent) has the first focus. On a loss, the opponent's one-line tip (`opponent.tip`) shows under the record, and for an opponent not yet beaten, `이기면 이 카드가 덱에 들어와요` (Win to add this card to your Deck) and that opponent's three reward cards appear in turn (this is not a reward display). Otherwise `다시 도전` (Challenge again) has the first focus. Back input is `로비로` (To lobby). For a result that was not saved (play session expired, ended too fast, play session unknown to the server), the record line is `이번 대전은 전적에 넣지 못했어요 (...)` (This match couldn't be added to your record (...))
- Pause popup: game time stops, so the CPU does not move. Pressing `항복하기` (Concede) the first time shows `항복하면 이 대전은 패배로 끝나요. 정말 항복할까요?` (Conceding ends this match in a defeat. Concede anyway?) and the button changes to `네, 항복할게요` (Yes, concede). Pressing that ends the match in a defeat and sends the result. Back input is `계속하기` (Resume)
- Opponent turn summary: from my second turn on, when my turn starts it shows, one per line, the cards the opponent played in the previous opponent turn (when there are none, `상대는 카드를 내지 않았어요` (The opponent played no cards)), the total damage my hero took, the total damage my minions took, the number of my minions that fell, the number of enemy minions that fell and the health the enemy hero restored (lines with 0 are left out; my losses in red, the opponent's losses in gold, healing in green). It hides when the opponent's turn starts
- `턴 종료` (End Turn) button: can be pressed only on my turn. On the CPU turn its text is `상대 차례` (Opponent's turn), and before the match starts and after the match ends it is disabled with the `턴 종료` text
- Match end display: after the fallen hero shatters, my hero portrait and `승리!` (Victory!) or `패배!` (Defeat!) pop out in the middle of the board and stay until the result screen covers them. Pressing the board during that time makes the display dip and pop and skips the remaining wait (`[game_over_delay]`)
- Pressing a locked opponent in the lobby shows the `앞 상대를 이기면 열려요` (Opens when you beat the previous opponent) toast. Back input on the root panel opens the quit confirmation

## systems

### battle rules

- Hero health of each side: player `[hero_health]`, opponent `opponent.hero_health`. A deck has `[deck_size]` cards and is shuffled with a seed at match start (`play_session_simulation`, `seed` of the loadout)
- The player always goes first. Starting hand: player `[start_hand_first]` cards, CPU `[start_hand_second]` cards. When the starting hand has no minion of mana `[opening_cheap_cost]` or less, the first such minion in the deck comes in. When the deck has no such minion, the same is done with a card (a spell) of that cost or less (when one is already in the hand, nothing changes). After that, when the hand has fewer than two minions of mana `[opening_curve_cost]` or less, one more such minion, the first in the deck, comes in. An incoming card takes the place of the most expensive hand card that this rule does not keep (on a tie, the earlier one), and that card goes to the bottom of the deck. So both sides have minions to play on the first two turns (mana 1, 2). Every deck (the starter deck, decks after ladder rewards, opponent decks) holds a minion of mana 1 or less and two or more minions of mana 2 or less
- Turn start: max mana +1 (cap `[max_mana]`), mana refills fully, that side's minions wake up (1 attack), and one card is drawn. When the deck is empty, each draw deals 1, 2, 3... damage (fatigue). When the hand has `[hand_size]` cards, the drawn card burns
- Playing a card: spends mana equal to its cost. A minion is placed at the right end of the board (board of `[board_size]` slots) and, without Charge, cannot attack that turn
- Attack: an awake minion hits an enemy minion or the enemy hero. Two minions deal damage to each other equal to each one's attack. When the enemy board has a Guard minion, only Guard minions can be attacked
- Ward: blocks the next single instance of damage that minion takes, then disappears
- Heal: hero health rises up to max health. A heal on a hero already at full health also stays as a heal of 0, and `체력 가득` (Full health) appears on screen. A heal event carries both the amount filled and the original heal amount
- A minion with health 0 or less dies (player side first, in board order). On Death effects run after the death
- Win and loss: enemy hero health 0 is a win, my hero health 0 is a loss, and when both reach 0 together or the match goes past `[max_turns]` turns, it ends in a loss. Conceding is also a loss
- Card effects (`card.effect`, `card.trigger`, `card.amount`, `card.amount2`): `DamageTarget` damage to a chosen character, `DamageEnemyHero` damage to the enemy hero, `DamageAllEnemyMinions` damage to all enemy minions, `HealOwnHero` heals my hero (up to max health), `DrawCards` draws cards, `BuffFriendlyMinion` +attack/+health to a chosen friendly minion, `BuffOtherFriendlyAttack` +attack to all my other minions. There are no random-target effects
- 20 cards: `card` table (15 minions, 5 spells). Keywords `card.guard` (Guard), `card.charge` (Charge), `card.ward` (Ward)
- Every formula is integer. shared formula: `lobby.opponent_unlocked` (opponent ladder unlock, `### ladder` below)

### CPU

- `BattleAi` (client simulation, deterministic): sees only its own hand, both boards and both heroes
  1. When it can end the match this turn (direct damage cards, total attack when there is no Guard), it does so
  2. Plays the useful card with the largest cost (on a tie, minions first). Targeted damage goes to the most valuable enemy minion it can kill (when there is none, to the hero only when the hand has more than `[ai_draw_hand_limit]` cards), an area spell is used when it kills `[ai_area_kills]` or more minions, a draw spell when the hand has fewer than `[ai_draw_hand_limit]` cards, and a buff on its strongest own minion
  3. Attack: when there is a Guard, the Guards it can kill first; otherwise trades that kill and survive, then trades that kill a threat with attack `[ai_threat_attack]` or more, and otherwise it hits the hero
- Going for the hero (an opponent whose `opponent.ai_face` is `true`, the practice opponent): does not make the trades of 3, only trades that kill a threat with attack `[ai_threat_attack]` or more. Targeted damage spells go to the hero even when there is a minion to kill. So my hero's health drops even in the first match
- The CPU turn starts after `[cpu_turn_start_delay]` and pauses `[cpu_action_delay]` per action. When the match ends, the result is saved after `[game_over_delay]`

### ladder

- Opponents: `opponent` table. In the order of `order`: the practice opponent (`수련생 미로` (Miro the Trainee), hero health 14), `숲의 파수꾼 타라` (Tara the Forest Warden), `대마법사 벨로크` (Velloch the Archmage)
- Unlock (shared formula `lobby.opponent_unlocked`): an opponent opens when its `order` is 1 or when the opponent with `order` − 1 has been beaten. The client lobby and the server `prepare_play_session` use the same rule
- First win reward: beating that opponent for the first time puts the cards of `opponent.reward_cards` one by one into the places of the cards of `opponent.reward_removes` (the deck card count stays the same). Winning again gives no reward
- Deck: `ProgressUserState.deck_card_ids`. Before the first reward it is the `[starter_deck]` row
- Difficulty curve (row simulation; the bot plays with the deck it has when it reaches that opponent, by the same rules as the CPU): bot win rate 850‰ or more against the practice opponent, 400‰~900‰ against the Forest Warden, 300‰~800‰ against the Archmage. Match turn count: 5~14 turns against the practice opponent, 10~24 turns against the rest. In a match against the practice opponent, my hero at its lowest is 6 or more below max health (`damage_peak`, the tension of the first match). The targets are the `sim_` columns of `opponent`

### battle session

- A match is one `play-session` run. The mode is reserved ID `[battle_mode]` → `[mode_battle]` of `play_session_mode`, and `level_id` is the opponent's ID value. There is no pre-match choice and no continue (`max_continue_count` 0)
- `prepare_play_session`: `GAME_ERROR_OPPONENT_NOT_FOUND` when there is no opponent row, `GAME_ERROR_OPPONENT_LOCKED` for a locked opponent. loadout `PlaySessionLoadout`: opponent ID, player deck, opponent deck, seed (server random)
- Result `PlaySessionResult`: `won`, `conceded`, `turns`, `player_health`, `opponent_health`, `cards_played`. Upper bounds of the result values: `turns` is `game_setting.max_turns`, `player_health` is `game_setting.hero_health`, `opponent_health` is `opponent.hero_health`, `cards_played` is `game_setting.deck_size`
- `verify_play_session`: checks the upper bounds above, and that a win has opponent health 0, my health 1 or more and no concession, and a loss has one of my health 0, a concession or the turn limit. It does not verify the result by calculating it again. No ranking board takes a result value as a score. The reward is the cards set in the opponent row, not a quantity from the result values
- `apply_play_session`: applies to `ProgressUserState` the win or loss, the win streak, and on a first win the beaten opponent and the reward cards

## progression

- unlock order: practice opponent → Forest Warden → Archmage (`opponent.order`)
- Deck growth: each time an opponent is beaten for the first time, three different reward cards enter the deck, and as many cards of `opponent.reward_removes` leave it (practice opponent: `번개 창` (Lightning Lance), `새벽 기사` (Dawn Knight), `통찰` (Insight) ↔ `불씨 도깨비` (Ember Imp), `이끼 방패병` (Moss Guard) 2 / Forest Warden: `화염 폭풍` (Firestorm), `전쟁 북잡이` (War Drummer), `화염 비룡` (Flame Wyvern) ↔ `질풍 사냥개` (Gale Hound), `수정 거북` (Crystal Turtle), `약초 치유사` (Herb Healer) / Archmage: `하늘 거신` (Sky Colossus), `잿빛 망령` (Ash Wraith), `고목 수호자` (Elder Treant) ↔ `질풍 사냥개` (Gale Hound), `견습 학자` (Apprentice Scholar) 2)
- tutorial step: none of its own. In the first match (0 finished matches), the hint line on the left of the board tells what can be done at that moment: play a card → choose a target → attack with a minion → attack target → end turn. The hints for playing a card, attacking and ending the turn do not appear again once the player has done that action in that match (`BattleHint`). The target choice hint appears whenever something is selected

## economy

none

## new user

- Initial state: there is no `ProgressUserState` (record 0 wins 0 losses, deck is `[starter_deck]`). No initial state is created by a server request
- First launch: when login finishes after the terms popup, the first match against the practice opponent opens without the lobby. Until one match is finished, launching again also opens a match first

## feel targets

| metric | min | max | data |
|---|---|---|---|
| `input_latency_ms` | 0 | 100 | |
| `no_response_permille` | 0 | 150 | |
| `first_reward_ms` | 60000 | 600000 | `opponent.hero_health` |
| `restart_delay_ms` | 500 | 20000 | |
| `scene_load_ms` | 0 | 3000 | |

## tuning targets

| metric | min | max | data |
|---|---|---|---|
| `goal_interval_ms` | 60000 | 900000 | `opponent.hero_health` |

## battle feedback

- Playing a card: the played card lifts and grows at its hand position with a green glowing border (`tween/battle/card_lift`), then flies off (`tween/battle/card_fly`). A minion shrinks as it goes to the board slot where it will land, and a spell goes to the reveal spot on the right, shows large, then disappears
- Minion entrance: it appears large and drops into place (`tween/battle/summon`), squashes and bounces up the moment it lands (`tween/battle/summon_settle`), a dust ring spreads under it (`tween/battle/dust_ring`), dust and golden sparks (`particle/battle/summon_burst`) burst out, and the board sinks slightly (`tween/battle/land_thump`)
- Attack: the attacker lunges at the target (`tween/battle/attack_lunge`) and the damage appears the moment it hits. At the hit spot, sparks and dust spread wide (`particle/battle/impact` at `BattleConstants.IMPACT_BURST_SCALE` times scale, together with `particle/battle/summon_burst`), an orange shockwave ring spreads fast and fades (`tween/battle/impact_ring`), when a hero is hit the screen flashes warm (`tween/battle/hit_flash`), the board shakes hard (`tween/battle/impact_shake`; when a hero takes big damage (`BattleConstants.SHAKE_DAMAGE` or more), `tween/battle/board_shake`), and the attacker returns to its place while the damage shows (`tween/battle/attack_return`)
- Spell: the card is revealed large, and magic shards burst on the target (`particle/battle/spell_burst`)
- Damage and heal numbers: pop out large and disappear within about 1 second (`tween/battle/number_pop`)
- Buff: the minion swells (`tween/battle/buff_pop`), `+attack/+health` appears above it, the raised numbers grow and return (`tween/battle/stat_pop`), and green sparks (`particle/battle/buff_sparkle`)
- Match end: the fallen hero's portrait swells red, then tilts and fades (`tween/battle/hero_break`), shards fly (`particle/battle/hero_shatter`), and the board shakes hard. On a win the screen flashes warm (`tween/battle/victory_flash`); on a loss it flashes dark red (`tween/battle/defeat_flash`). Then my hero portrait and `승리!` (Victory!)/`패배!` (Defeat!) pop out in the middle of the board (`tween/battle/end_banner`; on a loss the portrait is dark). The result screen opens after `[game_over_delay]`
- Heal: `+heal amount` appears above the portrait (`체력 가득` (Full health) when health is full, `+찬 양 체력 가득` (+amount filled, Full health) when max health capped it and only part was filled), the portrait swells (`tween/battle/heal_pop`), the health number pops, and green sparks (`particle/battle/buff_sparkle`) rise
- Hand: cards are placed without overlapping. With 8 cards, they spread wide toward the left of the center
- Animation values live in tween presets and particle resources, and the big-damage criterion and layout values live in client constants (`BattleConstants`)

## art direction

- style: fantasy cards drawn on a dueling table of warm wood and stone. Painted fantasy illustration, crisp silhouettes, card art with a centered subject
- hex palette: background `#14110F`, panel `#1E1A2B`, card frame `#2A2238`, gold accent and button border `#E8B84A`, body text `#F4EBDD`, secondary text `#B8AC9A`, mana `#3FA9F5`, attack `#F2C14E`, health `#D64545`, available actions `#5BE37D`, target `#FF6B4A`, selection `#FFE066`
- outline: black outlines on numbers and large titles. Cards and minions have gold frames, Guard has a thick silver frame and the `수호` (Guard) tag, Ward is a translucent golden film
- proportions: hand card 176x250, board minion 132x172 (oval art), hero portrait 150x150, board of 5 slots
- screen density: only minions sit in the middle of the board. Numbers (mana, deck, turn) sit at the right edge and the top-left edge. Things are not told apart by color alone; text (`수호` (Guard), `대기` (Waiting), mana number) and shape (borders) are used too
- UI frames: panels and popups use `nine_slice/ui/panel_frame`, buttons `nine_slice/ui/button` (hover, pressed and disabled change only the color), border glow and focus `nine_slice/ui/glow_ring`, name plates and mana boxes `nine_slice/ui/name_plate`, art slots `nine_slice/ui/inset`, card bodies `nine_slice/battle/card_frame`, minions `image/battle/minion_frame` (also the shape that crops the art), `image/battle/minion_guard_frame`, `image/battle/minion_glow`, `image/battle/ward_bubble`, hero portrait frame `image/battle/hero_frame`, number gems `icon/battle/gem_mana`, `icon/battle/gem_attack`, `icon/battle/gem_health`, mana crystal `icon/battle/mana_crystal`, enemy card back `image/card_back` (96x136; tinted deep indigo, overlapped and tilted in a fan so that all of it shows inside the top edge of the screen), and the hero name plate is a golden ornamental plate made by scaling `nine_slice/ui/panel_frame` down to 0.4 times. Solid-color boxes drawn in code are not used
- main resource keys: `background/battle_board`, `background/lobby`, `image/card_*`, `image/opp_*`, `image/hero_player`, `app_icon/main`, `splash/main`, `font/main`

## audio direction

- mood: a warm tavern and a focused duel. The lobby has lute and light percussion; the match has strings and a steady pulse that build tension without covering the card sounds
- BGM per scene: lobby `bgm/lobby`, match `bgm/battle`. The title has no BGM
- events with sound: UI button `sfx/ui_click`, playing a minion `sfx/card_play`, drawing a card `sfx/card_draw`, spell `sfx/spell_cast`, attack `sfx/attack_hit`, hero damage `sfx/hero_hit`, minion death `sfx/minion_death`, heal `sfx/heal`, Ward break `sfx/ward_break`, buff `sfx/buff`, my turn start `sfx/your_turn`, end turn `sfx/end_turn`, victory `sfx/victory`, defeat `sfx/defeat`, reward card `sfx/reward`, refusal `sfx/error`

## terms

- Words used: `마나` (Mana), `하수인` (Minion), `주문` (Spell), `영웅` (Hero), `수호` (Guard), `돌격` (Charge), `결계` (Ward), `등장 시` (On Play), `소멸 시` (On Death), `손패` (Hand), `덱` (Deck), `턴 종료` (End Turn), `대전` (match), `상대` (opponent), `전적` (record)
- Words not used: `하스스톤` (Hearthstone), `도발` (Taunt), `천상의 보호막` (Divine Shield), `전투의 함성` (Battlecry), `죽음의 메아리` (Deathrattle), `영웅 능력` (hero power), `카드 팩` (card pack), `멀리건` (mulligan)
- glossary terms: 20 card names, 3 opponent names, `마나 클래시` (Mana Clash), `마나`, `하수인`, `주문`, `영웅`, `수호`, `돌격`, `결계`, `등장 시`, `소멸 시`, `턴 종료`, `손패`, `덱`

## core usage

- client hook: none. `ContentBoot` uses the core default behavior and only changes the first scene to the match for a user with no finished match
- server hook: `prepare_play_session` (`server/hooks/play_session.ts` `prepare_battle`), `verify_play_session` (`verify_battle`), `apply_play_session` (`apply_battle`) of `play-session`
