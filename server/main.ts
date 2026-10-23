import type { ApplyHook, PrepareHook, VerifyHook } from './core/play-session/index.ts';
import type { StorageContent } from './core/storage/index.ts';
import { apply_battle, prepare_battle, verify_battle } from './hooks/play_session.ts';

/** The `core` object of `register`: the module objects this content uses. */
export interface RegisterCore {
  readonly routing: {
    register_hook(module: 'play-session', hook: 'prepare_play_session', fn: PrepareHook): void;
    register_hook(module: 'play-session', hook: 'verify_play_session', fn: VerifyHook): void;
    register_hook(module: 'play-session', hook: 'apply_play_session', fn: ApplyHook): void;
  };
  readonly storage: StorageContent;
}

/**
 * Registers the play-session hooks of the CPU battle. The game has no `service Game` `rpc`: a battle starts with the
 * core `StartPlaySession` (its `level_id` is the opponent) and ends with the core `FinishPlaySession`, whose hooks check
 * the result, count it in the record and give the first-win reward.
 */
export function register(core: RegisterCore): void {
  core.routing.register_hook('play-session', 'prepare_play_session', prepare_battle(core.storage));
  core.routing.register_hook('play-session', 'verify_play_session', verify_battle);
  core.routing.register_hook('play-session', 'apply_play_session', apply_battle(core.storage));
}
