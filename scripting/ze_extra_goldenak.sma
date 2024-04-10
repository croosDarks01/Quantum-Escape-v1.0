#include <ze_core>
#include <ze_items_manager>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define NAME "Golden Ak 47"
#define COST 30
#define LIMIT 0
#define is_valid_player(%1) (1 <= %1 <= get_maxplayers())
new const g_GAKEnt[] = "weapon_ak47"

new AK_V_MODEL[64] = "models/zombie_escape/v_golden_ak47.mdl"
new AK_P_MODEL[64] = "models/zombie_escape/p_golden_ak47.mdl"
new AK_W_MODEL[64] = "models/zombie_escape/w_golden_ak47.mdl"

/* Pcvars */
new cvar_dmgmultiplier, cvar_goldbullets,  cvar_custommodel, cvar_uclip
new g_itemid, bool:g_HasAk[33], g_hasZoom[33], bullets[33]
// Sprite
new m_spriteTexture
const Wep_ak47 = ((1<<CSW_AK47))

public plugin_init()
{
	// Register The Plugin
	register_plugin("[ZP] Extra: Golden Ak 47", "1.1", "AlejandroSk / JaCk")
	register_cvar("JaCk", "[ZE] Golden AK47", FCVAR_SERVER|FCVAR_SPONLY)
	// Register our extra item
	g_itemid = ze_register_item(NAME, COST, LIMIT)
	// Event
	register_event("DeathMsg", "Death", "a")
	register_event("WeapPickup","checkModel","b","1=19")
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	RegisterHam(Ham_Item_AddToPlayer, g_GAKEnt, "fw_GAK47AddToPlayer")
	// Forwards
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward( FM_CmdStart, "fw_CmdStart" )
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_goldenak_dmg_multiplier", "5")
	cvar_custommodel = register_cvar("zp_goldenak_custom_model", "1")
	cvar_goldbullets = register_cvar("zp_goldenak_gold_bullets", "1")
	cvar_uclip = register_cvar("zp_goldenak_unlimited_clip", "1")
}

public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnected(id)
{
	g_HasAk[id] = false
}

public Death()
{
	g_HasAk[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_HasAk[id] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_P_MODEL)
	precache_model(AK_W_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public ze_user_infected(id)
{
	g_HasAk[id] = false
}

public checkModel(id)
{
	if ( ze_is_user_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, AK_V_MODEL)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AK47 && g_HasAk[id])
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
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_HasAk[attacker] )
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
		
		if( szWeapID == CSW_AK47 && g_HasAk[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && g_hasZoom[id])
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
		
		if ((bullets[id] > clip) && (wpnid == CSW_AK47) && g_HasAk[id]) 
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
			write_byte( 255 )     // R
			write_byte( 215 )       // G
			write_byte( 0 )       // B
			write_byte(200) // Alpha
			write_byte(150) // speed
			message_end()
		}
	
		bullets[id] = clip
	}
	
}

public ze_select_item_pre(id, itemid)
{
	if(itemid != g_itemid) // Not our gun?
		return ZE_ITEM_AVAILABLE;
		
	if(ze_is_user_zombie(id)) // Zombie?
		return ZE_ITEM_DONT_SHOW;
		
	return ZE_ITEM_AVAILABLE;
}

public ze_select_item_post(id, itemid)
{
	if(itemid != g_itemid) // Not our gun?
		return;
		
	if(user_has_weapon(id, CSW_AK47))
	{
		drop_prim(id)
	}
	give_item(id, "weapon_ak47")
	g_HasAk[id] = true
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity)) // Entity is not valid
		return FMRES_IGNORED;
		
	if(!equal(model, "models/w_ak47.mdl")) // Entity model is not w_ak47
		return FMRES_IGNORED;
		
	static szClassName[33] // Get classname
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox")) // Not a Weapon box
		return FMRES_IGNORED
	
	static iOwner, iStoredGalilID // Some vars
	
	iOwner = entity_get_edict(entity, EV_ENT_owner) // Get owner
	
	iStoredGalilID = find_ent_by_owner(-1, "weapon_ak47", entity) // Get drop weapon index (galil) to use in fw_Galil_AddToPlayer forward
	
	if(g_HasAk[iOwner] && is_valid_ent(iStoredGalilID)) // Entity classname is weaponbox, and galil has founded
	{
		entity_set_int(iStoredGalilID, EV_INT_impulse, 666) // Setting weapon options
		g_HasAk[iOwner] = false // Reset user vars
		entity_set_model(entity, AK_W_MODEL) // Set weaponbox new model
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fw_GAK47AddToPlayer(GAK47, id)
{
	if( is_valid_ent(GAK47) && is_user_connected(id) && entity_get_int(GAK47, EV_INT_impulse) == 666) // Make sure that this is our gun
	{
		g_HasAk[id] = true
		entity_set_int(GAK47, EV_INT_impulse, 0)
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++)
	{
		if (Wep_ak47 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
