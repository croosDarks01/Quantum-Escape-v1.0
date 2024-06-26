/* Plugin generated by AMXX-Studio */

#pragma compress 1

#include <amxmodx>
#include <ze_core>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <ze_items_manager>


#define PLUGIN "[ZE] Star Chaser AR"
#define VERSION "1.0"
#define AUTHOR "Bim Bim Cay + Legolas"

// Models
#define v_model "models/zombie_escape/v_starchaserar.mdl"
#define w_model "models/zombie_escape/w_starchaserar.mdl"
#define p_model "models/zombie_escape/p_starchaserar.mdl"

// Sounds
#define attack1_sound "weapons/starchaserar-1.wav"
#define attack2_sound "weapons/starchaserar-2.wav"
#define explode_sound "weapons/starchasersr_exp.wav"

// Sprites
#define muzzle_flash "sprites/muzzleflash76.spr"
#define ef_ball "sprites/ef_starchasersr_star.spr"
#define ef_line "sprites/ef_starchasersr_line.spr"
#define ef_explosion "sprites/ef_starchasersr_explosion.spr"

// Anims
#define ANIM_IDLE		0
#define ANIM_RELOAD		1
#define ANIM_DRAW		2
#define ANIM_SHOOT1		3
#define ANIM_SHOOT2		4
#define ANIM_SHOOT3		5

#define ANIM_EXTENSION 		"carbine"

// Entity Classname
#define BALL_CLASSNAME "StarChaserAREf_Ball"
#define MUZZLEFLASH_CLASSNAME "Muzzle_StarChaserAR"

// Configs
#define WEAPON_NAME 		"weapon_starchaserar"
#define WEAPON_BASE		"weapon_aug"

#define WEAPON_MAX_CLIP		50
#define WEAPON_DEFAULT_AMMO	700

#define WEAPON_SHOOT_DAMAGE	45.0
#define WEAPON_EXPLODE_DAMAGE	150.0
#define WEAPON_EXPLODE_RADIUS	100.0

#define WEAPON_TIME_NEXT_ATTACK 0.1
#define WEAPON_TIME_NEXT_ATTACKZ 0.135
#define AMMO_CHARGE 7

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)
#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsObserver(%0) pev(%0,pev_iuser1)
#define OBS_IN_EYE 4

new g_iszWeaponKey
new g_iForwardDecalIndex
new g_Line_SprId, g_Explode_SprId

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive
new g_iItemID

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_TraceLine, "fw_TraceLine_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	
	unregister_forward(FM_DecalIndex, g_iForwardDecalIndex, 1)
	
	// Think
	register_think(MUZZLEFLASH_CLASSNAME, "fw_MuzzleFlash_Think") 
	register_think(BALL_CLASSNAME, "fw_Ball_Think")
	register_touch(BALL_CLASSNAME, "*", "fw_Ball_Touch")
	
	// Ham
	RegisterHam(Ham_Spawn, "weaponbox", "fw_Weaponbox_Spawn_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, WEAPON_BASE, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_PostFrame, WEAPON_BASE, "fw_Item_PostFrame")
	RegisterHam(Ham_Weapon_Reload, WEAPON_BASE, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_BASE, "fw_Weapon_WeaponIdle")
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE, "fw_Weapon_PrimaryAttack")
	
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack_Entity")
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack_Entity")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Entity")
	
	//register_clcmd("say /star", "Get_MyWeapon")
        g_iItemID = ze_register_item("StarChaseAR", 650, 0)
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(w_model)
	precache_model(p_model)
	
	precache_model(ef_ball)
	precache_model(muzzle_flash)
	
	g_Line_SprId = precache_model(ef_line)
	g_Explode_SprId = precache_model(ef_explosion)
	
	precache_sound(attack1_sound)
	precache_sound(attack2_sound)
	precache_sound(explode_sound)
	
	g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
	g_iForwardDecalIndex = register_forward(FM_DecalIndex, "fw_DecalIndex_Post", 1)
}

public client_putinserver(iPlayer)
{
	Safety_Connected(iPlayer)
	
	if(!g_HamBot && is_user_bot(iPlayer))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", iPlayer)
	}
}
 
