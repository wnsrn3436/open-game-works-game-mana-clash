# Mana Clash

[한국어](README.ko.md)

A one-on-one card battle game against CPU duelists for macOS, made by AI agents with
[open-game-works](https://github.com/wnsrn3436/open-game-works-core).

<p align="center"><img src=".github/media/mana-clash.gif" alt="mana-clash gameplay" width="720"></p>

## Play it

Set up an open-game-works workspace with the
[Quick start of the harness README](https://github.com/wnsrn3436/open-game-works-core#quick-start). Then clone this
repository into `games/` (with the local `id-registry` branch the data tool reads) and start an instance to play:

```
cd <workspace>/games
git clone https://github.com/wnsrn3436/open-game-works-game-mana-clash.git
cd open-game-works-game-mana-clash
git branch id-registry origin/id-registry

cd <workspace>/open-game-works-core
tools/bin/ogw instance start open-game-works-game-mana-clash   # prints the instance id
tools/bin/ogw instance stop <instance id>
```

Before the first `instance start`, run `update env` in the harness session (even if you ran it before): it installs
this game's engine.

## The game

You play a dueling mage in a single-player, turn-based card battle. Each turn you spend mana on minions and spells and
attack with your minions. You win when the enemy hero's health reaches 0; the aim is the turn where your remaining
mana and your board's attack bring it to exactly 0.

- **Cards:** 20 (15 minions, 5 spells) with five keywords: Guard, Ward, Charge, On Play and On Death
- **Opponents:** a ladder of three CPU duelists: Miro the Trainee (practice, hero health 14), Tara the Forest Warden
  (18) and Velloch the Archmage (25). Beating one opens the next
- **Controls:** mouse clicks only (no dragging); `Esc` opens the pause popup
- **Rules:** hero health 20, 20-card deck, 5 board slots per side, up to 8 cards in hand. One more mana crystal each
  turn, up to 10, refilled every turn. You always go first. An empty deck deals 1, 2, 3, ... damage per draw, and a
  match past 60 turns is a loss. No hero power, random-target effects, turn timer, payment, ads, card packs or gacha
- **Progress:** the first win against each opponent swaps three fixed new cards into your 20-card deck. A loss only
  adds to the record and ends the win streak; `Challenge again` starts a new match at once

## Status

Played and checked on macOS during development. Not built for release yet: `build` has not been run on it.

## Change it with AI

Give these in the Claude Code (or Codex) session in `open-game-works-core/`:

- `update game: open-game-works-game-mana-clash <request>`: runs the loop on your request and merges it into `main`
- `build: open-game-works-game-mana-clash DEV`: builds the game, tags `dev-<version>` and deploys the DEV server

First put the reference gameplay videos in place (the judge compares the game with them; they are not in git): run
this for each file under `## video` of [reference.md](records/setup/reference/reference.md) (needs `yt-dlp`):

```
cd <workspace>/open-game-works-core
tools/bin/ogw game reference open-game-works-game-mana-clash https://www.youtube.com/watch?v=<video id>
```

<details><summary>Before the first DEV build</summary>

- `settings.json` has no DEV build values yet (such as `appId`, `serverImage`, `environments.DEV.serverUrl` and
  `environments.DEV.deploy`); the lead agent asks you for them
- The only build platform is `macos`: builds need a Mac with Xcode, and Docker for a PostgreSQL 18 container
- Windows: `client/resource` is a symbolic link, so enable Developer Mode and run
  `git config --global core.symlinks true` before cloning. The loop and DEV and STG builds do not run on Windows

</details>

## How it is built

A match is one run of the core module `play-session`. The Godot client plays the whole match in its own simulation;
the TypeScript server hands out the decks and seed, checks the result, and saves the record and reward cards. It pins
core [0.1.0](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0) (`coreVersion` in
`settings.json`); `client/core/` and `server/core/` are copies of that release.

```
client (Godot, client/)                     server (TypeScript, server/)
StartPlaySession (opponent) ------------->  prepare: opponent exists and is unlocked?
            <---------- PlaySessionLoadout  player deck, opponent deck, seed
match runs in the client simulation
FinishPlaySession (result) -------------->  verify: values in bounds, win or loss consistent
                                            apply: record, win streak, first-win reward cards
```

| path | contents |
|---|---|
| [brief.md](brief.md) | player fantasy, genre conventions kept or changed, prohibitions, reference game |
| [design.md](design.md) | design doc: rules, screens, CPU, ladder, tuning, art and audio direction |
| [play-guide.md](play-guide.md) | guide for the play and judge agents: controls, game flow, input locks |
| [settings.json](settings.json) | core version, engine, core modules, languages, platforms, resolution |
| [contract/](contract/) | protobuf contract between client and server |
| [data/](data/) | CSV tables (cards, decks, opponents, settings), translations, fixtures |
| [resource/](resource/) | images, music, sound effects, font, scenes, prefabs; [resources.csv](resource/resources.csv) |
| [client/](client/) | Godot project (title, lobby, battle with its simulation) and tests |
| [server/](server/) | TypeScript server hooks of `play-session` and tests |
| [records/](records/) | process records, including the reference game notes |

Made with the [open-game-works harness](https://github.com/wnsrn3436/open-game-works-core).

## License

See [LICENSE](LICENSE).

| part | license |
|---|---|
| The game's own content (documents, contract, data, content code, scenes, prefabs and other resources) | [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) |
| Resources marked `LicenseRef-game-owned` in `resource/resources.csv` (made by the game's own procedural generation) | part of the game's content: CC BY-NC-ND 4.0 |
| `client/core/`, `server/core/`: copies of an open-game-works core release, like [open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl) | Apache License 2.0 ([LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt)) |
| `resource/font/main.ttf` (Noto Sans KR) | SIL Open Font License 1.1 ([LICENSES/OFL-1.1-NotoSansKR.txt](LICENSES/OFL-1.1-NotoSansKR.txt)) |

For each resource, `resource/resources.csv` records how it was made (`method`) and the license of the model or source
used (`license`), with the source and attribution where they apply:

| resources | count | `method` | `license` recorded |
|---|---|---|---|
| images, icons, backgrounds, nine-slice frames, app icon, splash | 44 | `flux2-klein` (local model) | Apache-2.0 |
| background music | 2 | `ace-step` (local model) | MIT |
| sound effects | 16 | `moss-sfx` (local model) | Apache-2.0 |
| particles | 5 | `procedural` | LicenseRef-game-owned |
| font (Noto Sans KR) | 1 | `font-catalog` (pinned catalog) | OFL-1.1 |
| scenes, prefabs, tween presets | 45 | written by the content agent | |

The third-party components of the client (Godot Engine and the libraries it includes, the godot-cpp library of the
core's native UI plugin, the Android libraries that plugin uses, and the font) are listed with their licenses and the
platforms they ship on in `client/generated/licenses.json`.
