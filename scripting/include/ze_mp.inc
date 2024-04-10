#if defined __mp_included
	#endinput
#endif
#define __mp_included

/**
 * Give or remove Multi-Jumps for specific player.
 *
 * @param id     Client index.
 * @param bSet   true = Give Multi-Jumps | false = Otherwise.
 *
 * @return       true  | If player got Multi-Jumps.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_set_user_multijump(id, bool:bSet);

/**
 * Give or remove Parachute for specific player.
 *
 * @param id      Client index.
 * @param bSet    true = Give Parachute | false = Otherwise.
 *
 * @return        true  | If player got Parachute.
 *                false | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_set_user_parachute(id, bool:bSet);