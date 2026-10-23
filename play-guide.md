## goal

Fight CPU duelists with cards and bring the enemy hero's health (the number in the red circle at the bottom right of the portrait) to 0. There are three opponents (`수련생 미로` (Miro the Trainee) → `숲의 파수꾼 타라` (Tara the Forest Warden) → `대마법사 벨로크` (Velloch the Archmage)), and beating an opponent opens the next one. Each time an opponent is beaten for the first time, three new cards enter my deck.

## controls

- Every control is a mouse click (tap). There is no dragging
- Hand cards (bottom of the screen, anchors `hand_card_1`~`hand_card_8`, from the left): pressing one plays that card. The blue circle at the card's top left is the mana it needs. On my turn, a card that can be played now has a green glowing border, and a card that cannot be played because mana is short or there is no target has no border and dark art
  - A card that needs a target (`마나 화살` (Mana Bolt), `번개 창` (Lightning Lance): any character / `수호의 축복` (Guardian's Blessing): my minion) rises with a yellow border when pressed, and whatever can be a target gets a red border. Pressing that target uses the card. Pressing the same card again or an empty spot on the board cancels
- Minion attack: pressing one of my minions (lower middle row, anchors `own_minion_1`~`own_minion_5`) that has a green border selects it with a yellow border, and pressing an enemy that can be attacked (red border: enemy minions `enemy_minion_1`~`enemy_minion_5`, enemy hero `enemy_hero`) attacks it. Only minions that can still attack this turn have a green border, and a minion that has finished attacking loses its border. My hero is the portrait at the bottom left of the board (`own_hero`)
- Minion anchor numbers: when my turn starts they are 1, 2, 3… from the left. Within that turn, the numbers of the remaining minions do not change when a minion dies (e.g. when `enemy_minion_1` dies, `enemy_minion_2` stays `enemy_minion_2` even when it moves toward the middle, and `enemy_minion_1` no longer exists). A newly played minion gets the number after the numbers in use. So during a turn the numbers can differ from the order from the left. When the numbers are confusing, it is also fine to find that minion's position in the capture and press that spot with `tap`
- A minion on the turn it is played carries the `대기` (Waiting) tag and cannot attack (a Charge minion attacks at once)
- When the enemy board has a minion with the `수호` (Guard) tag (thick silver border), only that minion can be attacked
- A minion with a golden film (Ward) blocks the next single instance of damage, and the film disappears
- `턴 종료` (End Turn) button (right middle, anchor `end_turn`): ends my turn. When there is nothing more to do, it glows green and its text turns green. During the opponent's turn its text is `상대 차례` (Opponent's turn)
- Presses made during an animation (while a card flies, a minion lands or an attack plays) are all remembered in the order pressed and run one by one when the animation ends. E.g. pressing a card and then `턴 종료` right away ends the turn after the card comes out
- Refusal: pressing something that cannot be done now (e.g. not enough mana, attacking the hero while there is a Guard minion, the opponent's turn) plays an error sound, the reason appears for about 1.4 seconds above what was pressed (beside it when above is the screen edge, beside the portrait when it would cover a hero portrait), and the pressed card or minion shakes. When mana is short, the mana number flashes red; when Guard is the cause, the frame of the enemy Guard minion swells
- `일시정지` (Paused) button (top left, anchor `battle_pause`) or `Esc`: pause popup (`계속하기` (Resume) anchor `pause_resume`, `항복하기` (Concede) anchor `pause_concede`). Pressing `항복하기` the first time shows a confirmation sentence and the button changes to `네, 항복할게요` (Yes, concede). Pressing it once more (the same anchor `pause_concede`) ends the match in a defeat. Pressing `계속하기` continues the match
- Mana: `usable mana/max mana` and the blue circle at the bottom right. On each of my turns, max mana goes up by 1 (up to 10) and mana fully refills
- The top right shows the opponent's mana and deck, and the number of card backs fanned out along the top is the opponent's hand size. The top left shows the current turn number
- When my turn starts (from my second turn on), the `지난 상대 차례` (Last opponent turn) box at the top left shows the cards the opponent played in the previous opponent turn, the damage my hero took, the damage my minions took, the number of my minions that fell, the number of enemy minions that fell and the health the enemy hero restored (only what happened). It disappears when the opponent's turn starts

## game flow

1. Terms agreement popup (new users only): press `모두 동의합니다` (Agree to all) (anchor `terms_agree_all`), then `확인` (OK) (anchor `terms_confirm`)
2. For a user with no finished match, a match against the practice opponent (`수련생 미로` (Miro the Trainee), hero health 14) opens right away without the lobby. The practice opponent hits my hero rather than trading minions and also uses damage spells on my hero (when my board has a Guard minion, it must hit the Guard first). In the first match, the hint box at the left middle tells what can be done now. The hints for playing a card, attacking and ending the turn do not appear again once that action is done in that match (the hint while choosing a target appears every time)
3. Match: I always move first. After the `내 차례` (Your turn) display on the left of the board, play cards, attack and press `턴 종료` (End Turn). A played card flies from its hand position; a minion is placed in the rightmost slot of my board and a spell in the reveal spot on the right. After `턴 종료`, the `상대 차례` (Opponent's turn) display appears and the CPU moves one action at a time. A card the CPU played shows large on the right for a moment. When a heal goes to a hero with full health, `체력 가득` (Full health) appears above the portrait. During the CPU turn, pressing the board makes no move and the `상대 차례예요` (It's the opponent's turn) hint appears
4. When one hero's health reaches 0, the portrait shatters, my hero portrait and a large `승리!` (Victory!)/`패배!` (Defeat!) display appear in the middle of the board, and about 1 second later the result screen opens (pressing the board during that time opens it at once without waiting). For an opponent beaten for the first time, before the result screen, `새 카드를 얻었어요!` (You got a new card!) and three new cards flip out large one at a time over the whole screen. When all are out, `아무 곳이나 눌러 계속하기` (Tap anywhere to continue) shows, and pressing the screen (anchor `reward_continue`) closes it (pressing during the flips shows all cards first, and one more press is needed to close it). Result screen: `승리!`/`패배` (Defeat), opponent, the turn the match ended on, record. For an opponent beaten for the first time, the three new cards are in a row, and under it the cards leaving the deck appear in one line (one card leaves for each new card, so the deck always has 20 cards). On a loss, a one-line tip for that opponent appears and, for an opponent not yet beaten, the three cards received by beating it. Buttons: `다음 상대` (Next opponent) (only when a new opponent opened, anchor `result_next`), `다시 도전` (Challenge again) (a new match against the same opponent, anchor `result_retry`), `로비로` (To lobby) (anchor `result_lobby`)
5. Lobby: pressing an opponent in the opponent list on the right (anchors `lobby_opponent_1`~`lobby_opponent_3`, from the top) selects that opponent (a locked opponent cannot be selected). `대전 시작` (Start match) (anchor `lobby_play`) starts a match against the selected opponent. `내 덱` (My Deck) (anchor `lobby_deck`) shows the cards of the deck, and `닫기` (Close) (anchor `deck_close`) closes it. `설정` (Settings) (anchor `lobby_options`)

## failure

- Defeat: the match is lost when my hero's health reaches 0 or when `항복하기` (Concede) is pressed twice (confirmation included). Nothing is lost (beaten opponents, received cards and the deck stay as they are). Pressing `다시 도전` (Challenge again) (anchor `result_retry`) on the result screen starts a new match against the same opponent at once

## input lock window

- boot and title: no input is accepted until login finishes (about 1000ms~3000ms)
- scene change (lobby ↔ match): during the loading screen (about 300ms~1500ms)
- match start: until the server responds (about 100ms~500ms), `대전 준비 중` (Getting the match ready) shows and the board is empty
- turn start display: while the `내 차례`/`상대 차례` display on the left of the board shows for about 1000ms, board input is not accepted
- animation: while a played card flies from the hand (about 300ms), a card enters (about 300ms), an attack plays (about 450ms), damage and death play (about 350ms~450ms) and a card is revealed (spells and CPU cards, about 1350ms), board input does not run at once. On my turn, of the hand cards, my minions and `턴 종료` pressed during that time, the last one is remembered and runs when the animation ends
- CPU turn: about 900ms after the turn starts, then about 950ms plus animation duration per action. Usually 3000ms~14000ms
- match end: after the portrait shatters and the `승리!`/`패배!` display appears, the result screen does not open for about 1000ms (skipped by pressing the board) and until the result save response arrives
- first win reward screen: about 1700ms until all three cards have flipped. A press during that time finishes the flipping. The result screen buttons can be pressed after this screen closes
- pause popup: the CPU does not move while it is open

## fastest start path

1. (new user) terms popup `tap_anchor terms_agree_all` → `tap_anchor terms_confirm`
2. With no finished match, the match screen opens right after login. If the lobby opened, `tap_anchor lobby_play`
3. After the `내 차례` (Your turn) display disappears, press a hand card with a green border (e.g. `tap_anchor hand_card_1`)

## play mode

| scene | mode | step ms |
|---|---|---|
| `scene/title/title` | `free` | |
| `scene/lobby/lobby` | `free` | |
| `scene/battle/battle` | `free` | |
