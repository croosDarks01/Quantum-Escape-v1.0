#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <ze_core>
#include <ze_class_zombie>

#define TASK_BAT_FLY 11111
#define TASK_HOOK_HUMAN 22222
#define TASK_THROW_BAT 33333
#define TASK_COOLDOWN 70
new const g_bat_model[] = "models/zombie_escape/bat_witch.mdl"
new const ent_class[] = "bat_witch"
new g_zclass_banshee
new ent
new exp_id
new bat_mode[33]
new g_target[33]
new bool:g_gotcha[33]
new bool:can_do_skill[33]

new cvar_cooldown, cvar_time_removebat, cvar_hook_speed

public plugin_precache()
{
	new const szZombieName[] = "Banshee"
	new const szZombieDesc[] = "-= Balanced =-"
	new const szZombieModel[] = "witch_zombi_origin"
	new const szZombieMelee[] = "models/zm_es/zombie_escape/v_knife_witch_zombi.mdl"
	const Float:flZombieHealth = 10000.0
	const Float:flZombieSpeed = 320.0
	const Float:flZombieGravity = 640.0
	const Float:flZombieKnockback = 200.0
	new const g_bat_model[] = "models/zombie_escape/bat_witch.mdl"
	new const ent_class[] = "bat_witch"
	
	exp_id = precache_model("sprites/zerogxplode.spr")
	precache_model(g_bat_model)

	// Registers new Class.
	 g_zclass_banshee = ze_zclass_register(szZombieName, szZombieDesc, szZombieModel, szZombieMelee, flZombieHealth, flZombieSpeed, flZombieGravity, flZombieKnockback)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Normal", ZE_VERSION, ZE_AUTHORS)
	register_touch(ent_class, "*", "fw_touch")
	RegisterHam(Ham_Killed, "player", "fw_killed", 1)
	RegisterHam(Ham_Touch, "player", "fw_touch2")
	
	// Events
	register_event("HLTV", "event_newround", "1=0", "2=0")
	
	// Skill Command
	register_clcmd("drop", "do_skill")
	
	// Register Cvars
	cvar_cooldown = register_cvar("zp_banshee_cooldown", "70.0")
	cvar_time_removebat = register_cvar("zp_banshee_time_removebat", "5.0")
	cvar_hook_speed = register_cvar("zp_banshee_hook_speed", "290.0")
}

public ze_user_infected(id)
{
	if(is_user_alive(id) && ze_is_user_zombie(id) && ze_zclass_get_current(id) == g_zclass_banshee)
	{
		color_saytext(id, "^x04[ZE] ^x01You are Banshee Zombie. Press (G) to^x03 Drop Bat")
		can_do_skill[id] = true
	}
	
	if(g_gotcha[id])
	{
		if(task_exists(TASK_BAT_FLY)) remove_task(TASK_BAT_FLY)
		if(task_exists(TASK_HOOK_HUMAN)) remove_task(TASK_HOOK_HUMAN)
		
		if(is_valid_ent(ent))
			engfunc(EngFunc_RemoveEntity, ent)	
	}
}

public fw_killed(victim)
{
	if(ze_is_user_zombie(victim) && ze_zclass_get_current(victim) == g_zclass_banshee)
		set_pev(victim, pev_sequence, random_num(128, 137))
}

public event_newround(id)
{
	can_do_skill[id] = false
	
	if(task_exists(TASK_BAT_FLY)) remove_task(TASK_BAT_FLY)
	if(task_exists(TASK_HOOK_HUMAN)) remove_task(TASK_HOOK_HUMAN)
	if(task_exists(id+TASK_THROW_BAT)) remove_task(id+TASK_THROW_BAT)
	if(task_exists(id+TASK_COOLDOWN)) remove_task(id+TASK_COOLDOWN)
		
	if(is_valid_ent(ent))
		engfunc(EngFunc_RemoveEntity, ent)	
		
	g_gotcha[id] = false
}