public Register_HamBot(iPlayer)
{
	Register_SafetyFuncBot(iPlayer)
	RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "fw_TraceAttack_Entity")	
}

public client_disconnected(iPlayer)
{
	Safety_Disconnected(iPlayer)
}

public Get_MyWeapon(iPlayer)
{
	Weapon_Give(iPlayer)
}

public ze_select_item_pre(iPlayer, itemid)
{
	
	if (itemid != g_iItemID)
		return ZE_ITEM_AVAILABLE
			
	if (ze_is_user_zombie(iPlayer))
		return ZE_ITEM_DONT_SHOW
		
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(iPlayer, itemid)
{
	if (itemid != g_iItemID)
		return
		
	Get_MyWeapon(iPlayer)
} 

//**********************************************
//* Forward Hooking                            *
//********************************************** 
public fw_UpdateClientData_Post(iPlayer, sendweapons, CD_Handle)
{
	enum
	{
		SPEC_MODE,
		SPEC_TARGET,
		SPEC_END
	}
	 
	static aSpecInfo[33][SPEC_END]
	
	static iTarget
	static iSpecMode 
	static iActiveItem
	
	iTarget = (iSpecMode = IsObserver(iPlayer)) ? pev(iPlayer, pev_iuser2) : iPlayer
	
	if(!is_alive(iTarget))
		return FMRES_IGNORED
	
	iActiveItem = get_pdata_cbase(iTarget, 373, 5)
	
	if(!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
		return FMRES_IGNORED
	
	if(iSpecMode)
	{
		if(aSpecInfo[iPlayer][SPEC_MODE] != iSpecMode)
		{
			aSpecInfo[iPlayer][SPEC_MODE] = iSpecMode
			aSpecInfo[iPlayer][SPEC_TARGET] = 0
		}
		
		if(iSpecMode == OBS_IN_EYE && aSpecInfo[iPlayer][SPEC_TARGET] != iTarget)
		{
			aSpecInfo[iPlayer][SPEC_TARGET] = iTarget
			
			Weapon_SendAnim(iPlayer, iActiveItem, ANIM_IDLE)
		}
	}
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	
	return FMRES_HANDLED
}

public fw_TraceLine_Post(Float:TraceStart[3], Float:TraceEnd[3], fNoMonsters, iEntToSkip, iTrace) <FireBullets: Enabled>
{
	static Float:vecEndPos[3]
	
	get_tr2(iTrace, TR_vecEndPos, vecEndPos)
	engfunc(EngFunc_TraceLine, vecEndPos, TraceStart, fNoMonsters, iEntToSkip, 0)
	
	UTIL_GunshotDecalTrace(0)
	UTIL_GunshotDecalTrace(iTrace, true)
}

public fw_TraceLine_Post() </* Empty statement */>
{
	/* Fallback */
}

public fw_TraceLine_Post() <FireBullets: Disabled>	
{
	/* Do notning */
}

public fw_PlaybackEvent() <FireBullets: Enabled>
{
	return FMRES_SUPERCEDE
}

public fw_PlaybackEvent() </* Empty statement */>		
{ 
	return FMRES_IGNORED 
}

public fw_PlaybackEvent() <FireBullets: Disabled>		
{ 
	return FMRES_IGNORED 
}

//**********************************************
//* Weaponbox world model.                     *
//**********************************************
public fw_SetModel(iEntity) <WeaponBox: Enabled>
{
	state WeaponBox: Disabled
	
	if(!IsValidPev(iEntity))
		return FMRES_IGNORED
	
	#define MAX_ITEM_TYPES	6
	for(new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, 34 + i, 4)
		
		if(IsValidPev(iItem) && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, w_model)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_SetModel() </* Empty statement */>	
{ 
	/*  Fallback  */ 
	return FMRES_IGNORED 
}
public fw_SetModel() <WeaponBox: Disabled>	
{ 
	/* Do nothing */ 
	return FMRES_IGNORED 
}

public fw_Weaponbox_Spawn_Post(iWeaponBox)
{
	if(IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled
	}
	
	return HAM_IGNORED
}

//**********************************************
//* Weapon's codes.                     *
//**********************************************
public fw_Item_Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem))
		return
		
	static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)	
	
	set_pev(iPlayer, pev_viewmodel2, v_model)
	set_pev(iPlayer, pev_weaponmodel2, p_model)
	
	Weapon_SendAnim(iPlayer, iItem, ANIM_DRAW)
	
	set_pdata_string(iPlayer, (492) * 4, ANIM_EXTENSION, -1 , 20)
}

