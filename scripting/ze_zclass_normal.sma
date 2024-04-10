#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <ze_core>
#include <ze_class_zombie>


public plugin_precache()
{
	new const szZombieName[] = "Regular"
	new const szZombieDesc[] = "-= Balanced =-"
	new const szZombieModel[] = "ze_regular_zombi"
	new const szZombieMelee[] = "models/zm_es/zombi_melee/v_knife_reg_zombi.mdl"
	const Float:flZombieHealth = 10000.0
	const Float:flZombieSpeed = 320.0
	const Float:flZombieGravity = 640.0
	const Float:flZombieKnockback = 200.0


	// Registers new Class.
	ze_zclass_register(szZombieName, szZombieDesc, szZombieModel, szZombieMelee, flZombieHealth, flZombieSpeed, flZombieGravity, flZombieKnockback)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Normal", ZE_VERSION, ZE_AUTHORS)

}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
