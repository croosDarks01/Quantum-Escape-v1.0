#include <ze_core>
#include <ze_levels>

// Variables
new Float:g_fDamage[33], g_iBestDefIndex

// Cvars
new cvar_show_chat_notice, cvar_give_xp, cvar_give_escape_coins, cvar_show_stats

public plugin_init()
{
	register_plugin("[ZE] Best Defender", "1.3", "Raheem")
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_TakeDamage_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	
	// Cvars
	cvar_show_chat_notice = register_cvar("ze_best_def_chat_notice", "1")
	cvar_give_xp = register_cvar("ze_best_def_give_xp", "40")
	cvar_give_escape_coins = register_cvar("ze_best_def_give_ec", "20")
	cvar_show_stats = register_cvar("ze_show_best_def_stats", "1")
	
	// Commands
	register_clcmd("say /mydamage", "Cmd_BestDefenderStats")
}

public Fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	if (!is_user_alive(iVictim) || !is_user_alive(iAttacker))
		return HC_CONTINUE
	
	g_fDamage[iAttacker] += fDamage
	return HC_CONTINUE
}

public ze_roundend()
{
	Get_Best_Defender()
}

public Cmd_BestDefenderStats(id)
{
	Get_Best_Defender()
	
	switch (get_pcvar_num(cvar_show_stats))
	{
		case 1:
		{
			if (id == g_iBestDefIndex)
			{
				ze_colored_print(id, "!tYou are now Best Defender !y[!g%d!y] !y:)", floatround(g_fDamage[g_iBestDefIndex]))
			}
			else
			{
				ze_colored_print(id, "!tYour Damage !g%d!y, !tYou need !g%d !tDamage To be Best Defender!y.", floatround(g_fDamage[id]), floatround(g_fDamage[g_iBestDefIndex] - g_fDamage[id]))
			}
		}
		case 2:
		{
			if (id == g_iBestDefIndex)
			{
				set_hudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_hudmessage(id, "You are now Best Defender [%d] :)", floatround(g_fDamage[g_iBestDefIndex]))
			}
			else
			{
				set_hudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_hudmessage(id, "Your Damage %d, You need %d Damage To be Best Defender.", floatround(g_fDamage[id]), floatround(g_fDamage[g_iBestDefIndex] - g_fDamage[id]))
			}
		}
		case 3:
		{
			if (id == g_iBestDefIndex)
			{
				set_dhudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_dhudmessage(id, "You are now Best Defender [%d] :)", floatround(g_fDamage[g_iBestDefIndex]))
			}
			else
			{
				set_dhudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_dhudmessage(id, "Your Damage %d, You need %d Damage To be Best Defender.", floatround(g_fDamage[id]), floatround(g_fDamage[g_iBestDefIndex] - g_fDamage[id]))
			}
		}
	}
}

public Fw_PlayerSpawn_Post(id)
{
	if (get_pcvar_num(cvar_show_chat_notice) != 0)
	{
		new szName[32]
		get_user_name(g_iBestDefIndex, szName, charsmax(szName))
		
		if (g_iBestDefIndex == 0 || g_fDamage[g_iBestDefIndex] == 0.0)
			return
		


		ze_colored_print(id, "!tBest Defender: !g%s. !tDamage: !g%i. !tAwards: !g%d XP, %d QC!y.", szName, floatround(g_fDamage[g_iBestDefIndex]), get_pcvar_num(cvar_give_xp), get_pcvar_num(cvar_give_escape_coins))


	}
	
	if (get_pcvar_num(cvar_give_xp) != 0 || get_pcvar_num(cvar_give_escape_coins) != 0)
	{
		if (g_iBestDefIndex == 0 || g_iBestDefIndex != id || g_fDamage[g_iBestDefIndex] == 0.0)
			return
		
		ze_set_user_coins(g_iBestDefIndex, get_pcvar_num(cvar_give_escape_coins) + ze_get_user_coins(g_iBestDefIndex))
		ze_set_user_xp(g_iBestDefIndex, get_pcvar_num(cvar_give_xp) + ze_get_user_xp(g_iBestDefIndex))
	}
}

public ze_game_started()
{
	set_task(5.0, "RestDamage")
}

public RestDamage()
{
	for (new i = 1; i <= get_member_game(m_nMaxPlayers); i++)
	{
		g_fDamage[i] = 0.0
	}
}

public Get_Best_Defender()
{
	new Float:fTemp = 0.0
	
	for (new i = 1; i <= get_member_game(m_nMaxPlayers); i++)
	{
		if (!is_user_connected(i))
			continue
		
		if (g_fDamage[i] > fTemp)
		{
			fTemp = g_fDamage[i]
			g_iBestDefIndex = i
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
