#include <ze_core>

new g_IsLastRound = 0
new g_OldTimelimit=0

#define TASK_ID_CHECKFORMAPEND 241
#define TASK_ID_DELAYMAPCHANGE 242

public plugin_init()
{
	register_plugin("Allow round finish", "1.0.2" ,"EKS")

	set_task(15.0,"Task_MapEnd",TASK_ID_CHECKFORMAPEND,_,_,"d",1)
}

public Task_MapEnd()
{
	if(get_playersnum())
	{
		g_IsLastRound = 1
		g_OldTimelimit = get_cvar_num("mp_timelimit")

		server_cmd("mp_timelimit 0")
		client_print_color(0, print_team_default, "^4[QZE] ^1Timelimit has ^4expired^1, ^3Mapchange will happen after this round^1!")
	}
}

public ze_roundend(WinTeam)
{
	if(g_IsLastRound == 1)
	{
		client_print(0, print_chat,"^4[QZE] ^1Round is over, changing map ^4in 5 seconds")
		client_print_color(0, print_team_default, "^4[QZE] ^1Round is over^1, changing map ^4in 5 seconds^1!")
		set_task(5.0, "Task_DelayMapEnd", TASK_ID_DELAYMAPCHANGE, _, _, "a", 1) // We delay the end of the map with a few sec, so the last guys death is viewable
	}
}

public server_changelevel(map[])
{
	if(g_IsLastRound == 1)
		Task_DelayMapEnd()
}

public Task_DelayMapEnd()
{
	remove_task(TASK_ID_DELAYMAPCHANGE)
	g_IsLastRound = 0
	if(get_cvar_num("mp_timelimit") == 0)
		server_cmd("mp_timelimit %d", g_OldTimelimit)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