public fw_Item_PostFrame(iItem)
{
	if(!IsCustomItem(iItem))
		return HAM_IGNORED
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
	
	if(get_pdata_int(iItem, 54, 4))
	{
		static iClip; iClip = get_pdata_int(iItem, 51, 4)
		static iPrimaryAmmoIndex; iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem)
		static iAmmoPrimary; iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex)
		static iAmount; iAmount = min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary)
		
		set_pdata_int(iItem, 51, iClip + iAmount, 4)
		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount)
		
		set_pdata_int(iItem, 54, 0, 4)
	}	
	
	return HAM_IGNORED
}

public fw_Weapon_Reload(iItem)
{
	if(!IsCustomItem(iItem))
		return HAM_IGNORED
		
	static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)	
	
	static iClip; iClip = get_pdata_int(iItem, 51, 4)
	static iPrimaryAmmoIndex; iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem)
	static iAmmoPrimary; iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex)
	
	if(min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
		return HAM_SUPERCEDE
	
	set_pdata_int(iItem, 51, 0, 4)
	
	ExecuteHam(Ham_Weapon_Reload, iItem)
	
	set_pdata_int(iItem, 51, iClip, 4)
	
	set_pdata_float(iPlayer, 83, 3.2, 5)
	set_pdata_float(iItem, 48, 3.2, 4)
	
	Weapon_SendAnim(iPlayer, iItem, ANIM_RELOAD)
	
	return HAM_SUPERCEDE	
}

public fw_Weapon_WeaponIdle(iItem)
{
	if(!IsCustomItem(iItem))
		return HAM_IGNORED
		
	static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)	
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem)

	if(get_pdata_float(iItem, 48, 4) > 0.0)
		return HAM_SUPERCEDE
	
	set_pdata_float(iItem, 48, 10.0, 4)
	
	Weapon_SendAnim(iPlayer, iItem, ANIM_IDLE)
	
	return HAM_SUPERCEDE
}

public fw_Weapon_PrimaryAttack(iItem)
{
	if(!IsCustomItem(iItem))
		return HAM_IGNORED
		
	static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)	
	static iClip; iClip = get_pdata_int(iItem, 51, 4)
	
	if(iClip <= 0)
	{
		// No ammo, play empty sound and cancel
		if(get_pdata_int(iItem, 45, 4))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem)
			set_pdata_float(iItem, 46, 0.2, 4)
		}
	
		return HAM_SUPERCEDE
	}
	
	CallOriginalFireBullets(iItem, iPlayer)
	
	static iFlags
	static szAnimation[64], Float:Velocity[3]

	iFlags = pev(iPlayer, pev_flags)
	
	if(iFlags & FL_DUCKING)
	{
		formatex(szAnimation, charsmax(szAnimation), "crouch_shoot_%s", ANIM_EXTENSION)
	}
	else
	{
		formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION)
	}
	
	Player_SetAnimation(iPlayer, szAnimation)
	
	static ShootAnim
	switch(random_num(0, 2))
	{
		case 0: ShootAnim = ANIM_SHOOT1
		case 1: ShootAnim = ANIM_SHOOT2
		case 2: ShootAnim = ANIM_SHOOT3
	}
		
	Weapon_SendAnim(iPlayer, iItem, ShootAnim)
	
	set_pdata_float(iItem, 48, 0.7, 4)
	
	if(pev(iPlayer, pev_fov) == 90)
	{
		set_pdata_float(iItem, 46, WEAPON_TIME_NEXT_ATTACK, 4)
		set_pdata_float(iItem, 47, WEAPON_TIME_NEXT_ATTACK, 4)
	}
	else
	{
		set_pdata_float(iItem, 46, WEAPON_TIME_NEXT_ATTACKZ, 4)
		set_pdata_float(iItem, 47, WEAPON_TIME_NEXT_ATTACKZ, 4)
	}
	
	pev(iPlayer, pev_velocity, Velocity)
	
	if(xs_vec_len(Velocity) > 0)
	{
		Weapon_KickBack(iItem, iPlayer, 1.0, 0.45, 0.275, 0.05, 4.0, 2.5, 7)
	}
	else if(!(iFlags & FL_ONGROUND))
	{
		Weapon_KickBack(iItem, iPlayer, 1.25, 0.45, 0.22, 0.18, 5.5, 4.0, 5)
	}
	else if(iFlags & FL_DUCKING)
	{
		Weapon_KickBack(iItem, iPlayer, 0.575, 0.325, 0.2, 0.011, 3.25, 2.0, 8)
	}
	else
	{
		Weapon_KickBack(iItem, iPlayer, 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8)
	}

	Make_MuzzleFlash(iPlayer)
	
	static AmmoCharge; AmmoCharge = get_pdata_int(iItem, 30, 4)
	
	if(AmmoCharge < AMMO_CHARGE)
	{
		set_pdata_int(iItem, 30, AmmoCharge + 1, 4)
		
		emit_sound(iPlayer, CHAN_WEAPON, attack1_sound, 1.0, 0.4, 0, 94 + random_num(0, 15))
	}
	else
	{
		set_pdata_int(iItem, 30, 0, 4)
		
		emit_sound(iPlayer, CHAN_WEAPON, attack2_sound, 1.0, 0.4, 0, 94 + random_num(0, 15))
		
		Create_Star(iPlayer)	
	}
	
	return HAM_SUPERCEDE
}

