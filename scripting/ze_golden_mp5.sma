#include <ze_core>
#include <ze_items_manager>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define is_valid_player(%1) (1 <= %1 <= 32)

new gmp5_V_MODEL[64] = "models/zombie_escape/v_mp5navygold.mdl"
new gmp5_P_MODEL[64] = "models/zombie_escape/p_mp5navygold.mdl"

/* Pcvars */
new cvar_dmgmultiplier, cvar_goldbullets,  cvar_custommodel, cvar_uclip
new g_itemid, bool:g_Hasmp5navy[33], g_hasZoom[ 33 ], bullets[ 33 ]
// Sprite
new m_spriteTexture

const Wep_mp5navy = ((1<<CSW_MP5NAVY))

public plugin_init()
{
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_gmp5_dmg_multiplier", "2")
	cvar_custommodel = register_cvar("zp_gmp5_custom_model", "1")
	cvar_goldbullets = register_cvar("zp_gmp5_gold_bullets", "1")
	cvar_uclip = register_cvar("zp_gmp5_unlimited_clip", "1")
	
	// Register The Plugin
	register_plugin("[ZP] Extra: Golden MP5", "1.1", "Wisam187 : JaCk")
	// Register Zombie Plague extra item
	g_itemid = ze_register_item("Golden MP5", 40, 0)
	// Events
	register_event("DeathMsg", "Death", "a")
	register_event("WeapPickup","checkModel","b","1=19")
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Hams
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward( FM_CmdStart, "fw_CmdStart" )
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	
}

public client_connect(id)
{
	g_Hasmp5navy[id] = false
}

public client_disconnected(id)
{
	g_Hasmp5navy[id] = false
}

public Death()
{
	g_Hasmp5navy[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_Hasmp5navy[id] = false
}

public plugin_precache()
{
	precache_model(gmp5_V_MODEL)
	precache_model(gmp5_P_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public ze_user_infected(id)
{
	g_Hasmp5navy[id] = false
}

public checkModel(id)
{
	if ( ze_is_user_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, gmp5_V_MODEL)
		set_pev(id, pev_weaponmodel2, gmp5_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_MP5NAVY && g_Hasmp5navy[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	if (plrClip == 0 && get_pcvar_num(cvar_uclip))
	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)
		// Get the name of their weapon
		give_item(id, plrWeap)
		engclient_cmd(id, plrWeap) 
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}
	return PLUGIN_HANDLED
}



public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_MP5NAVY && g_Hasmp5navy[attacker] )
    {
        SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
    }
}

public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}


public make_tracer(id)
{
	if (get_pcvar_num(cvar_goldbullets))
	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]
		
		get_user_team(id, pteam, 15)
		
		if ((bullets[id] > clip) && (wpnid == CSW_MP5NAVY) && g_Hasmp5navy[id]) 
		{
			new vec1[3], vec2[3]
			get_user_origin(id, vec1, 1) // origin; your camera point.
			get_user_origin(id, vec2, 3) // termina; where your bullet goes (4 is cs-only)
			
			
			//BEAMENTPOINTS
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short( m_spriteTexture )
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte( random(256) )     // r, g, b
			write_byte( random(256) )       // r, g, b
			write_byte( random(256) )       // r, g, b
			write_byte(200) // brightness
			write_byte(150) // speed
			message_end()
		}
	
		bullets[id] = clip
	}
	
}

public ze_select_item_pre(id, itemid)
{
	if ( itemid != g_itemid )
		return ZE_ITEM_AVAILABLE;
	
	if(ze_is_user_zombie(id))
		return ZE_ITEM_DONT_SHOW;
	
	return ZE_ITEM_AVAILABLE;
}

public ze_select_item_post(id, itemid)
{
	if ( itemid != g_itemid )
		return;

	drop_weapons(id, 1)
	give_item(id, "weapon_mp5navy")
	g_Hasmp5navy[id] = true
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_MAC10)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
