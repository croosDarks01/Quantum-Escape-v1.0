#include <amxmodx>
#include <ze_core>
#include <reapi>

const Float:AUTORESPAWN_DELAY = 5.0
const TASK_AUTORESPAWN = 100
#define ID_AUTORESPAWN (taskid - TASK_AUTORESPAWN)

new g_player_died[33];

public plugin_init()
{
    register_plugin("[ZE] Addon: Auto Respawn Player", "0.1", "croosDarks");
}

public client_disconnected(id)
{
    remove_task(id + TASK_AUTORESPAWN);
}

public client_putinserver(id)
{
    set_task(0.1, "auto_respawn_player", id + TASK_AUTORESPAWN);
    g_player_died[id] = false;
}

public player_death(id)
{
    g_player_died[id] = true;
}

public auto_respawn_player(taskid)
{
    if (!is_user_alive(ID_AUTORESPAWN) && get_user_team(ID_AUTORESPAWN) != TEAM_SPECTATOR && ze_get_zm_number() != 0 && ze_get_azm_number() != 0)
    {
        rg_round_respawn(ID_AUTORESPAWN);
        ze_set_user_zombie(ID_AUTORESPAWN, 0);
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
