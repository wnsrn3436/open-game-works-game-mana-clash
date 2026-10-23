## player fantasy

Become a dueling mage who calculates down to the last point of remaining mana, combines minions and spells, and finds the one turn that brings the enemy hero's health to exactly 0.

## emotion

Core emotion: the thrill of a calculation that works out exactly (mastery).

Curve of one match:

1. First turns (mana 1~3): look at the hand and choose what to play first. Low tension, exploration
2. Midgame (mana 4~6): both sides' minions fill the board and trades begin. Guard minions and Ward complicate the calculation. Tension rises
3. Crisis: the opponent's big minion or area spell turns the board around. My hero's health drops and tension is highest
4. Finishing blow: find the turn where the remaining mana and the total attack on the board reach the enemy hero's health. The enemy hero's shattering animation releases the tension at once
5. End: on a win, a new card reward and anticipation of the next opponent; on a loss, the regret of "if only the deck were different" and an immediate retry

## memorable moment

The moment when, with the enemy hero's health slightly above the total attack on my board, a `번개 창` (Lightning Lance) cast with the last mana clears the Guard minion and opens the way, my minions' attacks bring the enemy hero's health to exactly 0, and the hero portrait shatters.

## genre conventions

| convention | decision | reason |
|---|---|---|
| One mana crystal is added each turn and all mana refills | accept | It is the rhythm of the genre. Maximum 10 |
| Minions are played onto the board and cannot attack on the turn they are played (except Charge) | accept | It is the basis for trades and planning |
| Keywords such as Guard (Taunt), Ward (Divine Shield), Charge, On Play (Battlecry) and On Death (Deathrattle) | twist | Only five keywords are kept, Guard, Ward, Charge, On Play and On Death, and their names and all cards are made new. With 20 cards, the role of each keyword is clear |
| Hero health 30, 30-card deck, 7-slot board | twist | Hero health 20, 20-card deck, 5-slot board. A match stays short (about 6~10 minutes) and the screen stays easy to read. The first opponent (the practice opponent) has hero health 14 and goes for my hero instead of trading, so my health drops from the first match on |
| Swapping the starting hand (mulligan) | twist | There is no swap screen. Instead, the starting hand must get at least one card of mana 2 or less. The first match starts at once |
| Random first and second player, and a compensation card for the second player | twist | Matches are against the CPU, so the player always goes first, and the CPU's starting hand has one more card |
| Hero power (a fixed skill that spends leftover mana) | reject | Cards are the only way to spend leftover mana, so the calculation of each point of mana comes down to card choice |
| Random-target effects (random damage, random summons) | reject | Every effect goes to a chosen target or a fixed target. Luck does not hide the thrill of a calculation that works out |
| Damage that grows with each draw once the deck is empty (fatigue) | accept | Ends long matches |
| Turn time limit (a rope counting seconds) | reject | Matches are against the CPU with no human opponent, so thinking time is not cut off |
| Card packs and random collection | reject | Each time the player beats an opponent for the first time, fixed new cards enter the deck. There is no payment and no random pull |

## prohibitions

- No hero power (removes a standard feature of the genre)
- No effect that goes to a random target. Only deck shuffling and drawing are random
- Do not use Hearthstone's card names, card text, art, heroes or sound effects. All cards and opponents are made new
- No payment, ads, card packs or gacha
- The CPU does not decide by looking at the player's hand or deck order. The CPU sees only what is visible on the board and its own hand

## failure penalty

- Share of progress lost per mistake (losing one match): 0‰. Beaten opponents, received cards and the deck do not shrink. A loss only adds 1 loss to the record and breaks the win streak
- duration limit of the loss state: 3000ms. It is the sum of my hero's shattering animation and the time until the result screen opens
- delay limit from the end of the loss until control returns: 1000ms. It runs from the result screen opening until the `다시 도전` (Challenge again) button can be pressed. `다시 도전` starts a new match against the same opponent at once

## prediction

If it works, after winning the first match (the practice opponent) the player sees the new card reward on the result screen and, without going through the lobby, presses the `다음 상대` (Next opponent) button to start a match against the second opponent.

## reference game

Hearthstone

records/setup/reference/reference.md

What this game does differently from the reference game:

- No hero power, and every effect goes to a chosen target or a fixed target (no random targets)
- Hero health 20, a 20-card deck and a 5-slot board make a match short
- No starting-hand swap screen, and a card of mana 2 or less must be in the starting hand
- Instead of card packs and payment, fixed new cards enter the deck each time the player beats an opponent of the CPU ladder (3 opponents) for the first time
- Cards are played by pressing (click), not by dragging. For cards that need a target and for attacks, press the card or minion, then press the target

## request

"Make Hearthstone. For now, let's make only about 20 cards" "https://youtu.be/I7lX3Q2LfAA?si=BD0owSe5fymUmGzQ refer to the video from 3 minutes"

Hearthstone's card names, card text, art and heroes are not used; everything is made original

Items the content agent decided:

- Single-player matches against the CPU. There are three opponents, the practice opponent, the Forest Warden and the Archmage, and they open in order
- There are 20 cards (15 minions, 5 spells)
- On first launch, the first match against the practice opponent starts at once without going through the lobby, and on-screen hint text teaches playing a card, attacking and ending the turn in order (the first-match flow at 3 minutes of the reference video)
- The target platform is macOS in game settings `buildPlatforms`. Controls use the mouse
- The screen is landscape, with a base resolution of 1920x1080
- Supported languages are Korean and English
- The game name is `마나 클래시` (Mana Clash) in `records/setup/name.md`
