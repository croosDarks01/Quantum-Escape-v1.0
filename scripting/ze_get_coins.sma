#include <ze_coins> // Include ze_core.inc file
#include <nvault>
#include <ze_levels>
#define NV_NAME "GET_COINS"
#define TAG "[ZE]" 

enum player_struct {
    mtime,bool:ftime,key[64]
}
new g_player[33][player_struct];

new cvar_save_type, cvar_time, cvar_coins, cvar_xp;

public plugin_init() {
    register_plugin("Get Escape Coins", "1.0", "ZE DEV TEAM");
    
    cvar_save_type = register_cvar("get_coins_save_type", "1"); // how to save data 1 by authid, 2 by ip or 3 by name
    cvar_time = register_cvar("get_coins_minutes", "720"); // time in minutes, 720 minutes=12 hours it will be auto calculated
    cvar_coins = register_cvar("get_escape_coins", "200"); // how many coins to give
    cvar_xp = register_cvar("get_xp_amount", "50"); // amount of XP to give
    
    register_clcmd("say /get", "cmd_coins");
    register_clcmd("say_team /get", "cmd_coins");

}
public cmd_coins(id) {
    new nv = nvault_open(NV_NAME);
    
    if(nv == INVALID_HANDLE) {
        client_print(id, print_chat, "%s For the moment, the Escape Coins system is inactive.", TAG);
        return;
    }
    
    new txt_min[32], txt_coins[10];
    new coins = get_pcvar_num(cvar_coins), pminutes = get_pcvar_num(cvar_time);
    copy(txt_coins, charsmax(txt_coins), (coins==1) ? "coin" : "coins");
    build_time(pminutes, txt_min, charsmax(txt_min));
    
    // Retrieve XP amount from cvar
    new xp_amount = get_pcvar_num(cvar_xp);
    
    // Check if player has received XP recently
    if(g_player[id][ftime]) {
        client_print(id, print_chat, "%s You have just received %d Escape %s and %d XP, get another in %s!", TAG, coins, txt_coins, xp_amount, txt_min);
        ze_set_user_coins(id, ze_get_user_coins(id) + coins);
        ze_set_user_xp(id, ze_get_user_xp(id) + xp_amount);
        g_player[id][ftime] = false;
        nvault_touch(nv, g_player[id][key], g_player[id][mtime] = get_systime());
        return;
    }
    
    // Calculate time difference since last XP received
    new user_time = get_systime() - g_player[id][mtime];
    new diff_min = (user_time < (pminutes * 60)) ? pminutes - (user_time / 60) : pminutes;
    build_time(diff_min, txt_min, charsmax(txt_min));
    
    // Check if enough time has passed to receive XP
    if(user_time >= (pminutes * 60)) {
        client_print(id, print_chat, "%s You have just received %d Escape %s and %d XP since %s passed!", TAG, coins, txt_coins, xp_amount, txt_min);
        ze_set_user_coins(id, ze_get_user_coins(id) + coins);
        ze_set_user_xp(id, ze_get_user_xp(id) + xp_amount);
        nvault_touch(nv, g_player[id][key], g_player[id][mtime] = get_systime());
    } else {
        client_print(id, print_chat, "%s Retry again in %s for getting %d more Escape %s and %d XP!", TAG, txt_min, coins, txt_coins, xp_amount);
    }
    
    nvault_close(nv);
}

public client_disconnected(id) {
    
    g_player[id][mtime]=0;
    g_player[id][ftime]=false;
}

stock get_auth(id,data[],len)
    switch(get_pcvar_num(cvar_save_type)) {
        case 1: get_user_authid(id,data,len);
        case 2: get_user_ip(id,data,len,1);
        case 3: get_user_name(id,data,len);
    }

stock build_time(pminutes,data[],len)
    if(pminutes==1)
        copy(data,len,"1 minute");
    else if(pminutes!=1&&pminutes<60)
        formatex(data,len,"%d minutes",pminutes);
    else if(pminutes==60)
        copy(data,len,"1 hour");
    else {
        new ptime=pminutes/60;
        if(ptime*60==pminutes)
            formatex(data,len,"%d %s",ptime,(ptime==1)?"hour":"hours");
        else {
            new diff=pminutes-ptime*60;
            formatex(data,len,"%d %s and %d %s",ptime,(ptime==1)?"hour":"hours",diff,(diff==1)?"minute":"minutes");
        }
    }  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