public fw_TraceAttack_Entity(iEntity, iAttacker, Float: flDamage) <FireBullets: Enabled>
{
	SetHamParamFloat(3, WEAPON_SHOOT_DAMAGE)
}

public fw_TraceAttack_Entity() </* Empty statement */>		
{ 
	/* Fallback */ 
}

public fw_TraceAttack_Entity() <FireBullets: Disabled>		
{ 
	/* Do notning */ 
}

//**********************************************
//* Effects                                    *
//**********************************************
Make_MuzzleFlash(iPlayer)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

	set_pev(Ent, pev_classname, MUZZLEFLASH_CLASSNAME)
	
	set_pev(Ent, pev_owner, iPlayer)
	set_pev(Ent, pev_body, 1)
	set_pev(Ent, pev_skin, iPlayer)
	set_pev(Ent, pev_aiment, iPlayer)
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	
	engfunc(EngFunc_SetModel, Ent, muzzle_flash)
	
	set_pev(Ent, pev_scale, 0.04)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 250.0)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
}

public fw_MuzzleFlash_Think(Ent)
{
	if(!pev_valid(Ent))
		return
	
	static Owner; Owner = pev(Ent, pev_owner)
	
	if(!is_alive(Owner))
	{
		set_pev(Ent, pev_flags, FL_KILLME)
		return
	}
	
	static iActiveItem; iActiveItem = get_pdata_cbase(Owner, 373, 5)
	
	if(!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		set_pev(Ent, pev_flags, FL_KILLME)
		return
	}

	static Float:Frame; pev(Ent, pev_frame, Frame)
	if(Frame > 2.0) 
	{
		set_pev(Ent, pev_flags, FL_KILLME)
		return
	}
	else
	{
		Frame += 1.0
		set_pev(Ent, pev_frame, Frame)
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
}

public Create_Star(iPlayer)
{
	static Float:Origin[3]
	
	if(get_cvar_num("cl_righthand"))
	{
		Get_Position(iPlayer, 48.0, 10.0, -5.0, Origin)
	}
	else
	{
		Get_Position(iPlayer, 48.0, -10.0, -5.0, Origin)
	}

	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(Ent)) 
		return
		
	engfunc(EngFunc_SetModel, Ent, ef_ball)	
	
	set_pev(Ent, pev_classname, BALL_CLASSNAME)
	set_pev(Ent, pev_movetype, MOVETYPE_FLYMISSILE)
	set_pev(Ent, pev_owner, iPlayer)
	set_pev(Ent, pev_origin, Origin)
	
	set_pev(Ent, pev_solid, SOLID_SLIDEBOX)
	set_pev(Ent, pev_mins, {-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, {1.0, 1.0, 1.0})
	
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 255.0)
	set_pev(Ent, pev_scale, 0.075)
	set_pev(Ent, pev_frame, 0.0)
	
	// Create Velocity
	static Float:Velocity[3], Float:TargetOrigin[3]
	
	fm_get_aim_origin(iPlayer, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, 2500.0, Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}

public fw_Ball_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	new Float:fFrame
	pev(Ent, pev_frame, fFrame)
	
	// effect exp
	if(fFrame <= 14.0) 
	{
		fFrame += 1.0
		
	}
	else
	{
		fFrame = 0.0
	}
	
	set_pev(Ent, pev_frame, fFrame)
	
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Line_SprId)	// sprite index
	write_byte(3)	// scale in 3.4's
	write_byte(20)	// framerate
	write_byte(TE_FLAG)	// flags
	message_end()
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)	
}

