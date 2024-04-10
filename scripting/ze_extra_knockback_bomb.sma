#include <ze_core>
#include <cstrike>
#include <hamsandwich>
#include <ze_items_manager>
#include <engine>
#include <fun>

#define Plugin    "[ZE] Knockback Bomb"
#define Version   "1.0"
#define Author    "0"

// === Customization starts below! ===
new const g_PlayerModel [ ] = "models/zombie_escape/p_grenade_knock.mdl"
new const g_ViewModel [ ] = "models/zombie_escape/v_grenade_knockback.mdl"
new const g_WorldModel [ ] = "models/zombie_escape/w_grenade_knock.mdl"

// You can add more than 1 sound!
new const g_SoundGrenadeBuy [ ] [ ] = { "items/gunpickup2.wav" }
new const g_SoundAmmoPurchase [ ] [ ] = { "items/9mmclip1.wav" }
new const g_SoundBombExplode [ ] [ ] = { "zombie_escape/grenade_infect.wav" }

new const g_szItemName [ ] = "Knockback Bomb" 
new const g_iItemPrice = 7  

#define MAXCARRY    4 // How many grenades 1 player can hold at the same time
#define RADIUS        300.0 // Affect radius
// === Customization ends above! ===

#define MAXPLAYERS        32
#define pev_nade_type        pev_flTimeStepSound
#define NADE_TYPE_JUMPING    26517
#define AMMOID_SM        13

new g_iExplo

new g_iNadeID

new g_iJumpingNadeCount [ MAXPLAYERS+1 ]
new g_iCurrentWeapon [ MAXPLAYERS+1 ]

new cvar_speed

new g_MaxPlayers
new g_msgAmmoPickup

public plugin_precache ( )
{
    precache_model ( g_PlayerModel )
    precache_model ( g_ViewModel )
    precache_model ( g_WorldModel )
    
    new i
    for ( i = 0; i < sizeof g_SoundGrenadeBuy; i++ )
        precache_sound ( g_SoundGrenadeBuy [ i ] )
    for ( i = 0; i < sizeof g_SoundAmmoPurchase; i++ )
        precache_sound ( g_SoundAmmoPurchase [ i ] )
    for ( i = 0; i < sizeof g_SoundBombExplode; i++ )
        precache_sound ( g_SoundBombExplode [ i ] )
    
    g_iExplo = precache_model ( "sprites/xfire.spr" )
}

public plugin_init ( )
{
    register_plugin ( Plugin, Version, Author )
    
    g_iNadeID = ze_register_item(g_szItemName, g_iItemPrice, 0)  

    register_event ( "CurWeapon", "EV_CurWeapon", "be", "1=1" )
    register_event ( "HLTV", "EV_NewRound", "a", "1=0", "2=0" )
    register_event ( "DeathMsg", "EV_DeathMsg", "a" )
    
    register_forward ( FM_SetModel, "fw_SetModel" )
    RegisterHam ( Ham_Think, "grenade", "fw_ThinkGrenade" )
    
    cvar_speed = register_cvar ( "ze_zombiebomb_knockback", "800" )
    
    g_msgAmmoPickup = get_user_msgid ( "AmmoPickup" )
    
    g_MaxPlayers = get_maxplayers ( )
}

public client_connect ( Player )
{
    g_iJumpingNadeCount [ Player ] = 0
}

