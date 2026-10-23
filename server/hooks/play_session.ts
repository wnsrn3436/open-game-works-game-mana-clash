import type { ApplyHook, PlaySessionRecord, PrepareHook, VerifyHook } from '../core/play-session/index.ts';
import type { RequestCtx, StorageContent } from '../core/storage/index.ts';
import * as GameContract from '../generated/contract/game_contract.ts';
import type * as GameData from '../generated/data/game_data.ts';

/** Whether the opponent of ladder `order` is open: the first one always, any other once the one before it is beaten. */
// ogw:shared lobby.opponent_unlocked
export function opponent_unlocked(order: number, cleared_orders: readonly number[]): boolean {
  return order <= 1 || cleared_orders.includes(order - 1);
}

/** `deck` with the first-win reward of `opponent`: each removed card is replaced by its added card at the same place. */
export function rewarded_deck(deck: readonly number[], opponent: GameData.OpponentRow): number[] {
  const out = [...deck];
  const count = Math.min(opponent.reward_cards.length, opponent.reward_removes.length);
  for (let i = 0; i < count; i += 1) {
    const at = out.indexOf(opponent.reward_removes[i] ?? 0);
    if (at >= 0) out[at] = opponent.reward_cards[i] ?? 0;
  }
  return out;
}

function progress_of(storage: StorageContent, ctx: RequestCtx): GameContract.ProgressUserState | null {
  return storage.get_state(ctx, GameContract.ProgressUserState, 0n) as GameContract.ProgressUserState | null;
}

/** The ladder `order` of every beaten opponent still in the data. */
function cleared_orders(ctx: RequestCtx, state: GameContract.ProgressUserState | null): number[] {
  if (state === null) return [];
  return state.cleared_opponent_ids.filter((id) => ctx.data.OpponentTable.has_row(id)).map((id) => ctx.data.OpponentTable.get_row(id).order);
}

/** The player deck: the stored deck, or the `[starter_deck]` row before the first reward. */
function deck_of(ctx: RequestCtx, state: GameContract.ProgressUserState | null): number[] {
  if (state !== null && state.deck_card_ids.length > 0) return [...state.deck_card_ids];
  return [...ctx.data.DeckTable.get_row(ctx.data.ReservedId.starter_deck()).cards];
}

/**
 * `prepare_play_session`: a battle against the opponent `level_id`. It must be an `opponent` row whose ladder place is
 * open. The loadout holds both decks and the shuffle seed.
 */
export function prepare_battle(storage: StorageContent): PrepareHook {
  return (ctx: RequestCtx, _mode_id: number, level_id: number) => {
    if (!ctx.data.OpponentTable.has_row(level_id)) return GameContract.GameError.GAME_ERROR_OPPONENT_NOT_FOUND;
    const opponent = ctx.data.OpponentTable.get_row(level_id);
    const state = progress_of(storage, ctx);
    if (!opponent_unlocked(opponent.order, cleared_orders(ctx, state))) return GameContract.GameError.GAME_ERROR_OPPONENT_LOCKED;
    const loadout = new GameContract.PlaySessionLoadout();
    loadout.opponent_id = level_id;
    loadout.player_deck_ids = deck_of(ctx, state);
    loadout.opponent_deck_ids = [...ctx.data.DeckTable.get_row(opponent.deck).cards];
    loadout.seed = BigInt(storage.random_u32(ctx));
    return loadout.encode();
  };
}

/**
 * `verify_play_session`: the result fits the battle. Turns are 1 to `[max_turns]`, each hero health is at most its
 * start health, a win has the opponent hero at 0 and the player hero above 0 without a surrender, a loss has the
 * player hero at 0, a surrender, or the turn limit, and the player played at most `[deck_size]` cards. The battle is
 * not simulated again; it only counts in the record and gives the fixed first-win reward of the opponent row.
 */
export const verify_battle: VerifyHook = (ctx: RequestCtx, record: PlaySessionRecord, result: Uint8Array) => {
  const decoded = GameContract.PlaySessionResult.decode(result);
  if (decoded === null || !ctx.data.OpponentTable.has_row(record.level_id)) return 'reject';
  const opponent = ctx.data.OpponentTable.get_row(record.level_id);
  const max_turns = ctx.data.GameSetting.max_turns();
  if (decoded.turns < 1 || decoded.turns > max_turns) return 'reject';
  if (decoded.player_health > ctx.data.GameSetting.hero_health() || decoded.opponent_health > opponent.hero_health) return 'reject';
  if (decoded.cards_played > ctx.data.GameSetting.deck_size()) return 'reject';
  if (decoded.won) {
    if (decoded.conceded || decoded.opponent_health !== 0 || decoded.player_health === 0) return 'reject';
  } else if (!decoded.conceded && decoded.player_health !== 0 && decoded.turns !== max_turns) {
    return 'reject';
  }
  return 'pass';
};

/**
 * `apply_play_session`: counts the verified battle in `ProgressUserState`: a win or a loss and the win streak. The
 * first win against an opponent marks it beaten and swaps its reward cards into the deck. `FinishPlaySession` runs
 * this once per play session.
 */
export function apply_battle(storage: StorageContent): ApplyHook {
  return (ctx: RequestCtx, record: PlaySessionRecord, result: Uint8Array) => {
    const decoded = GameContract.PlaySessionResult.decode(result);
    if (decoded === null) return GameContract.GameError.GAME_ERROR_UNSPECIFIED;
    const stored = progress_of(storage, ctx);
    const next = new GameContract.ProgressUserState();
    next.wins = stored?.wins ?? 0;
    next.losses = stored?.losses ?? 0;
    next.win_streak = stored?.win_streak ?? 0;
    next.cleared_opponent_ids = [...(stored?.cleared_opponent_ids ?? [])];
    next.deck_card_ids = deck_of(ctx, stored);
    if (decoded.won) {
      next.wins += 1;
      next.win_streak += 1;
      if (!next.cleared_opponent_ids.includes(record.level_id)) {
        next.cleared_opponent_ids.push(record.level_id);
        next.deck_card_ids = rewarded_deck(next.deck_card_ids, ctx.data.OpponentTable.get_row(record.level_id));
      }
    } else {
      next.losses += 1;
      next.win_streak = 0;
    }
    storage.put_state(ctx, next);
    return 'pass';
  };
}
