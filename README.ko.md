# 마나 클래시

[English](README.md)

CPU 결투자와 일대일로 겨루는 카드 배틀 게임. AI 에이전트가
[open-game-works](https://github.com/wnsrn3436/open-game-works-core)로 만들었다.

<p align="center"><img src=".github/media/mana-clash.gif" alt="mana-clash gameplay" width="720"></p>

## 현재 상태

마나 클래시는 open-game-works로 만든 게임이고 개발하는 동안 macOS에서 플레이하며 확인했다. 아직 `build` 명령을
실행하지 않아서 출시용 빌드는 없다.

## 소개

마나 클래시(Mana Clash)는 macOS용 싱글 플레이 턴제 카드 배틀 게임이다. 플레이어는 결투 마법사가 되어 매 턴 마나로
하수인과 주문을 내고 보드 위의 하수인으로 공격하면서 남은 마나와 보드의 공격력으로 상대 영웅의 체력을 정확히 0으로
만드는 한 턴을 찾는다.

- 카드 20장(하수인 15장, 주문 5장)과 다섯 가지 키워드: 수호, 결계, 돌격, 등장 시, 소멸 시
- CPU 상대 세 명으로 이루어진 사다리. 상대를 이기면 다음 상대가 열린다. 각 상대를 처음 이기면 정해진 새 카드 세 장이
  덱에 들어오고 같은 수의 카드가 빠지므로, 덱은 늘 20장이다
- 첫 실행에서는 약관 팝업 다음에 로비를 거치지 않고 연습 상대와의 첫 대전이 바로 시작되고 힌트 줄이 카드 내기, 대상
  고르기, 공격, 턴 종료를 차례로 알려 준다
- 패배는 전적에 1패를 더하고 연승을 끊을 뿐이다. 이긴 상대, 받은 카드, 덱은 그대로 남는다. `다시 도전`을 누르면 같은
  상대와 새 대전이 바로 시작된다
- 조작은 드래그 없이 마우스 클릭뿐이고 `Esc`로 일시정지 팝업을 연다. 화면은 가로 방향, 기준 해상도는 1920x1080이다

## 규칙

`data/system/game_setting.csv`와 `design.md` 기준이다.

| 규칙 | 값 |
|---|---|
| 내 영웅 체력 | 20(상대 영웅 체력은 [상대](#상대) 표 참고) |
| 덱 | 20장, 대전 시작 때 섞음 |
| 보드 | 한쪽당 5칸 |
| 손패 | 최대 8장. 손패가 가득 찬 상태에서 뽑은 카드는 불타 사라짐 |
| 마나 | 마나 수정이 매 턴 하나씩 늘어 최대 10개, 매 턴 가득 다시 채워짐 |
| 시작 손패 | 플레이어 3장(항상 선공), CPU 4장. 교체 화면은 없고 시작 손패에는 마나 2 이하 카드가 반드시 들어감 |
| 빈 덱 | 빈 덱에서 카드를 뽑을 때마다 1, 2, 3, ... 피해 |
| 턴 제한 | 60턴을 넘긴 대전은 패배로 끝남 |

일부러 넣지 않은 것(`brief.md` 기준):

- 영웅 능력이 없다. 마나를 쓰는 방법은 카드뿐이다
- 대상이 무작위인 효과가 없다. 모든 효과는 고른 대상이나 정해진 대상에게 가고 무작위는 덱 섞기와 카드 뽑기뿐이다
- 결제, 광고, 카드 팩, 가챠가 없다. 새 카드는 사다리에서 처음 이길 때만 얻는다
- CPU는 보드와 자기 손패만 보고 판단한다. 플레이어의 손패나 덱 순서는 보지 않는다
- 턴 시간 제한이 없다

## 상대

`data/tables/opponent.csv` 기준이다. 게임 속 소개 열은 게임 화면에 나오는 문구를 그대로 옮겼다.

| 순서 | 상대 | 영웅 체력 | 게임 속 소개 | 처음 이기면 들어오는 카드 |
|---|---|---|---|---|
| 1 | 수련생 미로(연습 상대) | 14 | "교환은 몰라도 영웅만 노리는 수련생. 영웅 체력이 낮아요" | 번개 창, 새벽 기사, 통찰 |
| 2 | 숲의 파수꾼 타라 | 18 | "수호 하수인으로 버티다 큰 나무로 밀어붙여요" | 화염 폭풍, 전쟁 북잡이, 화염 비룡 |
| 3 | 대마법사 벨로크 | 25 | "주문으로 판을 쓸어내는 사다리의 끝" | 하늘 거신, 잿빛 망령, 고목 수호자 |

## 시작하기

이 저장소는 open-game-works 워크스페이스 안에서 하네스 옆에 두고 쓴다.

```
<workspace>/
  open-game-works-core/                    하네스 (여기서 Claude Code나 Codex를 실행)
  open-game-works-core-impl/               코어 소스
  open-game-works-core-releases/           받아 온 코어 릴리스 (도구가 만듦)
  games/open-game-works-game-mana-clash/   이 저장소
```

1. [하네스 README](https://github.com/wnsrn3436/open-game-works-core/blob/main/README.ko.md#빠른-시작)의 빠른 시작대로 워크스페이스와
   하네스를 준비한다
2. 이 저장소를 `games/`에 클론하고 데이터 도구가 읽는 로컬 `id-registry` 브랜치를 만든다

   ```
   cd <workspace>/games
   git clone https://github.com/wnsrn3436/open-game-works-game-mana-clash.git
   cd open-game-works-game-mana-clash
   git branch id-registry origin/id-registry
   ```

3. 클론한 뒤 `open-game-works-core/`의 Claude Code 세션에서 `update env`를 실행한다. 전에 실행했더라도 다시 한다.
   `update env`는 `games/`에 있는 각 게임의 코어 릴리스가 정한 엔진 버전도 설치한다
4. 게임을 직접 플레이하려면 터미널에서 인스턴스를 띄우고 다 하면 멈춘다

   ```
   cd <workspace>/open-game-works-core
   tools/bin/ogw instance start open-game-works-game-mana-clash
   # id: <instance id>
   # address: <server URL>
   tools/bin/ogw instance stop <instance id>
   ```

5. 게임을 고치려면 Claude Code 세션에 `update game: open-game-works-game-mana-clash <request>`를 입력한다. 그 전에 참고
   게임 플레이 영상을 제자리에 넣는다([참고 영상](#참고-영상) 참고)

다른 명령과 옵션은 [게임 작업하기](#게임-작업하기)에 있다.

## 만든 과정

이 게임은 AI 에이전트가 open-game-works 하네스로 만들었다. 사람은 `setup game`에서 요청과 참고 게임, 참고 게임
플레이 영상을 주고 `create game`을 시작했다. 그 뒤로는 리드 에이전트(lead agent)가 사람을 기다리지 않고 루프를 끝까지
돌렸다. 콘텐츠 에이전트(content agent)가 고치고 자동 검사가 돈 다음, 플레이 에이전트(play agent)가 실제 입력으로
인스턴스를 플레이한다. 판정 에이전트(judge agent)가 결과를 기준 게임(baseline) 및 참고 게임 플레이 영상과 비교하면
하네스 도구가 심사 결과와 자동 검사 결과로 성공을 판정한다.

| 부분 | 만든 주체 |
|---|---|
| `brief.md`, `design.md`, `play-guide.md`, 클라이언트와 서버의 콘텐츠 코드, 씬, 프리팹, 트윈 프리셋, 데이터, 계약, 회귀 테스트, 봇 플레이테스트 시나리오 | 콘텐츠 에이전트 |
| 이미지, 아이콘, 배경, 음악, 효과음, 파티클, 폰트 | 리소스 서브 에이전트(resource sub-agent). 하네스 설정의 생성 방법을 사용 |
| 영어 번역 | 번역 서브 에이전트(translation sub-agent) |
| `client/core/`, `server/core/` | 코어 릴리스(콘텐츠 에이전트는 코어를 고치지 않음) |

`brief.md`, `design.md`, `play-guide.md`는 콘텐츠 에이전트가 한국어로 썼고 `create game` 루프가 끝난 뒤 영어로
옮겼다.

`resource/resources.csv`의 모든 리소스는 상태가 `final`이다. 사용한 생성 방법은 다음과 같다.

| 리소스 | 개수 | 방법 | 종류 | 기록된 `license` |
|---|---|---|---|---|
| 이미지, 아이콘, 배경, 나인 슬라이스 프레임, 앱 아이콘, 스플래시 | 44 | `flux2-klein` | 로컬 모델 | Apache-2.0 |
| 배경 음악 | 2 | `ace-step` | 로컬 모델 | MIT |
| 효과음 | 16 | `moss-sfx` | 로컬 모델 | Apache-2.0 |
| 파티클 | 5 | `procedural` | 절차적 생성 | LicenseRef-game-owned |
| 폰트(Noto Sans KR) | 1 | `font-catalog` | 고정된 카탈로그 | OFL-1.1 |
| 씬, 프리팹, 트윈 프리셋 | 45 | 콘텐츠 에이전트가 작성 | | |

루프에서 이 게임은 `client/tests/`와 `server/tests/`의 회귀 테스트, 봇 플레이테스트 시나리오
`client/dev/bot/scenario.json`, 행 시뮬레이션(row simulation)으로 검사한다. 행 시뮬레이션에서는 봇이 각 상대와
대전하고 승률, 턴 수, 피해를 `data/tables/opponent.csv`의 `sim_` 열과 비교한다.

## 동작 방식

대전 한 판은 코어 모듈 `play-session`의 실행 한 번이다. 게임 자체의 RPC는 없고 서버 콘텐츠 코드
(`server/main.ts`, `server/hooks/play_session.ts`)가 이 모듈의 훅 세 개를 등록한다.

```
client (Godot, client/)                         server (TypeScript, server/)

title -> lobby -> battle
StartPlaySession (level_id = opponent) -------> prepare_play_session
                                                  상대가 있고 열려 있는지 확인
                <------- PlaySessionLoadout       플레이어 덱, 상대 덱, 시드
클라이언트 시뮬레이션에서 대전 진행
(BattleSim, BattleAi, 덱은 시드로 섞음)
FinishPlaySession (PlaySessionResult) --------> verify_play_session
                                                  값의 범위와 승패의 일관성 확인
                                                apply_play_session
                                                  전적, 연승, 첫 승리 보상 카드
                                                  -> ProgressUserState
```

- 상대가 열리는 규칙은 클라이언트 로비와 서버가 똑같이 쓰는 공유 공식(`lobby.opponent_unlocked`)이다. 그 픽스처는
  `data/fixtures/lobby.opponent_unlocked.json`이다
- 계약(`contract/`)은 `PlaySessionLoadout`, `PlaySessionResult`, `ProgressUserState`와 오류 코드
  `GAME_ERROR_OPPONENT_NOT_FOUND`, `GAME_ERROR_OPPONENT_LOCKED`를 정의한다

## 코어 버전

`settings.json`은 `coreVersion`을 **0.1.0**으로 고정한다. 이 버전은
[open-game-works-core-impl의 GitHub Release](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0)다.

- `client/core/`와 `server/core/`는 그 릴리스의 복사본이다
- 릴리스가 워크스페이스의 `open-game-works-core-releases/`에 없으면 하네스 도구가 GitHub에서 받아 와 파일을
  해시로 확인한다
- 이 버전은 Godot 4.7.2를 쓴다(릴리스의 `engine.json`)
- 게임이 고른 코어 모듈(`coreModules`): 클라이언트 `NativeUiCore`, `TweenCore`, `ScreenEffectCore`, 서버
  `play-session`
- `update game`은 먼저 `coreVersion`을 올릴 수 있는 가장 높은 코어 릴리스로 올린다

## 저장소 구성

| 경로 | 내용 |
|---|---|
| `brief.md` | 브리프: 플레이어 판타지, 감정, 받아들이거나 바꾼 장르 관습, 금지 사항, 실패 페널티, 참고 게임, 요청 |
| `design.md` | 디자인 문서: 핵심 루프, 조작, 화면, 대전 규칙, CPU, 사다리, 진행, 손맛과 튜닝 목표, 아트와 오디오 방향, 용어, 코어 사용 |
| `play-guide.md` | 플레이 에이전트와 판정 에이전트가 받는 플레이 가이드: 목표, 자동화 앵커가 붙은 조작, 게임 흐름, 입력이 막히는 구간, 플레이 모드 |
| `settings.json` | 게임 설정(스키마: 하네스의 `schemas/game-settings.schema.json`): 코어 버전, 엔진, 코어 모듈, 언어, 빌드 플랫폼, 해상도, UI 검사 화면, 환경 |
| `contract/` | protobuf 계약: `service.proto`, `user_state.proto`, `error.proto` |
| `data/` | CSV 테이블(`tables/`: `card.csv`, `deck.csv`, `opponent.csv`와 데이터 도구가 넣는 코어 데이터 테이블, `system/`: `game_setting.csv`와 예약 ID), `enums.csv`, `invariants.csv`, `simulation_tables.csv`, `glossary.csv`, `translations/`, `fixtures/` |
| `resource/` | 최종 리소스(이미지, 음악, 효과음, 폰트, 씬, 프리팹, 트윈 프리셋, 파티클)와, 리소스 키마다 방법, 출처, 라이선스를 적은 `resources.csv` |
| `client/` | Godot 프로젝트: `boot/`, `common/`, `features/`(`title`, `lobby`, 시뮬레이션이 `battle/sim/`에 있는 `battle`), `core/`(코어 릴리스), `generated/`(계약 도구와 데이터 도구의 출력), `dev/`(DEV 코드: 봇 플레이테스트 시나리오, 화면을 열고 상대 시뮬레이션을 돌리는 자동화 명령, 생성된 DEV 코드), `tests/`. `client/resource`는 `../resource`를 가리키는 링크 |
| `server/` | TypeScript 서버: `main.ts`, `hooks/play_session.ts`, `core/`(코어 릴리스), `generated/`, `dev/`, `tests/` |
| `records/` | 에이전트와 하네스 도구가 쓰는 작업 기록. 지금은 `records/setup/reference/reference.md`만 있음 |
| `LICENSE`, `LICENSES/` | 이 저장소의 라이선스 조건과, Apache-2.0 및 OFL-1.1을 따르는 부분의 라이선스 전문 |

ID 레지스트리는 별도 브랜치 `id-registry`(`id_registry.json`)에 있다. 이 브랜치에는 데이터 도구만 쓰고 다른
브랜치와 병합하지 않는다.

## 언어

- 원문은 한국어다. `settings.json`에 `sourceLanguage`가 없으므로 스키마 기본값 `ko`가 적용된다
- `supportedLanguages`는 `ko`와 `en`이다. `data/`의 텍스트 열에는 한국어 원문이 있고 `data/translations/ko.csv`와
  `data/translations/en.csv`에 번역 키별 텍스트가 있다. 영어 텍스트는 번역 서브 에이전트가 쓴다
- `data/glossary.csv`는 카드와 상대 이름, 게임 이름, 게임 용어(예: 수호, 결계, 돌격)의 번역을 고정한다
- `brief.md`, `design.md`, `play-guide.md`는 영어로 되어 있고 게임 속 한국어 텍스트는 코드 스팬으로 적고 옆에 영어
  뜻을 붙였다

## 게임 작업하기

모든 작업은 하네스를 통해 한다. `open-game-works-core/`에서 Claude Code나 Codex를 열고 명령을 입력한다.

| 명령 | 하는 일 |
|---|---|
| `update game: open-game-works-game-mana-clash <request>` | `coreVersion`을 올리고 작업 브랜치 `loop/<run>`에서 루프가 멈출 때까지 돌린 뒤, 고른 커밋을 `main`에 병합하고 보고한다. 플레이해 본 뒤의 피드백, 새 기능, 수정에 쓴다 |
| `build: open-game-works-game-mana-clash DEV [<platform>...] [--version <version>]` | 서버와 클라이언트의 콘텐츠 코드를 계약에 맞춰 하드닝하고 PostgreSQL로 검사와 심사를 한 번 더 돌린 뒤, 플랫폼별로 빌드하고(생략하면 `buildPlatforms` 전체) 커밋에 `dev-<version>` 태그를 붙이고 DEV 서버를 배포한다. 빌드 결과물은 커밋하지 않는 `builds/`에 생긴다 |
| `build: open-game-works-game-mana-clash STG` / `PROD` | STG와 PROD 빌드는 서명된 결과물까지 만든다. STG는 서버도 배포하고 PROD 배포는 사람이 한다 |

- `build`는 먼저 `settings.json`에 필요한 빌드 값(그 환경의 값과 어느 환경에도 속하지 않는 값)이 있는지 확인한다. 이
  저장소에는 아직 DEV 빌드 값(예: `appId`, `serverImage`, `environments.DEV.serverUrl`, `environments.DEV.deploy`)이
  없으므로, 첫 DEV 빌드 전에 리드 에이전트가 빠진 값을 묻는다
- 이 게임에서는 `create game`, `update game`, `build` 중 한 번에 하나만 실행된다
- `main`에는 언제나 루프를 통과한 최신 코드가 있다

### 인스턴스 실행

인스턴스는 LOCAL 환경에서 게임을 dev run으로 띄운 것이다. 인스턴스마다 SQLite를 쓰는 서버 프로세스가 따로 있고
외부 서비스는 가짜 어댑터가 대신한다. DEV 코드가 들어가고 Godot 클라이언트는 빌드 없이 프로젝트에서 바로 시작된다.
[시작하기](#시작하기)에서처럼 하네스 폴더에서 `tools/bin/ogw instance start`로 띄우고 `tools/bin/ogw instance stop`으로
멈춘다.

- `instance start`의 옵션: `--commit <sha>`(그 커밋의 워크트리에서 시작), `--platform <platform>`(생략하면
  `buildPlatforms`의 첫 항목), `--fixture <file>`(저장 픽스처), `--db postgresql`
- 클라이언트는 개발 계정으로 로그인하고 약관 팝업 없이 시작한다. 끝낸 대전이 아직 없으면 연습 상대와의 첫 대전이 바로
  열린다
- 동시에 띄울 수 있는 인스턴스 수는 하네스 설정의 `maxConcurrentInstances`로 제한된다

실행 중인 인스턴스에 쓰는 명령:

| 명령 | 하는 일 |
|---|---|
| `tools/bin/ogw capture <id> [--video <ms>]` | 화면을 캡처하거나, 그 길이만큼 영상을 남김 |
| `tools/bin/ogw log <id>` | 오류 로그를 보여 줌 |
| `tools/bin/ogw telemetry <id>` | 텔레메트리를 보여 줌 |
| `tools/bin/ogw input <id> <command> <argument...>` | 실제 입력 하나를 넣음(명령 목록은 `ogw input --help`) |
| `tools/bin/ogw command <id> list_commands` | 게임의 콘텐츠 명령을 설명, 인자와 함께 보여 줌 |

### 참고 영상

`brief.md`에는 참고 게임이 적혀 있고 루프에서 판정 에이전트는 이 게임을 참고 게임의 플레이 영상과 비교한다.
`records/setup/reference/reference.md`에는 영상 파일과 비교할 순간(처음 30초, 핵심 행동, 첫 실패, 첫 보상, 재시작)이
적혀 있다.

영상 파일은 저장소에 없다. `.gitignore`가 `records/setup/reference/`에서 `reference.md` 말고는 모든 파일을 git에서 뺀다. 판정 에이전트가 이 파일을
받으므로, `update game`이나 `build`를 실행하기 전에 `reference.md`의 `## video`에 적힌 파일을
`records/setup/reference/`에 넣는다. 각 파일 이름은 YouTube 영상 ID에 `.mp4`를 붙인 것이다. 파일마다 다음 명령을 한
번씩 실행하면 영상을 같은 폴더에 `<video id>.mp4`로 받아 온다. 호스트에 `yt-dlp`가 있어야 한다.

```
cd <workspace>/open-game-works-core
tools/bin/ogw game reference open-game-works-game-mana-clash https://www.youtube.com/watch?v=<video id>
```

### 요구 사항

하네스에 필요한 것 외에 이 게임에 필요한 것:

- 빌드 플랫폼은 `macos` 하나다(`buildPlatforms`). macOS 빌드는 Xcode가 있는 Mac에서 한다(코어 릴리스
  `engine.json`의 `buildTools`)
- Docker: 빌드와 `--db postgresql` 인스턴스는 PostgreSQL 컨테이너를 쓴다(`postgresqlMajor`는 18)

Windows: 이 저장소는 심볼릭 링크 `client/resource` -> `../resource`를 쓴다. 클론하기 전에 개발자 모드를 켜고
`git config --global core.symlinks true`를 실행해야 한다. 그렇지 않으면 링크가 일반 텍스트 파일로 체크아웃된다. 플레이
에이전트와 판정 에이전트는 macOS와 Linux에만 있는 샌드박스에서 돌기 때문에, 루프(`update game`)와 DEV·STG 빌드는
Windows에서 돌지 않는다. 주 호스트는 macOS다.

## 라이선스

자세한 조건은 [LICENSE](LICENSE)에 있다.

- 이 저장소에 있는 게임 고유의 콘텐츠(문서, 계약, 데이터, 콘텐츠 코드, 씬, 프리팹과 그 밖의 리소스)는
  [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.ko)을 따른다
- `client/core/`와 `server/core/`는 open-game-works 코어 릴리스의 복사본이며,
  [open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl)과 마찬가지로 Apache License
  2.0을 그대로 따른다([LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt))
- 함께 들어 있는 폰트 `resource/font/main.ttf`(Noto Sans KR)는 SIL Open Font License 1.1을 그대로 따른다
  ([LICENSES/OFL-1.1-NotoSansKR.txt](LICENSES/OFL-1.1-NotoSansKR.txt))
- `resource/resources.csv`에는 리소스마다 만든 방법(`method`)과 사용한 모델이나 출처의 라이선스(`license`)가 적혀
  있고, 필요한 경우 출처와 저작자 표시도 있다
- `resource/resources.csv`에서 `LicenseRef-game-owned`로 표시된 리소스는 게임 자체의 절차적 생성으로 만든 것이며,
  게임 콘텐츠의 일부로서 그 라이선스(CC BY-NC-ND 4.0)를 따른다
- 클라이언트의 서드파티 구성 요소(Godot Engine과 거기 포함된 라이브러리, 코어 네이티브 UI 플러그인의 godot-cpp
  라이브러리, 그 플러그인이 쓰는 Android 라이브러리, 폰트)는 `client/generated/licenses.json`에 라이선스, 함께
  배포되는 플랫폼과 함께 나열되어 있다
