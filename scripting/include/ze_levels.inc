#if defined __ze_levels_included
	#endinput
#endif
#define __ze_levels_included

/**
 * -=| Forwards |=-
 */

/**
 * Get player's XP point(s).
 *
 * @param id     Client index.
 *
 * @return       XP point(s) on success, NULLENT whel failure.
 *
 * @error        If player not on game.
 */
native ze_get_user_xp(id);

/**
 * Set or Add XP point(s) for player.
 *
 * @param id     Client index.
 * @param xp     XP point(s) to be add or set.
 * @param add    true = Add XP | false = Set XP.
 *
 * @return       true  | If operation successfully.
 *               false | If failure.
 *
 * @error        If player not on game.
 */
native ze_set_user_xp(id, xp, bool:add = false);

/**
 * Get player's Level.
 *
 * @note If the XP point(s) is greater than MAX XP,
 *       The native will advance the player to the next level.
 *
 * @param id     Client index.
 *
 * @return       true  | If operation successfully.
 *               false | If failure.
 *
 * @error        If player not on game.
 */
native ze_get_user_level(id);

/**
 * Set or Add Level for player.
 *
 * @param id     Client index.
 *
 * @return       Level on success, NULLENT when failure.
 *
 * @error        If player not on game.
 */
native ze_set_user_level(id, level, bool:add = false);

/**
 * Get player's Max XP for next Level.
 *
 * @param id      Client index.
 *
 * @return        MaxXP on success, NULLENT when failure.
 *
 * @error         If player not on game.
 */
native ze_get_user_maxxp(id);

/**
 * Set or Add Max XP for player.
 *
 * @param id      Client index.
 * @param maxxp   New MaxXP.
 * @param add     true = Add XP on MaxXP | false = Set Max XP.
 *
 * @return        true  | If operation successfully.
 *                false | If failure.
 *
 * @error         If player not on game.
 */
native ze_set_user_maxxp(id, maxxp, bool:add = false);



native ze_get_max_level();
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