public ze_select_item_pre(id, itemid)
{
    // Return Available and we will block it in Post, So it dosen't affect other plugins
    if (itemid != g_iNadeID)
        return ZE_ITEM_AVAILABLE
   
    // Available for Zombies only, So don't show it for Humans
    if (!ze_is_user_zombie(id))
        return ZE_ITEM_DONT_SHOW
   
    return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid)
{
    if (itemid != g_iNadeID)
        return
	
	if (g_iJumpingNadeCount [ id ] >= MAXCARRY)
	{
		ze_colored_print(id, "!tCannot hold more grenades!y!")
	}
	else if (g_iJumpingNadeCount [ id ] >= 1)
	{
		new iBpAmmo = cs_get_user_bpammo ( id, CSW_SMOKEGRENADE )
		cs_set_user_bpammo ( id, CSW_SMOKEGRENADE, iBpAmmo+1 )
		emit_sound ( id, CHAN_ITEM, g_SoundAmmoPurchase[random_num(0, sizeof g_SoundAmmoPurchase-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
		AmmoPickup ( id, AMMOID_SM, 1 )
		g_iJumpingNadeCount [ id ]++
	}
	else if (g_iJumpingNadeCount [ id ] == 0)
	{
		give_item ( id, "weapon_smokegrenade" )
		emit_sound ( id, CHAN_ITEM, g_SoundGrenadeBuy[random_num(0, sizeof g_SoundGrenadeBuy-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
		AmmoPickup ( id, AMMOID_SM, 1 )
		g_iJumpingNadeCount [ id ] = 1
	}
}

public ze_user_infected (Player, Infector)
{
    g_iJumpingNadeCount [ Player ] = 0        
}

public EV_CurWeapon ( Player )
{
    if ( !is_user_alive ( Player ) || !ze_is_user_zombie ( Player ) )
        return PLUGIN_CONTINUE
    
    g_iCurrentWeapon [ Player ] = read_data ( 2 )
    
    if ( g_iJumpingNadeCount [ Player ] > 0 && g_iCurrentWeapon [ Player ] == CSW_SMOKEGRENADE )
    {
        set_pev ( Player, pev_viewmodel2, g_ViewModel )
        set_pev ( Player, pev_weaponmodel2, g_WorldModel )
    }
    
    return PLUGIN_CONTINUE
}

public EV_NewRound ( )
{
    arrayset ( g_iJumpingNadeCount, 0, 33 )
}

public EV_DeathMsg ( )
{
    new iVictim = read_data ( 2 )
    
    if ( !is_user_connected ( iVictim ) )
        return
    
    g_iJumpingNadeCount [ iVictim ] = 0
}

public fw_SetModel ( Entity, const Model [ ] )
{
    if ( Entity < 0 )
        return FMRES_IGNORED
    
    if ( pev ( Entity, pev_dmgtime ) == 0.0 )
        return FMRES_IGNORED
    
    new iOwner = entity_get_edict ( Entity, EV_ENT_owner )    
    
    if ( g_iJumpingNadeCount [ iOwner ] >= 1 && equal ( Model [ 7 ], "w_sm", 4 ) )
    {
        // Reset any other nade
        set_pev ( Entity, pev_nade_type, 0 )
        
        set_pev ( Entity, pev_nade_type, NADE_TYPE_JUMPING )
        
        g_iJumpingNadeCount [ iOwner ]--
        
        entity_set_model ( Entity, g_WorldModel )
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public fw_ThinkGrenade ( Entity )
{
    if ( !pev_valid ( Entity ) )
        return HAM_IGNORED
    
    static Float:dmg_time
    pev ( Entity, pev_dmgtime, dmg_time )
    
    if ( dmg_time > get_gametime ( ) )
        return HAM_IGNORED
    
    if ( pev ( Entity, pev_nade_type ) == NADE_TYPE_JUMPING )
    {
        jumping_explode ( Entity )
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public jumping_explode ( Entity )
{
    if ( Entity < 0 )
        return
    
    static Float:flOrigin [ 3 ]
    pev ( Entity, pev_origin, flOrigin )
    
    engfunc ( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 )
    write_byte ( TE_SPRITE ) 
    engfunc ( EngFunc_WriteCoord, flOrigin [ 0 ] )
    engfunc ( EngFunc_WriteCoord, flOrigin [ 1 ] )
    engfunc ( EngFunc_WriteCoord, flOrigin [ 2 ] + 45.0 )
    write_short ( g_iExplo )
    write_byte ( 35 )
    write_byte ( 186 )
    message_end ( )
    
    new iOwner = entity_get_edict ( Entity, EV_ENT_owner )
    
    emit_sound ( Entity, CHAN_WEAPON, g_SoundBombExplode[random_num(0, sizeof g_SoundBombExplode-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
    
    for ( new i = 1; i < g_MaxPlayers; i++ )
    {
        if ( !is_user_alive  ( i ) )
            continue
       

        
        // Debug!
        //client_print ( iOwner, print_chat, "Owner of Smoke Grenade!" )    
        
        new Float:flVictimOrigin [ 3 ]
        pev ( i, pev_origin, flVictimOrigin )
        
        new Float:flDistance = get_distance_f ( flOrigin, flVictimOrigin )    
        
        if ( flDistance <= RADIUS )
        {
            static Float:flSpeed
            flSpeed = get_pcvar_float ( cvar_speed )
            
            static Float:flNewSpeed
            flNewSpeed = flSpeed * ( 1.0 - ( flDistance / RADIUS ) )
            
            static Float:flVelocity [ 3 ]
            get_speed_vector ( flOrigin, flVictimOrigin, flNewSpeed, flVelocity )
            
            set_pev ( i, pev_velocity,flVelocity )
        }
    }
    
    engfunc ( EngFunc_RemoveEntity, Entity )
}        

public AmmoPickup ( Player, AmmoID, AmmoAmount )
{
    message_begin ( MSG_ONE, g_msgAmmoPickup, _, Player )
    write_byte ( AmmoID )
    write_byte ( AmmoAmount )
    message_end ( )
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
    new_velocity[0] = origin2[0] - origin1[0]
    new_velocity[1] = origin2[1] - origin1[1]
    new_velocity[2] = origin2[2] - origin1[2]
    new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
    new_velocity[0] *= num
    new_velocity[1] *= num
    new_velocity[2] *= num
    
    return 1;
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
