#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <ze_core>
#include <ze_class_zombie>
new g_L4dTank
new g_trailSprite, rockmodel
new g_trail[] = "sprites/xbeam3.spr"
new rock_model[] = "models/rockgibs.mdl"
new rock_model2[] = "models/rockgibs.mdl"
new tank_rocklaunch[] = "zombie_plague/tank_rocklaunch.wav"
new g_power[33]

new cvar_rock_damage, cvar_rock_reward, cvar_rockmode, cvar_rockEnergyNesesary, cvar_rock_speed, cvar_reloadpower
public plugin_precache()
{
	new const szZombieName[] = "Butcher"
	new const szZombieDesc[] = "-= Balanced =-"
	new const szZombieModel[] = "ze_regular_zombi"
	new const szZombieMelee[] = "models/zm_es/zombi_melee/v_knife_reg_zombi.mdl"
	const Float:flZombieHealth = 10000.0
	const Float:flZombieSpeed = 320.0
	const Float:flZombieGravity = 640.0
	const Float:flZombieKnockback = 200.0
	g_L4dTank = ze_zclass_register(szZombieName, szZombieDesc, szZombieModel, szZombieMelee, flZombieHealth, flZombieSpeed, flZombieGravity, flZombieKnockback)
	g_trailSprite = precache_model(g_trail)
	rockmodel = precache_model(rock_model)
	precache_sound(tank_rocklaunch)


}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Normal", ZE_VERSION, ZE_AUTHORS)
	cvar_rock_speed = register_cvar("ze_tank_rockspeed", "700")
	cvar_rock_damage = register_cvar("ze_tank_rockdamage", "70")
	cvar_rock_reward = register_cvar("ze_tank_rockreward", "1")
	cvar_rockmode = register_cvar("ze_tank_rockmode", "1")
	cvar_rockEnergyNesesary = register_cvar("ze_tank_rock_energynesesary", "20")
	cvar_reloadpower = register_cvar("ze_tank_reload_power", "1")
	register_touch("rock_ent","*","RockTouch")
	register_forward(FM_CmdStart, "CmdStart" )
}
public ze_user_infected( id, infector )
{
             if (ze_zclass_get_current(id) == g_L4dTank)
             {
		print_chatColor(id, "\g[ZE]\n You Are A \gL4D Tank\n, You Cant Launch Rock With \tIN_USE [+E]") 
		g_power[id] = get_pcvar_num(cvar_rockEnergyNesesary)
		set_task(get_pcvar_float(cvar_reloadpower), "power1", id, _, _, "b")
             }
}  
public CmdStart( const id, const uc_handle, random_seed )
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	if(!ze_is_user_zombie(id))
		return FMRES_IGNORED;
		
	new button = pev(id, pev_button)
	new oldbutton = pev(id, pev_oldbuttons)
	
	if (ze_is_user_zombie(id) && (ze_zclass_get_current(id) == g_L4dTank))
		if(oldbutton & IN_USE && !(button & IN_USE))
		{
			if(g_power[id] >= get_pcvar_num(cvar_rockEnergyNesesary))
			{
				MakeRock(id)
				emit_sound(id, CHAN_STREAM, tank_rocklaunch, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				g_power[id] = 0
			}
			else
			{
				set_hudmessage(255, 0, 0, 0.0, 0.6, 0, 6.0, 3.0)
				show_hudmessage(id, "[ZE] Energy Nesesary To Launch Rock [%d] || You Energy [%d]", get_pcvar_num(cvar_rockEnergyNesesary), g_power[id])
			}
			
		}
			
	return FMRES_IGNORED
}

public power1(id)
{
	g_power[id] += 1
	
	if( g_power[id] > get_pcvar_num(cvar_rockEnergyNesesary) )
	{
		g_power[id] = get_pcvar_num(cvar_rockEnergyNesesary)
	}
}