public fw_Ball_Touch(Ent, Touch)
{
	if(!pev_valid(Ent)) 
		return
		
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Explode_SprId)	// sprite index
	write_byte(7)	// scale in 3.4's
	write_byte(45)	// framerate
	write_byte(TE_FLAG)	// flags
	message_end()
	
	emit_sound(Ent, CHAN_BODY, explode_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static Owner; Owner = pev(Ent, pev_owner)
	
	if(is_connected(Owner))
	{
		static Victim; Victim = -1
		while((Victim = find_ent_in_sphere(Victim, Origin, WEAPON_EXPLODE_RADIUS)) != 0)
		{
			if(is_alive(Victim))
			{
				if(Victim == Owner)
					continue
			}
			else
			{
				if(pev(Victim, pev_takedamage) == DAMAGE_NO)
					continue
			}
		
			ExecuteHamB(Ham_TakeDamage, Victim, Ent, Owner, WEAPON_EXPLODE_DAMAGE, DMG_BULLET)
		}
	}
	
	set_pev(Ent, pev_flags, FL_KILLME)
}

//**********************************************
//* Safety Functions        		       *
//**********************************************
public Register_SafetyFunc()
{
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(iPlayer)
{
	RegisterHamFromEntity(Ham_Spawn, iPlayer, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, iPlayer, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(iPlayer)
{
	Set_BitVar(g_IsConnected, iPlayer)
	UnSet_BitVar(g_IsAlive, iPlayer)
}

public Safety_Disconnected(iPlayer)
{
	UnSet_BitVar(g_IsConnected, iPlayer)
	UnSet_BitVar(g_IsAlive, iPlayer)
}

public fw_Safety_Spawn_Post(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return
		
	Set_BitVar(g_IsAlive, iPlayer)
}

public fw_Safety_Killed_Post(iPlayer)
{
	UnSet_BitVar(g_IsAlive, iPlayer)
}

public is_connected(iPlayer)
{
	if(!(1 <= iPlayer <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, iPlayer))
		return 0

	return 1
}

public is_alive(iPlayer)
{
	if(!is_connected(iPlayer))
		return 0
	if(!Get_BitVar(g_IsAlive, iPlayer))
		return 0
		
	return 1
}

//**********************************************
//* Create and check our custom weapon.        *
//**********************************************
IsCustomItem(iItem)
{
	return (pev(iItem, pev_impulse) == g_iszWeaponKey)
}

Weapon_Create(Float: Origin[3] = {0.0, 0.0, 0.0}, Float: Angles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon

	static iszAllocStringCached
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_BASE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached)
	}
	
	if(!IsValidPev(iWeapon))
		return FM_NULLENT
	
	dllfunc(DLLFunc_Spawn, iWeapon)
	set_pev(iWeapon, pev_origin, Origin)

	set_pdata_int(iWeapon, 51, WEAPON_MAX_CLIP, 4)
	set_pdata_int(iWeapon, 30, 0, 4)

	set_pev(iWeapon, pev_impulse, g_iszWeaponKey)
	set_pev(iWeapon, pev_angles, Angles)
	
	engfunc(EngFunc_SetModel, iWeapon, w_model)

	return iWeapon
}

Weapon_Give(iPlayer)
{
	if(!IsValidPev(iPlayer))
	{
		return FM_NULLENT
	}
	
	new iWeapon, Float: vecOrigin[3]
	pev(iPlayer, pev_origin, vecOrigin)
	
	if((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon))
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN)
		dllfunc(DLLFunc_Touch, iWeapon, iPlayer)
		
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO)
		
		return iWeapon
	}
	
	return FM_NULLENT
}