public do_skill(id)
{
	if(is_user_alive(id) && ze_is_user_zombie(id) && ze_zclass_get_current(id) == g_zclass_banshee)
	{
		if(can_do_skill[id])
		{
			new body, target
			get_user_aiming(id, target, body, 99999)
			
			if(target && is_valid_ent(target))
			{
				bat_mode[id] = 1
				g_target[id] = target
				g_gotcha[target] = false
			
				create_bat(id)
					
				static bat_array[2]
				bat_array[0] = ent
				bat_array[1] = g_target[id]
				
				set_task(0.1, "set_bat_fly", TASK_BAT_FLY, bat_array, sizeof(bat_array), "b")
				set_task(get_pcvar_float(cvar_time_removebat), "remove_bat", target+TASK_THROW_BAT)
			} else {
				bat_mode[id] = 2
				
				create_bat(id)
				
				new Float:Velocity1[3]
				VelocityByAim(id, 700, Velocity1)
				
				entity_set_vector(ent, EV_VEC_velocity, Velocity1)
			}
			set_task(get_pcvar_float(cvar_cooldown), "remove_cooldown", id+TASK_COOLDOWN)
		} else {
			color_saytext(id, "^x04[ZE] ^x01You can't^x03 Drop Bat^x01 at this time...")
		}
	}
}

public set_bat_fly(bat_array[], taskid)
{
	static target
	target = bat_array[1]
	
	new owner
	
	if(is_valid_ent(ent))
		owner = pev(ent, pev_owner)
	
	if(is_user_alive(owner))
	{
		set_hook(target, ent)
	} else {
		if(task_exists(TASK_BAT_FLY)) remove_task(TASK_BAT_FLY)
		if(task_exists(TASK_HOOK_HUMAN)) remove_task(TASK_HOOK_HUMAN)
		
		if(is_valid_ent(ent))
			engfunc(EngFunc_RemoveEntity, ent)
	}
}

public set_grab_player(graber, grabed)
{
	new array2[2]
	array2[0] = graber
	array2[1] = grabed
	
	set_task(0.1, "set_grab_player2", TASK_HOOK_HUMAN, array2, sizeof(array2), "b")
}

public set_grab_player2(array2[], taskid)
{
	static id
	id = array2[0]
	static target
	target = array2[1]
	
	set_hook(id, target)
	
	if(is_valid_ent(ent))
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
}