public RockTouch( RockEnt, Touched )
{
	if ( !pev_valid ( RockEnt ) )
		return
		
	static Class[ 32 ]
	entity_get_string( Touched, EV_SZ_classname, Class, charsmax( Class ) )
	new Float:origin[3]
		
	pev(Touched,pev_origin,origin)
	
	if( equal( Class, "player" ) )
		if (is_user_alive(Touched))
		{
			if(!ze_is_user_zombie(Touched))
			{
				new TankKiller = entity_get_edict( RockEnt, EV_ENT_owner )
				
				switch(get_pcvar_num(cvar_rockmode))
				{
					case 1: // Health
					{
						new iHealth = get_user_health(Touched)

						if( iHealth >= 1 && iHealth <= get_pcvar_num(cvar_rock_damage))
						{
							ExecuteHamB( Ham_Killed, Touched, TankKiller, 0 )
							print_chatColor(TankKiller, "\g[ZE]\n You Receive \t%d\n Ammo Packs To Reach a Rock a Enemy", get_pcvar_num(cvar_rock_reward))
						}
						else
						{
							set_user_health(Touched, get_user_health(Touched) - get_pcvar_num(cvar_rock_damage))
							print_chatColor(TankKiller, "\g[ZE]\n You Receive \t%d\n Ammo Packs To Reach a Rock a Enemy", get_pcvar_num(cvar_rock_reward))
						}
					}
					case 2: //BadAim
					{
						new Float:vec[3] = {100.0,100.0,100.0}
						
						entity_set_vector(Touched,EV_VEC_punchangle,vec)  
						entity_set_vector(Touched,EV_VEC_punchangle,vec)
						entity_set_vector(Touched,EV_VEC_punchangle,vec) 
						
						print_chatColor(TankKiller, "\g[ZE]\n You Receive \t%d\n Ammo Packs To Reach a Rock a Enemy", get_pcvar_num(cvar_rock_reward))
						set_task(1.50, "EndVictimAim", Touched)
					}
				}
			}
		}
		
	if(equal(Class, "func_breakable") && entity_get_int(Touched, EV_INT_solid) != SOLID_NOT)
		force_use(RockEnt, Touched)
		
	remove_entity(RockEnt)
	
	if(!is_user_alive(Touched))
		return
		
	static origin1[3]
	get_user_origin(Touched, origin1)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, origin1);
	write_byte(TE_BREAKMODEL); 
	write_coord(origin1[0]);  
	write_coord(origin1[1]);
	write_coord(origin1[2] + 24); 
	write_coord(16); 
	write_coord(16); 
	write_coord(16); 
	write_coord(random_num(-50,50)); 
	write_coord(random_num(-50,50)); 
	write_coord(25);
	write_byte(10); 
	write_short(rockmodel); 
	write_byte(10); 
	write_byte(25);
	write_byte(0x01); 
	message_end();
}

public EndVictimAim(Touched)
{
	new Float:vec[3] = {-100.0,-100.0,-100.0}
	entity_set_vector(Touched,EV_VEC_punchangle,vec)  
	entity_set_vector(Touched,EV_VEC_punchangle,vec)
	entity_set_vector(Touched,EV_VEC_punchangle,vec)
}

public MakeRock(id)
{
			
	new Float:Origin[3]
	new Float:Velocity[3]
	new Float:vAngle[3]

	new RockSpeed = get_pcvar_num(cvar_rock_speed)

	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)

	new NewEnt = create_entity("info_target")

	entity_set_string(NewEnt, EV_SZ_classname, "rock_ent")

	entity_set_model(NewEnt, rock_model2)

	entity_set_size(NewEnt, Float:{-1.5, -1.5, -1.5}, Float:{1.5, 1.5, 1.5})

	entity_set_origin(NewEnt, Origin)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	entity_set_int(NewEnt, EV_INT_solid, 2)

	entity_set_int(NewEnt, EV_INT_rendermode, 5)
	entity_set_float(NewEnt, EV_FL_renderamt, 200.0)
	entity_set_float(NewEnt, EV_FL_scale, 1.00)

	entity_set_int(NewEnt, EV_INT_movetype, 5)
	entity_set_edict(NewEnt, EV_ENT_owner, id)

	velocity_by_aim(id, RockSpeed  , Velocity)
	entity_set_vector(NewEnt, EV_VEC_velocity ,Velocity)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) 
	write_short(NewEnt) 
	write_short(g_trailSprite) 
	write_byte(10) 
	write_byte(10) 
	write_byte(255) 
	write_byte(0) 
	write_byte(0) 
	write_byte(200) 
	message_end()
	
	return PLUGIN_HANDLED
}

stock print_chatColor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg,190,input,3);
	replace_all(msg,190,"\g","^4");// green
	replace_all(msg,190,"\n","^1");// normal
	replace_all(msg,190,"\t","^3");// team
	
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i=0;i<count;i++)
	if (is_user_connected(players[i]))
	{
		message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
		write_byte(players[i]);
		write_string(msg);
		message_end();
	}
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
