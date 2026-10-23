import { randomUUID } from 'node:crypto';
import * as Testing from '../core/testing/dev/index.ts';
import * as CoreContract from '../generated/contract/core_contract.ts';
import * as GameContract from '../generated/contract/game_contract.ts';
import { opponent_unlocked, rewarded_deck } from '../hooks/play_session.ts';

const LOADED = Testing.load_data();
const DATA = LOADED.data;
const MODE = LOADED.dev.find_id_value('[mode_battle]');
const MIN_DURATION = DATA.PlaySessionModeTable.get_row(MODE).min_duration;
const MAX_TURNS = DATA.GameSetting.max_turns();
const HERO_HEALTH = DATA.GameSetting.hero_health();
const DECK_SIZE = DATA.GameSetting.deck_size();
const STARTER = [...DATA.DeckTable.get_row(DATA.ReservedId.starter_deck()).cards];
/** Opponents in ladder order. */
const LADDER = [...DATA.OpponentTable.all_rows()].sort((a, b) => a.order - b.order);
function rung(index: number): (typeof LADDER)[number] {
  const row = LADDER[index];
  if (row === undefined) throw new Error(`the ladder has no opponent ${String(index + 1)}`);
  return row;
}
const FIRST = rung(0);
const SECOND = rung(1);

function code(envelope: CoreContract.ResponseEnvelope): number {
  return envelope.error?.code ?? 0;
}

interface ResultInput {
  won: boolean;
  conceded?: boolean;
  turns?: number;
  player_health?: number;
  opponent_health?: number;
  cards_played?: number;
}

function result(input: ResultInput): Uint8Array {
  const out = new GameContract.PlaySessionResult();
  out.won = input.won;
  out.conceded = input.conceded ?? false;
  out.turns = input.turns ?? 9;
  out.player_health = input.player_health ?? (input.won ? 7 : 0);
  out.opponent_health = input.opponent_health ?? (input.won ? 0 : 4);
  out.cards_played = input.cards_played ?? 8;
  return out.encode();
}

async function start(session: Testing.TestSession, level_id: number): Promise<Testing.SendResult> {
  const request = new CoreContract.StartPlaySessionRequest();
  request.mode_id = MODE;
  request.level_id = level_id;
  return Testing.send(session, 'core/StartPlaySession', request);
}

function finish(session: Testing.TestSession, play_session_id: string, bytes: Uint8Array, request_id?: string): Promise<Testing.SendResult> {
  const request = new CoreContract.FinishPlaySessionRequest();
  request.play_session_id = play_session_id;
  request.result = bytes;
  return Testing.send(session, 'core/FinishPlaySession', request, request_id);
}

async function progress(server: Testing.TestServer, user_id: bigint): Promise<GameContract.ProgressUserState | null> {
  const item = (await Testing.read_user_state(server, user_id)).find((entry) => entry.kind === 'ProgressUserState');
  return item === undefined ? null : (item.value as GameContract.ProgressUserState);
}

function loadout_of(sent: Testing.SendResult): GameContract.PlaySessionLoadout {
  const response = sent.response as CoreContract.StartPlaySessionResponse;
  const loadout = GameContract.PlaySessionLoadout.decode(response.loadout);
  if (loadout === null) throw new Error('the loadout does not decode');
  return loadout;
}

describe('opponent unlock shared formula', () => {
  it('matches every case of the shared fixture', () => {
    const fixture = JSON.parse(new TextDecoder().decode(Testing.read_shared_fixture('lobby.opponent_unlocked'))) as {
      cases: { name: string; input: { order: number; cleared_orders: number[] }; expected: boolean }[];
    };
    expect(fixture.cases.length).toBeGreaterThan(0);
    for (const entry of fixture.cases) {
      expect(opponent_unlocked(entry.input.order, entry.input.cleared_orders)).toBe(entry.expected);
    }
  });
});

