#include <amxmodx>
#include <ze_core>

// HUD Positions
const Float:HUD_X = -1.0
const Float:HUD_Y = 0.55

enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Cvars.
new bool:g_bEnabled,
	g_iHumanColors[Colors],
	g_iZombieColors[Colors]

// Variables.
new g_iSyncHUDMsg

// Array
new Float:g_flCooldownTime[MAX_PLAYERS+1]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Addon: Target Information's", "1.2", "z0h1r-LK")

	// Events.
	register_event("StatusValue", "fw_ShowStatus_Event", "be", "1=2", "2!0")

	// Message.
	register_message(get_user_msgid("StatusValue"), "fw_StatusValue_Message")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_target_info", "1"), g_bEnabled)
	bind_pcvar_num(register_cvar("ze_target_info_human_red", "0"), g_iHumanColors[Red])
	bind_pcvar_num(register_cvar("ze_target_info_human_green", "100"), g_iHumanColors[Green])
	bind_pcvar_num(register_cvar("ze_target_info_human_blue", "200"), g_iHumanColors[Blue])
	bind_pcvar_num(register_cvar("ze_target_info_zombie_red", "200"), g_iZombieColors[Red])
	bind_pcvar_num(register_cvar("ze_target_info_zombie_green", "0"), g_iZombieColors[Green])
	bind_pcvar_num(register_cvar("ze_target_info_zombie_blue", "0"), g_iZombieColors[Blue])

	// Initial Value.
	g_iSyncHUDMsg = CreateHudSyncObj()
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	g_flCooldownTime[id] = 0.0
}

public fw_StatusValue_Message(const id)
{
	if (g_bEnabled)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_ShowStatus_Event(const id)
{
	if (!g_bEnabled)
		return

	static Float:flHlTime; flHlTime = get_gametime()

	if (g_flCooldownTime[id] > flHlTime)
		return

	static cl; cl = read_data(2)

	// Player disconnected?
	if (!is_user_connected(cl))
		return

	static szName[MAX_NAME_LENGTH], iClientTeam, iTargetTeam, iHP, iEC, iSP

	iHP = get_user_health(cl)
	iSP = get_user_armor(cl)
	iEC = ze_get_user_coins(cl)
	get_user_name(cl, szName, charsmax(szName))

	iClientTeam = get_member(id, m_iTeam)
	iTargetTeam = get_member(cl, m_iTeam)

	ClearSyncHud(id, g_iSyncHUDMsg)

	if (iClientTeam == ZE_TEAM_HUMAN && iTargetTeam == ZE_TEAM_HUMAN)
	{
		set_hudmessage(g_iHumanColors[Red], g_iHumanColors[Green], g_iHumanColors[Blue], HUD_X, HUD_Y, 0, 3.0, 3.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_TARGET_INFO_1", szName, iHP, iSP, iEC)
	}
	else if (iClientTeam == ZE_TEAM_ZOMBIE && iTargetTeam == ZE_TEAM_ZOMBIE)
	{
		set_hudmessage(g_iZombieColors[Red], g_iZombieColors[Green], g_iZombieColors[Blue], HUD_X, HUD_Y, 0, 3.0, 3.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_TARGET_INFO_1", szName, iHP, iSP, iEC)
	}
	else if (iClientTeam == ZE_TEAM_HUMAN && iTargetTeam == ZE_TEAM_ZOMBIE)
	{
		set_hudmessage(g_iZombieColors[Red], g_iZombieColors[Green], g_iZombieColors[Blue], HUD_X, HUD_Y, 0, 3.0, 3.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_TARGET_INFO_2", szName)
	}
	else if (iClientTeam == ZE_TEAM_ZOMBIE && iTargetTeam == ZE_TEAM_HUMAN)
	{
		set_hudmessage(g_iHumanColors[Red], g_iHumanColors[Green], g_iHumanColors[Blue], HUD_X, HUD_Y, 0, 3.0, 3.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_TARGET_INFO_2", szName)
	}

	// Cooldown time (to avoid SZ_GetSpace).
	g_flCooldownTime[id] = flHlTime + 0.1
}