Player_DropWeapons(iPlayer, iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, 367 + iSlot, 5)

	while(IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName))
		engclient_cmd(iPlayer, "drop", szWeaponName)

		iItem = get_pdata_cbase(iItem, 42, 4)
	}
}

//**********************************************
//* Ammo Inventory.                            *
//**********************************************
PrimaryAmmoIndex(iItem)
{
	return get_pdata_int(iItem, 49, 4)
}

GetAmmoInventory(iPlayer, iAmmoIndex)
{
	if(iAmmoIndex == -1)
		return -1
	
	return get_pdata_int(iPlayer, 376 + iAmmoIndex, 5)
}

SetAmmoInventory(iPlayer, iAmmoIndex, iAmount)
{
	if(iAmmoIndex == -1)
		return 0
	
	set_pdata_int(iPlayer, 376 + iAmmoIndex, iAmount, 5)
	
	return 1
}

//**********************************************
//* Fire Bullets.                              *
//**********************************************
CallOriginalFireBullets(iItem, iPlayer)
{
	state FireBullets: Enabled
	static Float:g_Recoil[3]

	pev(iPlayer, pev_punchangle, g_Recoil)
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem)
	set_pev(iPlayer, pev_punchangle, g_Recoil)
	
	state FireBullets: Disabled
}

//**********************************************
//* Decals.                                    *
//**********************************************
new Array: g_hDecals

public fw_DecalIndex_Post()
{
	if(!g_hDecals)
	{
		g_hDecals = ArrayCreate(1, 1)
	}
	
	ArrayPushCell(g_hDecals, get_orig_retval())
}

UTIL_GunshotDecalTrace(iTrace, bool: bIsGunshot = false)
{
	static iHit
	static iMessage
	static iDecalIndex
	
	static Float:flFraction 
	static Float:vecEndPos[3]
	
	iHit = INSTANCE(get_tr2(iTrace, TR_pHit))
	
	if(iHit && !IsValidPev(iHit) || (pev(iHit, pev_flags) & FL_KILLME))
		return
	
	if(pev(iHit, pev_solid) != SOLID_BSP && pev(iHit, pev_movetype) != MOVETYPE_PUSHSTEP)
		return
	
	iDecalIndex = ExecuteHamB(Ham_DamageDecal, iHit, 0)
	
	if(iDecalIndex < 0 || iDecalIndex >=  ArraySize(g_hDecals))
		return
	
	iDecalIndex = ArrayGetCell(g_hDecals, iDecalIndex)
	
	get_tr2(iTrace, TR_flFraction, flFraction)
	get_tr2(iTrace, TR_vecEndPos, vecEndPos)
	
	if(iDecalIndex < 0 || flFraction >= 1.0)
		return
	
	if(bIsGunshot)
	{
		iMessage = TE_GUNSHOTDECAL
	}
	else
	{
		iMessage = TE_DECAL
		
		if(iHit != 0)
		{
			if(iDecalIndex > 255)
			{
				iMessage = TE_DECALHIGH
				iDecalIndex -= 256
			}
		}
		else
		{
			iMessage = TE_WORLDDECAL
			
			if(iDecalIndex > 255)
			{
				iMessage = TE_WORLDDECALHIGH
				iDecalIndex -= 256
			}
		}
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0)
	write_byte(iMessage)
	engfunc(EngFunc_WriteCoord, vecEndPos[0])
	engfunc(EngFunc_WriteCoord, vecEndPos[1])
	engfunc(EngFunc_WriteCoord, vecEndPos[2])

	if(bIsGunshot)
	{
		write_short(iHit)
		write_byte(iDecalIndex)
	}
	else 
	{
		write_byte(iDecalIndex)
		
		if(iHit)
		{
			write_short(iHit)
		}
	}
    
	message_end()
}

