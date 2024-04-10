#include <amxmodx>
#include <fakemeta>
#include <ze_core>
#include <ze_class_zombie>
new const leap_sound[4][] = { "left_4_dead2/hunter_jump.wav", "left_4_dead2/hunter_jump1.wav", "left_4_dead2/hunter_jump2.wav", "left_4_dead2/hunter_jump3.wav" }
// Variables
new g_hunter

// Arrays
new Float:g_lastleaptime[33]

// Cvar pointers
new cvar_force, cvar_cooldown

// Plugin info.
#define PLUG_VERSION "0.2"
#define PLUG_AUTHOR "DJHD!"
public plugin_precache()
{
	new const szZombieName[] = "Hunter"
	new const szZombieDesc[] = "-= Balanced =-"
	new const szZombieModel[] = "ze_regular_zombi"
	new const szZombieMelee[] = "models/zm_es/zombi_melee/v_knife_reg_zombi.mdl"
	const Float:flZombieHealth = 10000.0
	const Float:flZombieSpeed = 320.0
	const Float:flZombieGravity = 640.0
	const Float:flZombieKnockback = 200.0

	// Registers new Class.
	g_hunter = ze_zclass_register(szZombieName, szZombieDesc, szZombieModel, szZombieMelee, flZombieHealth, flZombieSpeed, flZombieGravity, flZombieKnockback)
	// Sound
	static i
	for(i = 0; i < sizeof leap_sound; i++)
		precache_sound(leap_sound[i])
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Normal", ZE_VERSION, ZE_AUTHORS)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink") 
	
	// Cvars
	cvar_force = register_cvar("ze_hunter_jump_force", "400") 
	cvar_cooldown = register_cvar("ze_hunter_jump_cooldown", "30.0")
	
	static szCvar[30]
	formatex(szCvar, charsmax(szCvar), "v%s by %s", PLUG_VERSION, PLUG_AUTHOR)
	register_cvar("zp_zclass_hunterl4d2", szCvar, FCVAR_SERVER|FCVAR_SPONLY)
}
public ze_user_infected(id, infector)
{
	// It's the selected zombie class
	if(ze_zclass_get_current(id) == g_hunter)
	{

		// Message
		client_print(id, print_chat, "[ZE] To use the super jump ability press - ^"CTRL + E^"")
	}
}
public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id))
		return
	
	if(is_user_connected(id))
	{
		if (allowed_hunterjump(id))
		{
			static Float:velocity[3]
			velocity_by_aim(id, get_pcvar_num(cvar_force), velocity)
			set_pev(id, pev_velocity, velocity)
			
			emit_sound(id, CHAN_STREAM, leap_sound[random_num(0, sizeof leap_sound -1)], 1.0, ATTN_NORM, 0, PITCH_HIGH)
			
			// Set the current super jump time
			g_lastleaptime[id] = get_gametime()
		}
	}
}
allowed_hunterjump(id)
{    
	if (!ze_is_user_zombie(id))
		return false
	
	if (ze_zclass_get_current(id) != g_hunter)
		return false
	
	if (!((pev(id, pev_flags) & FL_ONGROUND) && (pev(id, pev_flags) & FL_DUCKING)))
		return false
	
	static buttons
	buttons = pev(id, pev_button)
	
	// Not doing a longjump (added bot support)
	if (!(buttons & IN_USE) && !is_user_bot(id))
		return false
	
	static Float:cooldown
	cooldown = get_pcvar_float(cvar_cooldown)
	
	if (get_gametime() - g_lastleaptime[id] < cooldown)
		return false
	
	return true
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
