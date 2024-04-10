
#include <ze_core>
#include <ze_levels>

// Variables
new g_iKills[33], g_iBestInfecIndex

// Cvars
new cvar_show_chat_notice, cvar_give_xp, cvar_give_escape_coins, cvar_show_stats

public plugin_init()
{
	register_plugin("[ZE] Best Infector", "1.3", "Raheem")
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	
	// Cvars

	cvar_show_chat_notice = register_cvar("ze_best_infc_chat_notice", "1")
	cvar_give_xp = register_cvar("ze_best_infc_give_xp", "40")
	cvar_give_escape_coins = register_cvar("ze_best_infc_give_ec", "20")
	cvar_show_stats = register_cvar("ze_show_best_infec_stats", "1")
	
	// Commands
	register_clcmd("say /myinfects", "Cmd_BestInfectorStats")
}

public ze_roundend()
{
	Get_Best_Infector()
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0)
		return

	g_iKills[iInfector]++
}

public Cmd_BestInfectorStats(id)
{
	Get_Best_Infector()
	
	switch (get_pcvar_num(cvar_show_stats))
	{
		case 1:
		{
			if (id == g_iBestInfecIndex)
			{
				ze_colored_print(id, "!tYou are now Best Infector !y[!g%d!y] !y:)", g_iKills[g_iBestInfecIndex])
			}
			else
			{
				ze_colored_print(id, "!tYour Infects !g%d!y, !tYou need !g%d !tInfects To be Best Infector!y.", g_iKills[id], g_iKills[g_iBestInfecIndex] - g_iKills[id])
			}
		}
		case 2:
		{
			if (id == g_iBestInfecIndex)
			{
				set_hudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_hudmessage(id, "You are now Best Infector [%d] :)", g_iKills[g_iBestInfecIndex])
			}
			else
			{
				set_hudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_hudmessage(id, "Your Infects %d, You need %d Infects To be Best Infector.", g_iKills[id], g_iKills[g_iBestInfecIndex] - g_iKills[id])
			}
		}
		case 3:
		{
			if (id == g_iBestInfecIndex)
			{
				set_dhudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_dhudmessage(id, "You are now Best Infector [%d] :)", g_iKills[g_iBestInfecIndex])
			}
			else
			{
				set_dhudmessage(random(256), random(256), random(256), -1.0, 0.3, 2, 3.0, 5.0)
				show_dhudmessage(id, "Your Infects %d, You need %d Infects To be Best Infector.", g_iKills[id], g_iKills[g_iBestInfecIndex] - g_iKills[id])
			}
		}
	}
}

public Fw_PlayerSpawn_Post(id)
{
	if (get_pcvar_num(cvar_show_chat_notice) != 0)
	{
		if (g_iBestInfecIndex == 0 || g_iKills[g_iBestInfecIndex] == 0)
			return
		
		new szName[32]
		get_user_name(g_iBestInfecIndex, szName, charsmax(szName))
		

		ze_colored_print(id, "!tBest Infector: !g%s. !tInfects: !g%i. !tAwards: !g%d XP, %d QC!y.", szName, g_iKills[g_iBestInfecIndex], get_pcvar_num(cvar_give_xp), get_pcvar_num(cvar_give_escape_coins))
	}
	

	
	if (get_pcvar_num(cvar_give_xp) != 0 || get_pcvar_num(cvar_give_escape_coins) != 0)
	{
		if (g_iBestInfecIndex == 0 || g_iBestInfecIndex != id || g_iKills[g_iBestInfecIndex] == 0)
			return
		
		ze_set_user_coins(g_iBestInfecIndex, get_pcvar_num(cvar_give_escape_coins) + ze_get_user_coins(g_iBestInfecIndex))
		ze_set_user_xp(g_iBestInfecIndex, get_pcvar_num(cvar_give_xp) + ze_get_user_xp(g_iBestInfecIndex))
	}
}

public ze_game_started()
{
	set_task(5.0, "RestKills")
}

public RestKills()
{
	for (new i = 1; i <= get_member_game(m_nMaxPlayers); i++)
	{
		g_iKills[i] = 0
	}
}

public Get_Best_Infector()
{
	new iTemp = 0
	
	for (new i = 1; i <= get_member_game(m_nMaxPlayers); i++)
	{
		if (!is_user_connected(i))
			continue
		
		if (g_iKills[i] > iTemp)
		{
			iTemp = g_iKills[i]
			g_iBestInfecIndex = i
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
