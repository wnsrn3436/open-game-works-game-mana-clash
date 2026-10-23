# Mana Clash

[한국어](README.ko.md)

A one-on-one card battle game against CPU duelists, made by AI agents with
[open-game-works](https://github.com/wnsrn3436/open-game-works-core).

<p align="center"><img src=".github/media/mana-clash.gif" alt="mana-clash gameplay" width="720"></p>

## Status

Mana Clash was made with open-game-works and was played and checked on macOS during development. It has not been
built for release yet: the `build` command has not been run on it.

## What it is

Mana Clash (`마나 클래시`) is a single-player, turn-based card battle game for macOS. You play a dueling mage. Each
turn you spend mana on minions and spells, attack with the minions on your board, and look for the one turn in which
your remaining mana and the attack on your board bring the enemy hero's health to exactly 0.

- 20 cards (15 minions and 5 spells) with five keywords: Guard, Ward, Charge, On Play and On Death
- A ladder of three CPU opponents. Beating an opponent opens the next one. The first win against each opponent puts
  three fixed new cards into your deck and takes the same number out, so the deck always has 20 cards
- On first launch, after the terms popup, the first match against the practice opponent starts at once, without the
  lobby, and a hint line teaches playing a card, choosing a target, attacking and ending the turn
- A loss only adds a loss to the record and ends the win streak: beaten opponents, received cards and the deck stay.
  `Challenge again` starts a new match against the same opponent at once
- Mouse clicks only (no dragging); `Esc` opens the pause popup. Landscape screen, base resolution 1920x1080

## Rules

From `data/system/game_setting.csv` and `design.md`:

| rule | value |
|---|---|
| your hero's health | 20 (each opponent's is in the [Opponents](#opponents) table) |
| deck | 20 cards, shuffled at match start |
| board | 5 slots per side |
| hand | up to 8 cards; a card drawn into a full hand burns |
| mana | one more crystal each turn, up to 10, refilled every turn |
| starting hand | 3 cards for you (you always go first), 4 for the CPU. There is no swap screen; the starting hand always holds a card of mana 2 or less |
| empty deck | each draw from an empty deck deals 1, 2, 3, ... damage |
| turn limit | a match that goes past 60 turns ends in a loss |

What the game leaves out on purpose (from `brief.md`):

- No hero power. Cards are the only way to spend mana
- No effect with a random target. Every effect goes to a chosen or a fixed target; only shuffling and drawing are
  random
- No payment, ads, card packs or gacha. New cards come only from first wins on the ladder
- The CPU decides only from the board and its own hand, never from your hand or your deck order
- No turn timer

## Opponents

From `data/tables/opponent.csv` and the English translation:

| order | opponent | hero health | in the game | cards added on the first win |
|---|---|---|---|---|
| 1 | Miro the Trainee (practice opponent) | 14 | A trainee who knows nothing about trading and only goes for your Hero. Their Hero has low health | Lightning Lance, Dawn Knight, Insight |
| 2 | Tara the Forest Warden | 18 | Holds out with Guard Minions, then pushes forward with a big tree | Firestorm, War Drummer, Flame Wyvern |
| 3 | Velloch the Archmage | 25 | The top of the ladder, sweeping the board with Spells | Sky Colossus, Ash Wraith, Elder Treant |

## Getting started

This repository is used inside an open-game-works workspace, next to the harness:

```
<workspace>/
  open-game-works-core/                    harness (run Claude Code or Codex here)
  open-game-works-core-impl/               core source
  open-game-works-core-releases/           downloaded core releases (created by the tool)
  games/open-game-works-game-mana-clash/   this repository
```

1. Set up the workspace and the harness with the
   [Quick start of the harness README](https://github.com/wnsrn3436/open-game-works-core#quick-start)
2. Clone this repository into `games/` and create the local `id-registry` branch, which the data tool reads:

   ```
   cd <workspace>/games
   git clone https://github.com/wnsrn3436/open-game-works-game-mana-clash.git
   cd open-game-works-game-mana-clash
   git branch id-registry origin/id-registry
   ```

3. In the Claude Code session in `open-game-works-core/`, run `update env` after cloning, even if you ran it before.
   It installs, among other things, the engine version of each game's core release in `games/`
4. To play the game yourself, start an instance from a terminal, and stop it when you are done:

   ```
   cd <workspace>/open-game-works-core
   tools/bin/ogw instance start open-game-works-game-mana-clash
   # id: <instance id>
   # address: <server URL>
   tools/bin/ogw instance stop <instance id>
   ```

5. To change the game, give `update game: open-game-works-game-mana-clash <request>` in the Claude Code session. Put
   the reference gameplay videos in place first (see [Reference videos](#reference-videos))

More commands and options are in [Working on the game](#working-on-the-game).

## How it was made

AI agents made the game with the open-game-works harness. In `setup game` a human gave the request, a reference game
and its gameplay videos, then started `create game`. From there the lead agent ran the loop to the end without waiting
for the human: the content agent edits, the automated checks run, play agents play instances with real input, a judge
agent compares the result with a baseline and with the reference gameplay videos, and the harness tool decides success
from the judge results and the automated checks.

| part | made by |
|---|---|
| `brief.md`, `design.md`, `play-guide.md`, client and server content code, scenes, prefabs, tween presets, data, contract, regression tests, bot playtest scenario | content agent |
| images, icons, backgrounds, music, sound effects, particles, font | resource sub-agent, with the generation methods in the harness settings |
| English translation | translation sub-agent |
| `client/core/`, `server/core/` | a core release (the content agent does not edit core) |

The content agent wrote `brief.md`, `design.md` and `play-guide.md` in Korean; they were translated into English after
the `create game` loop.

Every resource in `resource/resources.csv` has status `final`. The generation methods used:

| resources | count | method | kind | `license` recorded |
|---|---|---|---|---|
| images, icons, backgrounds, nine-slice frames, app icon, splash | 44 | `flux2-klein` | local model | Apache-2.0 |
| background music | 2 | `ace-step` | local model | MIT |
| sound effects | 16 | `moss-sfx` | local model | Apache-2.0 |
| particles | 5 | `procedural` | procedural | LicenseRef-game-owned |
| font (Noto Sans KR) | 1 | `font-catalog` | pinned catalog | OFL-1.1 |
| scenes, prefabs, tween presets | 45 | written by the content agent | | |

In the loop, the game is covered by the regression tests in `client/tests/` and `server/tests/`, the bot playtest
scenario `client/dev/bot/scenario.json`, and a row simulation: a bot plays each opponent, and its win rate, turn count
and damage are compared with the `sim_` columns of `data/tables/opponent.csv`.

## How it works

A match is one run of the core module `play-session`. The game defines no RPC of its own: the server content code
(`server/main.ts`, `server/hooks/play_session.ts`) registers the three hooks of that module.

```
client (Godot, client/)                         server (TypeScript, server/)

title -> lobby -> battle
StartPlaySession (level_id = opponent) -------> prepare_play_session
                                                  opponent exists and is unlocked?
                <------- PlaySessionLoadout       player deck, opponent deck, seed
the match runs in the client simulation
(BattleSim, BattleAi; decks shuffled by seed)
FinishPlaySession (PlaySessionResult) --------> verify_play_session
                                                  values within bounds, win or loss consistent
                                                apply_play_session
                                                  record, win streak, first-win reward cards
                                                  -> ProgressUserState
```

- The opponent unlock rule is a shared formula (`lobby.opponent_unlocked`) that the client lobby and the server both
  use; its fixture is `data/fixtures/lobby.opponent_unlocked.json`
- The contract (`contract/`) defines `PlaySessionLoadout`, `PlaySessionResult`, `ProgressUserState` and the error codes
  `GAME_ERROR_OPPONENT_NOT_FOUND` and `GAME_ERROR_OPPONENT_LOCKED`

## Core version

`settings.json` pins `coreVersion` **0.1.0**, a
[GitHub Release of open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0).

- `client/core/` and `server/core/` are copies of that release
- When the release is not in `open-game-works-core-releases/` of the workspace, the harness tool fetches it from
  GitHub and checks the files by hash
- That release uses Godot 4.7.2 (`engine.json` of the release)
- Core modules the game chose (`coreModules`): client `NativeUiCore`, `TweenCore`, `ScreenEffectCore`; server
  `play-session`
- `update game` first raises `coreVersion` to the highest core release it can

## Repository layout

| path | contents |
|---|---|
| `brief.md` | The brief: player fantasy, emotion, genre conventions kept or changed, prohibitions, failure penalty, reference game, request |
| `design.md` | The design doc: core loop, controls, screens, battle rules, CPU, ladder, progression, feel and tuning targets, art and audio direction, terms, core usage |
| `play-guide.md` | The play guide that play agents and the judge agent receive: goal, controls with automation anchors, game flow, input lock windows, play mode |
| `settings.json` | Game settings (schema: `schemas/game-settings.schema.json` of the harness): core version, engine, core modules, languages, build platforms, resolution, UI check screens, environments |
| `contract/` | Protobuf contract: `service.proto`, `user_state.proto`, `error.proto` |
| `data/` | CSV tables (`tables/`: `card.csv`, `deck.csv`, `opponent.csv` and the core data tables the data tool adds; `system/`: `game_setting.csv` and reserved IDs), `enums.csv`, `invariants.csv`, `simulation_tables.csv`, `glossary.csv`, `translations/`, `fixtures/` |
| `resource/` | Final resources (images, music, sound effects, font, scenes, prefabs, tween presets, particles) and `resources.csv`, which lists each resource key with its method, source and license |
| `client/` | Godot project: `boot/`, `common/`, `features/` (`title`, `lobby`, `battle` with the simulation in `battle/sim/`), `core/` (core release), `generated/` (contract tool and data tool output), `dev/` (DEV code: bot playtest scenario, automation commands that open screens and run the opponent simulation, generated DEV code), `tests/`. `client/resource` is a link to `../resource` |
| `server/` | TypeScript server: `main.ts`, `hooks/play_session.ts`, `core/` (core release), `generated/`, `dev/`, `tests/` |
| `records/` | Process records that agents and the harness tool write. It currently holds `records/setup/reference/reference.md` |
| `LICENSE`, `LICENSES/` | The license terms of this repository and the license texts of the parts under Apache-2.0 and OFL-1.1 |

The ID registry is kept on the separate branch `id-registry` (`id_registry.json`). Only the data tool writes to it, and
it is never merged with another branch.

## Languages

- Source text is Korean: `settings.json` does not set `sourceLanguage`, so the schema default `ko` applies
- `supportedLanguages` is `ko` and `en`. The text columns of `data/` hold the Korean source text, and
  `data/translations/ko.csv` and `data/translations/en.csv` hold the text per translation key. The translation
  sub-agent writes the English text
- `data/glossary.csv` fixes the translations of the card and opponent names, the game name and the game's terms (for
  example Guard, Ward, Charge)
- `brief.md`, `design.md` and `play-guide.md` are in English; Korean in-game text appears in code spans with its English
  meaning next to it

## Working on the game

All work goes through the harness. Open Claude Code or Codex in `open-game-works-core/` and give a command:

| command | what happens |
|---|---|
| `update game: open-game-works-game-mana-clash <request>` | Raises `coreVersion`, runs the loop on a work branch `loop/<run>` until it stops, then merges the chosen commit into `main` and reports. Use it for feedback after playing, new features and fixes |
| `build: open-game-works-game-mana-clash DEV [<platform>...] [--version <version>]` | Hardens the server and client content code against the contract, runs the checks and the judge once more with PostgreSQL, builds the platforms (default: all of `buildPlatforms`), tags the commit `dev-<version>` and deploys the DEV server. Build artifacts go to `builds/`, which is not committed |
| `build: open-game-works-game-mana-clash STG` / `PROD` | STG and PROD builds go as far as signed artifacts. STG also deploys its server; a human deploys PROD |

- `build` first checks that `settings.json` has the build values it needs (those of that environment and those outside
  any environment). This repository does not have the DEV build values yet (for example `appId`, `serverImage`,
  `environments.DEV.serverUrl` and `environments.DEV.deploy`), so before the first DEV build the lead agent asks you
  for the missing values
- Only one of `create game`, `update game` and `build` runs at a time for this game
- `main` always holds the latest code that passed the loop

### Running an instance

An instance is a dev run of the game in the LOCAL environment: its own server process with SQLite, fake adapters for
external services, DEV code included, and the Godot client started from the project without a build. Start and stop
it with `tools/bin/ogw instance start` and `tools/bin/ogw instance stop` from the harness folder, as in
[Getting started](#getting-started).

- Options of `instance start`: `--commit <sha>` (start from a worktree of that commit), `--platform <platform>`
  (default: the first entry of `buildPlatforms`), `--fixture <file>` (a save fixture), `--db postgresql`
- The client logs in with a dev account and starts without the terms popup. With no finished match yet, the first
  match against the practice opponent opens right away
- The number of instances running at once is limited by `maxConcurrentInstances` of the harness settings

Commands for a running instance:

| command | work |
|---|---|
| `tools/bin/ogw capture <id> [--video <ms>]` | Captures the screen, or a video of that duration |
| `tools/bin/ogw log <id>` | Shows the error log |
| `tools/bin/ogw telemetry <id>` | Shows telemetry |
| `tools/bin/ogw input <id> <command> <argument...>` | Puts in one real input (`ogw input --help` lists the commands) |
| `tools/bin/ogw command <id> list_commands` | Lists the game's content commands with their descriptions and arguments |

### Reference videos

`brief.md` names a reference game, and in the loop the judge agent compares this game with gameplay videos of it.
`records/setup/reference/reference.md` lists the video files and the moments that are compared (first 30 seconds, core
action, first failure, first reward, restart).

The videos are not in the repository: `.gitignore` keeps every file in `records/setup/reference/` except `reference.md` out of git. The judge agent
receives these files, so before you run `update game` or `build`, put the files listed under `## video`
of `reference.md` into `records/setup/reference/`. Each file name is a YouTube video ID followed by `.mp4`. Run this
once per file to fetch the video into that folder as `<video id>.mp4` (it needs `yt-dlp` on the host):

```
cd <workspace>/open-game-works-core
tools/bin/ogw game reference open-game-works-game-mana-clash https://www.youtube.com/watch?v=<video id>
```

### Requirements

Besides what the harness needs:

- The only build platform is `macos` (`buildPlatforms`). A macOS build runs on a Mac with Xcode (`buildTools` of the
  core release's `engine.json`)
- Docker: builds and `--db postgresql` instances use a PostgreSQL container (`postgresqlMajor` is 18)

Windows: this repository uses the symbolic link `client/resource` -> `../resource`. Enable Developer Mode and run
`git config --global core.symlinks true` before cloning, or the link checks out as a plain text file. The play and
judge agents run in a sandbox that exists only on macOS and Linux, so the loop (`update game`) and DEV and STG builds
do not run on Windows. macOS is the primary host.

## License

See [LICENSE](LICENSE).

- The game's own content in this repository (documents, contract, data, content code, scenes, prefabs and other
  resources) is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)
- `client/core/` and `server/core/` are copies of an open-game-works core release and stay under the Apache License
  2.0, like [open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl)
  ([LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt))
- The bundled font `resource/font/main.ttf` (Noto Sans KR) stays under the SIL Open Font License 1.1
  ([LICENSES/OFL-1.1-NotoSansKR.txt](LICENSES/OFL-1.1-NotoSansKR.txt))
- For each resource, `resource/resources.csv` records how it was made (`method`) and the license of the model or
  source used (`license`), with the source and attribution where they apply
- Resources marked `LicenseRef-game-owned` in `resource/resources.csv` were made by the game's own procedural
  generation and are part of the game's content under its license (CC BY-NC-ND 4.0)
- The third-party components of the client (Godot Engine and the libraries it includes, the godot-cpp library of the
  core's native UI plugin, the Android libraries that plugin uses, and the font) are listed with their licenses and the
  platforms they ship on in `client/generated/licenses.json`
