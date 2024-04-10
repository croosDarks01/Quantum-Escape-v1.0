#include <amxmodx>
#include <ze_core>

// Cvars.
new bool:g_bEnabled,
	Float:g_flCmdDelay

// Array.
new Float:g_flDelayUse[MAX_PLAYERS+1]

public plugin_natives()
{
	register_native("ze_reset_user_score", "__native_reset_user_score")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Reset Score", "0.1", "z0h1r-LK")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_rs_enable", "1"), g_bEnabled)
	bind_pcvar_float(register_cvar("ze_rs_cooldown", "60.0"), g_flCmdDelay)

	// Commands.
	register_clcmd("say /rs", "cmd_ResetScore")
	register_clcmd("say /resetscore", "cmd_ResetScore")
	register_clcmd("say_team /rs", "cmd_ResetScore")
	register_clcmd("say_team /resetscore", "cmd_ResetScore")
}

public cmd_ResetScore(const id)
{
	if (!g_bEnabled)
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "MSG_RS_DISABLED")
		return PLUGIN_HANDLED_MAIN
	}

	if (g_flCmdDelay > 0.0)
	{
		new Float:flHlTime = get_gametime()

		if (g_flDelayUse[id] > flHlTime)
		{
			ze_colored_print(id, "%L", LANG_PLAYER, "MSG_RS_COOLDOWN", g_flDelayUse[id] - flHlTime)
			return PLUGIN_HANDLED_MAIN
		}

		g_flDelayUse[id] = flHlTime + g_flCmdDelay
	}

	// Reset player Frags and Deaths.
	ze_add_user_frags(id, 0, false)
	ze_add_user_deaths(id, 0, false)

	// Send colored message on chat to player.
	ze_colored_print(id, "%L", LANG_PLAYER, "MSG_RS_SUCCESS")
	return PLUGIN_CONTINUE
}

/**
 * -=| Native |=-
 */
public __native_reset_user_score(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	cmd_ResetScore(id)
	return true
}