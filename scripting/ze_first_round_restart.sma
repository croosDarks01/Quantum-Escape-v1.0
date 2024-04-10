#include <ze_core>

#define TIMER_TASK 2018

// Pointers
new g_pCvarRestartTime

// Variables
new bool:g_bFirstRound = false, g_iCounter

public plugin_init()
{
	register_plugin("First Round Restart", "1.0", "Raheem")
	
	// Cvars
	g_pCvarRestartTime = register_cvar("restart_time", "30") // Restart time in seconds
	
	// Initial Values (-1 Hard Coded Value)
	g_iCounter = get_pcvar_num(g_pCvarRestartTime) - 1
}

public ze_game_started()
{
	if (!g_bFirstRound)
	{
		g_bFirstRound = true
		server_cmd("sv_restartround %d", get_pcvar_num(g_pCvarRestartTime))
		set_task(1.0, "TimeCounter", TIMER_TASK, _, _, "a", get_pcvar_num(g_pCvarRestartTime))
	}
}

public TimeCounter()
{
	new iNum = g_iCounter --
	new szNum[32]
	
	if (iNum <= 0)
		return
	
	client_print(0, print_center, "Round Will Restart IN: %d!!", iNum)
	
	if (iNum < 11)
	{
		num_to_word(iNum, szNum, charsmax(szNum))
		client_cmd(0,"speak ^"vox/%s^"", szNum)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1036{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
