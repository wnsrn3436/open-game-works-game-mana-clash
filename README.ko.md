# 마나 클래시

[English](README.md)

CPU 결투자와 일대일로 겨루는 macOS용 카드 배틀 게임. AI 에이전트가
[open-game-works](https://github.com/wnsrn3436/open-game-works-core)로 만들었다.

<p align="center"><img src=".github/media/mana-clash.gif" alt="mana-clash gameplay" width="720"></p>

## 직접 플레이하기

[하네스 README의 빠른 시작](https://github.com/wnsrn3436/open-game-works-core/blob/main/README.ko.md#빠른-시작)대로
open-game-works 워크스페이스를 준비한다. 그다음 이 저장소를 `games/`에 클론하고 데이터 도구가 읽는 로컬
`id-registry` 브랜치도 만든 뒤 인스턴스를 띄워 플레이한다.

```
cd <workspace>/games
git clone https://github.com/wnsrn3436/open-game-works-game-mana-clash.git
cd open-game-works-game-mana-clash
git branch id-registry origin/id-registry

cd <workspace>/open-game-works-core
tools/bin/ogw instance start open-game-works-game-mana-clash   # 인스턴스 id가 출력됨
tools/bin/ogw instance stop <instance id>
```

처음 `instance start`를 하기 전에는 이미 실행한 적이 있어도 하네스 세션에서 `update env`를 다시 실행한다. 이 게임의
엔진이 이때 설치된다.

## 게임 소개

플레이어는 결투 마법사가 되어 싱글 플레이 턴제 카드 배틀을 한다. 매 턴 마나로 하수인과 주문을 내고 하수인으로
공격한다. 상대 영웅의 체력이 0이 되면 이긴다. 남은 마나와 보드의 공격력으로 그 체력을 정확히 0으로 만드는 한 턴을
찾는 것이 목표다.

- **카드:** 20장(하수인 15장, 주문 5장)과 다섯 가지 키워드: 수호, 결계, 돌격, 등장 시, 소멸 시
- **상대:** CPU 결투자 세 명의 사다리: 수련생 미로(연습 상대, 영웅 체력 14), 숲의 파수꾼 타라(18), 대마법사
  벨로크(25). 상대를 이기면 다음 상대가 열린다
- **조작:** 마우스 클릭뿐이다(드래그 없음). `Esc`로 일시정지 팝업을 연다
- **규칙:** 영웅 체력 20, 덱 20장, 보드 한쪽당 5칸, 손패 최대 8장. 마나 수정은 매 턴 하나씩 늘어 최대 10개이고 매 턴
  가득 다시 채워진다. 플레이어가 항상 선공이다. 빈 덱에서 뽑을 때마다 1, 2, 3, ... 피해를 받고, 60턴을 넘긴 대전은
  패배로 끝난다. 영웅 능력, 무작위 대상 효과, 턴 시간 제한, 결제, 광고, 카드 팩, 가챠가 없다
- **진행:** 각 상대를 처음 이기면 정해진 새 카드 세 장이 20장짜리 덱에 들어오고 같은 수가 빠진다. 패배는 전적에
  1패를 더하고 연승을 끊을 뿐이다. `다시 도전`을 누르면 새 대전이 바로 시작된다

## 상태

개발하는 동안 macOS에서 플레이하며 확인했다. 아직 `build`를 실행하지 않아서 출시용 빌드는 없다.

## AI로 고치기

`open-game-works-core/`의 Claude Code(또는 Codex) 세션에 입력한다.

- `update game: open-game-works-game-mana-clash <request>`: 요청대로 루프를 돌리고 결과를 `main`에 병합한다
- `build: open-game-works-game-mana-clash DEV`: 게임을 빌드해 `dev-<version>` 태그를 붙이고 DEV 서버를 배포한다

먼저 참고 게임 플레이 영상을 제자리에 넣는다. 판정 에이전트가 이 영상과 게임을 비교하는데 영상은 git에 없다.
[reference.md](records/setup/reference/reference.md)의 `## video`에 적힌 파일마다 다음을 실행한다(`yt-dlp` 필요).

```
cd <workspace>/open-game-works-core
tools/bin/ogw game reference open-game-works-game-mana-clash https://www.youtube.com/watch?v=<video id>
```

### 첫 DEV 빌드 전에

- `settings.json`에는 아직 DEV 빌드 값(예: `appId`, `serverImage`, `environments.DEV.serverUrl`,
  `environments.DEV.deploy`)이 없다. 리드 에이전트가 빠진 값을 묻는다
- 빌드 플랫폼은 `macos` 하나다. 빌드에는 Xcode가 있는 Mac과, PostgreSQL 18 컨테이너를 띄울 Docker가 필요하다
- Windows: `client/resource`가 심볼릭 링크이므로 클론하기 전에 개발자 모드를 켜고
  `git config --global core.symlinks true`를 실행한다. 루프와 DEV·STG 빌드는 Windows에서 돌지 않는다

## 만든 방식

대전 한 판은 코어 모듈 `play-session`의 실행 한 번이다. Godot 클라이언트가 자체 시뮬레이션으로 대전 전체를 진행한다.
TypeScript 서버는 덱과 시드를 내주고 결과를 확인한 뒤 전적과 보상 카드를 저장한다. 코어는 `settings.json`의
`coreVersion`에 적힌 대로 [0.1.0](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0)으로
고정되어 있다. `client/core/`와 `server/core/`는 그 릴리스의 복사본이다.

```
client (Godot, client/)                     server (TypeScript, server/)
StartPlaySession (opponent) ------------->  prepare: 상대가 있고 열려 있는지 확인
            <---------- PlaySessionLoadout  플레이어 덱, 상대 덱, 시드
클라이언트 시뮬레이션에서 대전 진행
FinishPlaySession (result) -------------->  verify: 값의 범위와 승패의 일관성 확인
                                            apply: 전적, 연승, 첫 승리 보상 카드
```

| 경로 | 내용 |
|---|---|
| [brief.md](brief.md) | 플레이어 판타지, 받아들이거나 바꾼 장르 관습, 금지 사항, 참고 게임 |
| [design.md](design.md) | 디자인 문서: 규칙, 화면, CPU, 사다리, 튜닝, 아트와 오디오 방향 |
| [play-guide.md](play-guide.md) | 플레이 에이전트와 판정 에이전트용 가이드: 조작, 게임 흐름, 입력이 막히는 구간 |
| [settings.json](settings.json) | 코어 버전, 엔진, 코어 모듈, 언어, 플랫폼, 해상도 |
| [contract/](contract/) | 클라이언트와 서버 사이의 protobuf 계약 |
| [data/](data/) | CSV 테이블(카드, 덱, 상대, 설정), 번역, 픽스처 |
| [resource/](resource/) | 이미지, 음악, 효과음, 폰트, 씬, 프리팹, [resources.csv](resource/resources.csv) |
| [client/](client/) | Godot 프로젝트(타이틀, 로비, 시뮬레이션이 있는 대전)와 테스트 |
| [server/](server/) | `play-session`의 TypeScript 서버 훅과 테스트 |
| [records/](records/) | 작업 기록. 참고 게임 메모도 여기 있다 |

[open-game-works 하네스](https://github.com/wnsrn3436/open-game-works-core)로 만들었다.

## 라이선스

자세한 조건은 [LICENSE](LICENSE)에 있다.

| 부분 | 라이선스 |
|---|---|
| 게임 고유의 콘텐츠(문서, 계약, 데이터, 콘텐츠 코드, 씬, 프리팹과 그 밖의 리소스) | [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.ko) |
| `resource/resources.csv`에서 `LicenseRef-game-owned`로 표시된 리소스(게임 자체의 절차적 생성으로 만든 것) | 게임 콘텐츠의 일부: CC BY-NC-ND 4.0 |
| `client/core/`, `server/core/`: open-game-works 코어 릴리스의 복사본, [open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl)과 같음 | Apache License 2.0([LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt)) |
| `resource/font/main.ttf`(Noto Sans KR) | SIL Open Font License 1.1([LICENSES/OFL-1.1-NotoSansKR.txt](LICENSES/OFL-1.1-NotoSansKR.txt)) |

`resource/resources.csv`에는 리소스마다 만든 방법(`method`)과 사용한 모델이나 출처의 라이선스(`license`)가 적혀 있고,
필요한 경우 출처와 저작자 표시도 있다.

| 리소스 | 개수 | `method` | 기록된 `license` |
|---|---|---|---|
| 이미지, 아이콘, 배경, 나인 슬라이스 프레임, 앱 아이콘, 스플래시 | 44 | `flux2-klein`(로컬 모델) | Apache-2.0 |
| 배경 음악 | 2 | `ace-step`(로컬 모델) | MIT |
| 효과음 | 16 | `moss-sfx`(로컬 모델) | Apache-2.0 |
| 파티클 | 5 | `procedural` | LicenseRef-game-owned |
| 폰트(Noto Sans KR) | 1 | `font-catalog`(고정된 카탈로그) | OFL-1.1 |
| 씬, 프리팹, 트윈 프리셋 | 45 | 콘텐츠 에이전트가 작성 | |

클라이언트의 서드파티 구성 요소(Godot Engine과 거기 포함된 라이브러리, 코어 네이티브 UI 플러그인의 godot-cpp
라이브러리, 그 플러그인이 쓰는 Android 라이브러리, 폰트)는 `client/generated/licenses.json`에 라이선스, 함께 배포되는
플랫폼과 함께 나열되어 있다.