public set_hook(hooker, hooked)
{
	static Float:originF[3]
	pev(hooker, pev_origin, originF);
	
	new Float:fl_Velocity[3];
	new Float:vicOrigin[3]

	pev(hooked, pev_origin, vicOrigin);
	
	new Float:distance = get_distance_f(originF, vicOrigin);

	if (distance > 1.0)
	{
		new Float:fl_Time = distance / get_pcvar_float(cvar_hook_speed)

		fl_Velocity[0] = (originF[0] - vicOrigin[0]) / fl_Time
		fl_Velocity[1] = (originF[1] - vicOrigin[1]) / fl_Time
		fl_Velocity[2] = (originF[2] - vicOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(hooked, EV_VEC_velocity, fl_Velocity);
}

public create_bat(owner)
{
	ent = create_entity("info_target")
	
	new Float:Origin[3], Float:Angle[3]
	
	entity_get_vector(owner, EV_VEC_v_angle, Angle)
	entity_get_vector(owner, EV_VEC_origin, Origin)
	entity_set_origin(ent, Origin)
	
	entity_set_string(ent,EV_SZ_classname, ent_class);
	entity_set_model(ent, g_bat_model)
	entity_set_int(ent,EV_INT_solid, 2)
	entity_set_int(ent, EV_INT_movetype, 5)
	
	entity_set_vector(ent, EV_VEC_angles, Angle)
	
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {10.0,10.0,15.0}
	new Float:mins[3] = {-10.0,-10.0,-15.0}
	entity_set_size(ent,mins,maxs)
	
	entity_set_edict(ent, EV_ENT_owner, owner)
	
	entity_set_float(ent,EV_FL_animtime,2.0)
	entity_set_float(ent,EV_FL_framerate,1.0)
	entity_set_int(ent,EV_INT_sequence, 0)	
}

public fw_touch(ent, touched)
{
	new owner = pev(ent, pev_owner)
	new id = g_target[owner]
		
	if(bat_mode[owner] == 1 && !g_gotcha[id] && !ze_is_user_zombie(id))
	{
		g_gotcha[id] = true
		
		set_grab_player(owner, id)
	} else if(bat_mode[owner] == 2 && !g_gotcha[touched]) {
		if(is_user_alive(touched) && !ze_is_user_zombie(touched))
		{
			set_grab_player(owner, touched)
			g_gotcha[touched] = true
			
			static bat_array[2]
			bat_array[0] = ent
			bat_array[1] = touched
		
			set_task(0.1, "set_bat_fly", TASK_BAT_FLY, bat_array, sizeof(bat_array), "b")
		} else {
			new Float:Origin[3]
			pev(ent, pev_origin, Origin)
			
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(3)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(exp_id)	// sprite index
			write_byte(25)	// scale in 0.1's
			write_byte(30)	// framerate
			write_byte(0)	// flags
			message_end()
			
			if(is_valid_ent(ent))
				engfunc(EngFunc_RemoveEntity, ent)
		}
	}
}

public fw_touch2(ptr, ptd)
{
	if(!is_valid_ent(ptr) || !is_valid_ent(ptd))
		return FMRES_IGNORED
		
	if(!is_user_alive(ptr) || !is_user_alive(ptd))
		return FMRES_IGNORED
		
	if(!is_user_connected(ptr) || !is_user_connected(ptd))
		return FMRES_IGNORED
		
	if(!ze_is_user_zombie(ptr) || ze_is_user_zombie(ptd))
		return FMRES_IGNORED
		
	if(is_user_alive(ptr) && g_gotcha[ptd] && bat_mode[ptr] == 1)
	{
		remove_task(TASK_BAT_FLY)
		remove_task(TASK_HOOK_HUMAN)
		remove_task(TASK_THROW_BAT)
		
		if(is_valid_ent(ent))
			engfunc(EngFunc_RemoveEntity, ent)
			
		g_gotcha[ptd] = false
	} else if(is_user_alive(ptr) && g_gotcha[ptd] && bat_mode[ptr] == 2) {
		remove_task(TASK_BAT_FLY)
		remove_task(TASK_HOOK_HUMAN)
		remove_task(TASK_THROW_BAT)
		
		if(is_valid_ent(ent))
			engfunc(EngFunc_RemoveEntity, ent)
		
		g_gotcha[ptd] = false
	}
	
	return FMRES_HANDLED
}

public fw_think(ent)
{
	new owner = pev(ent, pev_owner)
	new id = g_target[owner]
	
	if(bat_mode[id] == 1 && g_gotcha[id])
	{
		static Float:Origin[3]
		entity_get_vector(id, EV_VEC_origin, Origin)
		entity_set_vector(ent, EV_VEC_origin, Origin)
	}
	
	entity_set_float(ent,EV_FL_nextthink, halflife_time() + 0.1)
}

public remove_bat(taskid)
{
	new id = taskid - TASK_THROW_BAT
	
	if(task_exists(TASK_BAT_FLY)) remove_task(TASK_BAT_FLY)
	if(task_exists(TASK_HOOK_HUMAN)) remove_task(TASK_HOOK_HUMAN)
	if(task_exists(id+TASK_THROW_BAT)) remove_task(id+TASK_THROW_BAT)
		
	if(is_valid_ent(ent))
		engfunc(EngFunc_RemoveEntity, ent)
			
	g_gotcha[id] = false
}

public remove_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	
	if(is_user_alive(id) && ze_is_user_zombie(id) && ze_zclass_get_current(id) == g_zclass_banshee)
	{
		color_saytext(id, "^x04[ZE] ^x01Now you can^x03 Drop Bat^x01. Press (G)")
		can_do_skill[id] = true

	}
}

color_saytext(player, const message[], any:...)
{
	new text[301]
	format(text, 300, "%s", message)

	new dest
	if (player) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, get_user_msgid("SayText"), {0,0,0}, player)
	write_byte(1)
	write_string(check_text(text))
	return message_end()
}

check_text(text1[])
{
	new text[301]
	format(text, 300, "%s", text1)
	replace(text, 300, "/g", "^x04")
	replace(text, 300, "/r", "^x03")
	replace(text, 300, "/y", "^x01")
	return text
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