describe('CPU battle play session', () => {
  let server: Testing.TestServer;
  let accounts = 0;

  beforeEach(async () => {
    server = await Testing.start_test_server();
  });

  afterEach(async () => {
    await Testing.stop_test_server(server);
  });

  async function player(): Promise<Testing.TestSession> {
    accounts += 1;
    return Testing.login(server, `battle_${String(accounts)}`);
  }

  async function played(session: Testing.TestSession, level_id: number, bytes: Uint8Array, request_id?: string): Promise<Testing.SendResult> {
    const started = await start(session, level_id);
    expect(code(started.envelope)).toBe(0);
    Testing.advance_time(server, MIN_DURATION);
    return finish(session, (started.response as CoreContract.StartPlaySessionResponse).play_session_id, bytes, request_id);
  }

  it('starts the first opponent with the starter deck, the opponent deck and a seed', async () => {
    const session = await player();
    const sent = await start(session, FIRST.id);
    expect(code(sent.envelope)).toBe(0);
    const loadout = loadout_of(sent);
    expect(loadout.opponent_id).toBe(FIRST.id);
    expect(loadout.player_deck_ids).toEqual(STARTER);
    expect(loadout.opponent_deck_ids).toEqual([...DATA.DeckTable.get_row(FIRST.deck).cards]);
    expect(await progress(server, session.user_id)).toBeNull();
  });

  it('refuses an opponent that is not an opponent row and one whose place is still locked', async () => {
    const session = await player();
    expect(code((await start(session, 0)).envelope)).toBe(GameContract.GameError.GAME_ERROR_OPPONENT_NOT_FOUND);
    expect(code((await start(session, MODE)).envelope)).toBe(GameContract.GameError.GAME_ERROR_OPPONENT_NOT_FOUND);
    expect(code((await start(session, SECOND.id)).envelope)).toBe(GameContract.GameError.GAME_ERROR_OPPONENT_LOCKED);
    expect(await progress(server, session.user_id)).toBeNull();
  });

  it('counts the first win, marks the opponent beaten, swaps its reward cards in and opens the next opponent', async () => {
    const session = await player();
    const sent = await played(session, FIRST.id, result({ won: true }));
    expect(code(sent.envelope)).toBe(0);
    const expected_deck = rewarded_deck(STARTER, FIRST);
    expect(expected_deck).toHaveLength(DECK_SIZE);
    for (const card of FIRST.reward_cards) expect(expected_deck).toContain(card);
    const stored = await progress(server, session.user_id);
    expect(stored?.wins).toBe(1);
    expect(stored?.losses).toBe(0);
    expect(stored?.win_streak).toBe(1);
    expect(stored?.cleared_opponent_ids).toEqual([FIRST.id]);
    expect(stored?.deck_card_ids).toEqual(expected_deck);
    const entry = sent.envelope.user_state?.entries.find((e) => e.kind === 'ProgressUserState');
    expect(entry).toBeDefined();
    const next = await start(session, SECOND.id);
    expect(code(next.envelope)).toBe(0);
    expect(loadout_of(next).player_deck_ids).toEqual(expected_deck);
  });

  it('gives the reward of an opponent only on the first win', async () => {
    const session = await player();
    await played(session, FIRST.id, result({ won: true }));
    const again = await played(session, FIRST.id, result({ won: true }));
    expect(code(again.envelope)).toBe(0);
    const stored = await progress(server, session.user_id);
    expect(stored?.wins).toBe(2);
    expect(stored?.win_streak).toBe(2);
    expect(stored?.cleared_opponent_ids).toEqual([FIRST.id]);
    expect(stored?.deck_card_ids).toEqual(rewarded_deck(STARTER, FIRST));
  });

  it('counts a loss and a surrender, ends the streak and keeps the deck', async () => {
    const session = await player();
    await played(session, FIRST.id, result({ won: true }));
    expect(code((await played(session, SECOND.id, result({ won: false }))).envelope)).toBe(0);
    expect(code((await played(session, SECOND.id, result({ won: false, conceded: true, player_health: 5 }))).envelope)).toBe(0);
    const stored = await progress(server, session.user_id);
    expect(stored?.wins).toBe(1);
    expect(stored?.losses).toBe(2);
    expect(stored?.win_streak).toBe(0);
    expect(stored?.cleared_opponent_ids).toEqual([FIRST.id]);
  });

  it('counts a battle that reached the turn limit as a loss', async () => {
    const session = await player();
    const sent = await played(session, FIRST.id, result({ won: false, turns: MAX_TURNS, player_health: 3, opponent_health: 2 }));
    expect(code(sent.envelope)).toBe(0);
    expect((await progress(server, session.user_id))?.losses).toBe(1);
  });

  it('rejects results that do not fit the battle and keeps the record', async () => {
    const session = await player();
    const bad = [
      result({ won: true, opponent_health: 1 }),
      result({ won: true, player_health: 0 }),
      result({ won: true, conceded: true }),
      result({ won: false, player_health: 4 }),
      result({ won: true, turns: 0 }),
      result({ won: true, turns: MAX_TURNS + 1 }),
      result({ won: true, player_health: HERO_HEALTH + 1 }),
      result({ won: false, opponent_health: FIRST.hero_health + 1 }),
      result({ won: true, cards_played: DECK_SIZE + 1 }),
    ];
    for (const bytes of bad) {
      const sent = await played(session, FIRST.id, bytes);
      expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_REJECTED);
    }
    expect(await progress(server, session.user_id)).toBeNull();
  });

  it('refuses a battle that ends before the minimum duration', async () => {
    const session = await player();
    const started = await start(session, FIRST.id);
    Testing.advance_time(server, MIN_DURATION - 1n);
    const sent = await finish(session, (started.response as CoreContract.StartPlaySessionResponse).play_session_id, result({ won: true }));
    expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_TOO_FAST);
    expect(await progress(server, session.user_id)).toBeNull();
  });

  it('refuses result values outside the field range without a hook call', async () => {
    const session = await player();
    const sent = await played(session, FIRST.id, result({ won: true, turns: -1 }));
    expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_INVALID_REQUEST);
    expect(await progress(server, session.user_id)).toBeNull();
  });

  it('answers a resent finish with the stored response and counts the battle once', async () => {
    const session = await player();
    const started = await start(session, FIRST.id);
    Testing.advance_time(server, MIN_DURATION);
    const id = (started.response as CoreContract.StartPlaySessionResponse).play_session_id;
    const request_id = randomUUID();
    const first = await finish(session, id, result({ won: true }), request_id);
    const again = await finish(session, id, result({ won: true }), request_id);
    expect(code(first.envelope)).toBe(0);
    expect(code(again.envelope)).toBe(0);
    const stored = await progress(server, session.user_id);
    expect(stored?.wins).toBe(1);
    expect(stored?.cleared_opponent_ids).toEqual([FIRST.id]);
  });

  it('counts one of two concurrent finishes of the same play session', async () => {
    const session = await player();
    const started = await start(session, FIRST.id);
    Testing.advance_time(server, MIN_DURATION);
    const id = (started.response as CoreContract.StartPlaySessionResponse).play_session_id;
    const results = await Promise.all([finish(session, id, result({ won: true })), finish(session, id, result({ won: true }))]);
    expect(results.map((r) => code(r.envelope)).sort()).toEqual([0, CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_NOT_FOUND].sort());
    expect((await progress(server, session.user_id))?.wins).toBe(1);
  });
});
