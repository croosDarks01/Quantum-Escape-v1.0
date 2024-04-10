#include <amxmodx>

#include <ze_core>
#include <ze_class_zombie>
new g_blinder
new gmsgFade
public plugin_precache()
{
	new const szZombieName[] = "Blinder"
	new const szZombieDesc[] = "-= Balanced =-"
	new const szZombieModel[] = "ze_regular_zombi"
	new const szZombieMelee[] = "models/zm_es/zombi_melee/v_knife_reg_zombi.mdl"
	const Float:flZombieHealth = 10000.0
	const Float:flZombieSpeed = 320.0
	const Float:flZombieGravity = 640.0
	const Float:flZombieKnockback = 200.0
	const DEFAULT_ZOMBIE_LEVEL = 0

	// Registers new Class.
	g_blinder = ze_zclass_register(szZombieName, szZombieDesc, szZombieModel, szZombieMelee, flZombieHealth, flZombieSpeed, flZombieGravity, flZombieKnockback, DEFAULT_ZOMBIE_LEVEL)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Normal", ZE_VERSION, ZE_AUTHORS)
	register_event("StatusValue", "EventStatusValue", "b", "1>0", "2>0" );
	gmsgFade = get_user_msgid("ScreenFade")
}
public EventStatusValue( const id ) 
{
	if(!is_user_bot(id) && is_user_connected(id) && !ze_zclass_get_current(id)) 	
	{
		new blinder = read_data(2)
		if (ze_zclass_get_current(blinder) == g_blinder)
		blind(id)
	}
}

public blind(id)
{
	message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
	write_short(1<<2) // fade duration 
	write_short(1<<11) // fade hold time 
	write_short(1<<12) // fade type (in / out) 
	write_byte(10) //  red 
	write_byte(150) //  green 
	write_byte(10) // blue 
	write_byte(250) //  alpha 
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
