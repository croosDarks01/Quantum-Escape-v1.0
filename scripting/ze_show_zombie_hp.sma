#include <amxmodx>
#include <reapi>
#include <ze_core>

// HUD Positions.
const Float:HUD_X = -1.0
const Float:HUD_Y = 0.3

// Cvars.
new g_iHUDType,
	g_iHUDStyle,
	Float:g_flInterval

// Variable.
new g_iSyncHUDMsg

// Array.
new Float:g_flDelay[MAX_PLAYERS+1]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Addon: Show Zombie HP", "1.3", "Raheem|z0h1r-LK")

	// Hook Chain.
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Post", 1)

	// Cvars
	bind_pcvar_num(register_cvar("ze_hp_remain_mode", "0"), g_iHUDType)
	bind_pcvar_num(register_cvar("ze_hp_remain_style", "0"), g_iHUDStyle)
	bind_pcvar_float(register_cvar("ze_hp_remain_interval", "0.25"), g_flInterval)

	// Initial Value.
	g_iSyncHUDMsg = CreateHudSyncObj()
}

public client_disconnected(client, bool:drop, message[], maxlen)
{
	g_flDelay[client] = 0.0
}

public fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return

	static Float:flHlTime; flHlTime = get_gametime()

	if (g_flInterval > 0.0)
	{
		// Cooldown time.
		if (g_flDelay[iAttacker] > flHlTime)
			return

		g_flDelay[iAttacker] = flHlTime + g_flInterval
	}

	if (ze_is_user_zombie(iVictim) && !ze_is_user_zombie(iAttacker))
	{
		switch (g_iHUDType)
		{
			case 0: // Text Message.
			{
				switch (g_iHUDStyle)
				{
					case 0: // Text Message.
					{
						client_print(iAttacker, print_center, "%L", LANG_PLAYER, "HUD_HP_REMAIN", get_user_health(iVictim))
					}
					case 1: // HUD.
					{
						static szHP[16]
						AddCommas(get_user_health(iVictim), szHP, charsmax(szHP))
						client_print(iAttacker, print_center, "%L", LANG_PLAYER, "HUD_HP_REMAIN_COMMAS", szHP)

						// Reset string.
						szHP[0] = EOS
					}
				}
			}
			case 1: // HUD.
			{
				switch (g_iHUDStyle)
				{
					case 0:
					{
						set_hudmessage(200, 200, 200, HUD_X, HUD_Y, 0, 1.0, 1.0, 0.0, 0.0)
						ShowSyncHudMsg(iAttacker, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_HP_REMAIN", get_user_health(iVictim))
					}
					case 1:
					{
						static szHP[16]
						AddCommas(get_user_health(iVictim), szHP, charsmax(szHP))

						set_hudmessage(200, 200, 200, HUD_X, HUD_Y, 0, 1.0, 1.0, 0.0, 0.0)
						ShowSyncHudMsg(iAttacker, g_iSyncHUDMsg, "%L", LANG_PLAYER, "HUD_HP_REMAIN_COMMAS", szHP)

						// Reset string.
						szHP[0] = EOS
					}
				}
			}
		}
	}
}