//**********************************************
//* Set Animations.                            *
//**********************************************
stock Weapon_SendAnim(iPlayer, iItem, iAnim)
{
	static i, iCount, iSpectator, aSpectators[32]
	
	set_pev(iPlayer, pev_weaponanim, iAnim)

	message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iPlayer)
	write_byte(iAnim)
	write_byte(pev(iItem, pev_body))
	message_end()
	
	if(IsObserver(iPlayer))
		return
	
	get_players(aSpectators, iCount, "bch")

	for(i = 0; i < iCount; i++)
	{
		iSpectator = aSpectators[i]
		
		if(IsObserver(iSpectator) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != iPlayer)
			continue
		
		set_pev(iSpectator, pev_weaponanim, iAnim)

		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iSpectator)
		write_byte(iAnim)
		write_byte(pev(iItem, pev_body))
		message_end()
	}
}

stock Player_SetAnimation(iPlayer, szAnim[])
{
	#define ACT_RANGE_ATTACK1   28
   
	// Linux extra offsets
	#define extra_offset_animating   4
	#define extra_offset_player 5
   
	// CBaseAnimating
	#define m_flFrameRate      36
	#define m_flGroundSpeed      37
	#define m_flLastEventCheck   38
	#define m_fSequenceFinished   39
	#define m_fSequenceLoops   40
   
	// CBaseMonster
	#define m_Activity      73
	#define m_IdealActivity      74
   
	// CBasePlayer
	#define m_flLastAttackTime   220
   
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops
      
	if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	{
		iAnimDesired = 0
	}
   
	static Float:flGametime; flGametime = get_gametime()

	set_pev(iPlayer, pev_frame, 0.0)
	set_pev(iPlayer, pev_framerate, 1.0)
	set_pev(iPlayer, pev_animtime, flGametime)
	set_pev(iPlayer, pev_sequence, iAnimDesired)
   
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating)
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating)
   
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating)
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating)
	set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating)
   
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player)
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player)  
	set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player)
}

//**********************************************
//* Kick back.                                 *
//**********************************************
Weapon_KickBack(iItem, iPlayer, Float:upBase, Float:lateralBase, Float:upMod, Float:lateralMod, Float:upMax, Float:lateralMax, directionChange)
{
	static iDirection
	static iShotsFired 
	
	static Float: Punchangle[3]
	pev(iPlayer, pev_punchangle, Punchangle)
	
	if((iShotsFired = get_pdata_int(iItem, 64, 4)) != 1)
	{
		upBase += iShotsFired * upMod
		lateralBase += iShotsFired * lateralMod
	}
	
	upMax *= -1.0
	Punchangle[0] -= upBase
 
	if(upMax >= Punchangle[0])
	{
		Punchangle[0] = upMax
	}
	
	if((iDirection = get_pdata_int(iItem, 60, 4)))
	{
		Punchangle[1] += lateralBase
		
		if(lateralMax < Punchangle[1])
		{
			Punchangle[1] = lateralMax
		}
	}
	else
	{
		lateralMax *= -1.0;
		Punchangle[1] -= lateralBase
		
		if(lateralMax > Punchangle[1])
		{
			Punchangle[1] = lateralMax
		}
	}
	
	if(!random_num(0, directionChange))
	{
		set_pdata_int(iItem, 60, !iDirection, 4)
	}
	
	set_pev(iPlayer, pev_punchangle, Punchangle)
}

//**********************************************
//* Some useful stocks.                        *
//**********************************************
stock get_speed_vector(Float:Origin1[3], Float:Origin2[3], Float:Speed, Float:NewVelocity[3])
{
	NewVelocity[0] = Origin2[0] - Origin1[0]
	NewVelocity[1] = Origin2[1] - Origin1[1]
	NewVelocity[2] = Origin2[2] - Origin1[2]
	new Float:num = floatsqroot(Speed*Speed / (NewVelocity[0]*NewVelocity[0] + NewVelocity[1]*NewVelocity[1] + NewVelocity[2]*NewVelocity[2]))
	NewVelocity[0] *= num
	NewVelocity[1] *= num
	NewVelocity[2] *= num
	
	return 1
}

stock Get_Position(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:Origin[3], Float:Angles[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(iPlayer, pev_origin, Origin)
	pev(iPlayer, pev_view_ofs,vUp) //for player
	xs_vec_add(Origin, vUp, Origin)
	pev(iPlayer, pev_v_angle, Angles) // if normal entity ,use pev_angles
	
	angle_vector(Angles, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(Angles, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(Angles, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = Origin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = Origin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = Origin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
