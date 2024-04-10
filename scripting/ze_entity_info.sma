#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <ze_core>

// Cvars.
new bool:g_bButtonInfo,
	bool:g_bBreakMessage

// String.
new g_szName[MAX_PLAYERS+1][MAX_NAME_LENGTH]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Entity Info", "1.0", "z0h1r-LK")

	// Hams.
	RegisterHam(Ham_Use, "func_button", "fw_ButtonUsed_Post", 1)
	RegisterHam(Ham_Use, "func_rot_button", "fw_ButtonUsed_Post", 1)
	RegisterHam(Ham_Use, "button_target", "fw_ButtonUsed_Post", 1)

	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_BreakDamage_Post", 1)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_button_info", "1"), g_bButtonInfo)
	bind_pcvar_num(register_cvar("ze_break_message", "1"), g_bBreakMessage)
}

public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	get_user_name(id, g_szName[id], charsmax(g_szName[]))
}

public client_infochanged(id)
{
	// Player disconnected?
	if (!is_user_connected(id) || is_user_hltv(id))
		return

	// Get new name of the player.
	get_user_info(id, "name", g_szName[id], charsmax(g_szName[]))
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	g_szName[id] = NULL_STRING
}

public fw_ButtonUsed_Post(iEnt, idCaller)
{
	if (!g_bButtonInfo)
		return

	if (is_nullent(iEnt) || !is_user_connected(idCaller))
		return

	static Float:flHlTime; flHlTime = get_gametime()
	if (get_entvar(iEnt, var_fuser3) > flHlTime)
		return

	// Send colored message on chat for everyone.
	ze_colored_print(0, "%L", LANG_PLAYER, "MSG_BUTTON_INFO", g_szName[idCaller], iEnt)
	set_entvar(iEnt, var_fuser3, flHlTime + get_ent_data_float(iEnt, "CBaseToggle", "m_flWait"))
}

public fw_BreakDamage_Post(iEnt, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	if (!g_bBreakMessage)
		return

	// Invalid entity?
	if (is_nullent(iEnt) || !is_user_connected(iAttacker))
		return

	if (get_entvar(iEnt, var_health) <= 0.0)
	{
		// Send colored message on chat for everyone.
		ze_colored_print(0, "%L", LANG_PLAYER, "MSG_BREAK_INFO", g_szName[iAttacker], iEnt)
	}
}