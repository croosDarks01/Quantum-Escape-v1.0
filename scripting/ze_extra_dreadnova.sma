#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <ze_items_manager>
#include <ze_core>
#include <xs>

// https://forums.alliedmods.net/showthread.php?t=184780
#include <beams>

#define IsCustomItem(%1) (get_pdata_int(%1, m_iId, linux_diff_weapon) == CSW_KNIFE)
#define IsUserHasDreadNova(%1) get_bit(gl_iBitUserHasDreadNova, %1)
#define IsUserHasSummoner(%1) get_bit(gl_iBitUserHasSummoner, %1)
#define DreadNovaInBMode(%1) (get_pdata_int(%1, m_iAttackState, linux_diff_weapon) >= WPNSTATE_KNIFE_B)
#define getComboData(%1) (get_pdata_int(%1, m_iComboData, linux_diff_weapon))
#define setComboData(%1,%2) (set_pdata_int(%1, m_iComboData, %2, linux_diff_weapon))

#define m_iSlashAnim m_iGlock18ShotsFired
#define m_iAttackState m_iFamasShotsFired
#define m_iComboData m_iWeaponState

#define pev_flHoldTime pev_fuser1
#define pev_flNextEnergy pev_fuser2
#define pev_iEnergy pev_iuser1

#define pev_iSumAnim pev_iuser3
#define pev_iSumState pev_iuser4

#define get_bit(%1,%2) ((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2) %1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2) %1 &= ~(1 << (%2 & 31))

#define DONT_BLEED -1
#define PDATA_SAFE 2
#define ACT_RANGE_ATTACK1 28
#define DMG_GRENADE (1<<24)

enum
{
	WPNSTATE_KNIFE_A = 0,
	WPNSTATE_KNIFE_A_ATTACK,

	WPNSTATE_KNIFE_B,
	WPNSTATE_KNIFE_B_ATTACK,
	WPNSTATE_KNIFE_B_HIT,
	WPNSTATE_KNIFE_B_CHARGE,
	WPNSTATE_KNIFE_B_CHARGE_HIT,
	WPNSTATE_KNIFE_B_CHARGE_END
};

enum
{
	SUMMONER_IDLE = 0,
	SUMMONER_SLASH,
	SUMMONER_SLASH_HIT,
	SUMMONER_SLASH_END,
	SUMMONER_STAB,
	SUMMONER_STAB_FIRE,
	SUMMONER_STAB_END,
	SUMMONER_SPAWN,
	SUMMONER_DISAPPEAR
};

/* ~ [ Weapon Settings ] ~ */
#define ADD_KNIFE_TO_EXTRA_ITEMS false
#define REMOVE_KNIFE_IF_INFECTED true

new const WEAPON_REFERENCE[] = "weapon_knife";
new const WEAPON_WEAPONLIST[] = "x/knife_summonknife";
new const WEAPON_MODEL_VIEW[] = "models/x/v_summonknife.mdl";
new const WEAPON_MODEL_PLAYER[][] =
{
	"models/x/p_summonknife_a.mdl",
	"models/x/p_summonknife_b.mdl",
	"models/x/p_summonknife_charging.mdl"
};
new const WEAPON_ANIMATIONS[][] = 
{
	"knife", // A mode (in CSO: katanad)
	"knife" // B mode (in CSO: sfsword)
};
new const WEAPON_SOUNDS[][] = 
{
	// Slash
	"weapons/summonknife1.wav", // 0
	"weapons/summonknife2.wav", // 1
	"weapons/summonknife3.wav", // 2
	"weapons/summonknife4.wav", // 3

	// Stab
	"weapons/summonknife_stab.wav", // 4
	"weapons/summonknife_charging_relese.wav", // 5
	
	// Hit Sounds
	"weapons/mastercombat_hit1.wav", // 6
	"weapons/mastercombat_stab.wav", // 7
	"weapons/mastercombat_wall.wav", // 8

	// Summoner ready
	"weapons/summoning_ready.wav" // 9
};
new const WEAPON_COMBO_DATA[] = { 1, 1, 0 }; // 0 - Slash, 1 - stab
const Float: WEAPON_NEXT_ATTACK = 0.27;

const WEAPON_MAX_ENERGY = 100;
const Float: WEAPON_ENERGY_LEFT = 0.15; // time for lost energy in summoner mode
const Float: WEAPON_ENERGY_DELAY = 0.25; // time for new energy

const Float: WEAPON_SLASH_DISTANCE = 125.0;
const Float: WEAPON_SLASH_DAMAGE = 200.0;
const Float: WEAPON_SLASH_DAMAGE_EX = 250.0;
const Float: WEAPON_SLASH_KNOCKBACK = 130.0;

const Float: WEAPON_STAB_DISTANCE = 150.0;
const Float: WEAPON_STAB_DAMAGE = 300.0;
const Float: WEAPON_STAB_KNOCKBACK = 500.0;

const Float: ENTITY_EXP_KNOCK_POWER = 1500.0; // It is knockback for victims of laser and cannon explosions

/* ~ [ TraceLine: Attack Angles ] ~ */
new Float: flAngles_Forward[] =
{ 
	0.0, 
	2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0,
	-2.5, -5.0, -7.5, -10.0, -12.5, -15.0, -17.5, -20.0, -22.5, -25.0
};

/* ~ [ Entity: Cannon ] ~ */
new const ENTITY_CANNON_CLASSNAME[] = "ent_dn_cannon";
new const ENTITY_CANNON_MODEL[] = "models/x/ef_summonknife_cannon.mdl";
new const ENTITY_CANNON_SOUND[] = "weapons/plasmagun_exp.wav"; // idk what sounds use in CSO, but it sound similar original
new const ENTITY_CANNON_SPRITE[] = "sprites/x/ef_summon_charging_exp.spr";
const Float: ENTITY_CANNON_SPEED = 1500.0;
const Float: ENTITY_CANNON_RADIUS = 100.0;
const ENTITY_CANNON_DMGTYPE = DMG_GRENADE;
#define ENTITY_CANNON_DAMAGE random_float(500.0, 700.0)

/* ~ [ Entity: Summoner ] ~ */
new const ENTITY_SUMMONER_CLASSNAME[] = "ent_dn_summoner";
new const ENTITY_SUMMONER_MODEL[] = "models/x/summoner.mdl";
new const ENTITY_SUMMONER_SPRITES[][] =
{
	"sprites/x/ef_summoner_summon02.spr", // 0 | summon
	"sprites/x/ef_summoner_unsummon02.spr", // 1 | disappear
	"sprites/x/ef_summoner_stab1.spr" // 2 | stab exp
};
new const ENTITY_SUMMONER_SOUNDS[][] =
{
	// Summoner slash
	"weapons/summon_slash1.wav", // 0
	"weapons/summon_slash2.wav", // 1
	"weapons/summon_slash3.wav", // 2
	"weapons/summon_slash4.wav", // 3

	// Summoner stab
	"weapons/summon_stab.wav", // 4 | start
	"weapons/summon_stab_fire.wav", // 5 | fire

	// Summoner spawn and disappear
	"weapons/summon_summon.wav", // 6 | spawn
	"weapons/summon_unsummon.wav" // 7 | die
};
const Float: ENTITY_SUMMONER_RAISED = 10.0;
const Float: ENTITY_SUMMONER_NEXTTHINK = 0.1; // in idle (im recomend 0.1)
const Float: SUMMONER_SLASH_DISTANCE = 200.0;
const Float: SUMMONER_SLASH_DAMAGE = 300.0;
const Float: SUMMONER_SLASH_KNOCKBACK = 300.0;
const Float: SUMMONER_STAB_EXP_RADIUS = 150.0;
const SUMMONER_STAB_EXP_DMGTYPE = DMG_GRENADE;
#define ENTITY_STAB_EXP_DAMAGE random_float(300.0, 400.0)

/* ~ [ Entity: Summoner Swing ] ~ */
new const ENTITY_SWING_CLASSNAME[] = "ent_dn_swing";
new const ENTITY_SWING_MODEL[] = "models/x/ef_summoner_swing.mdl";

/* ~ [ Entity: Explosion Ring ] ~ */
new const ENTITY_RING_CLASSNAME[] = "ent_dn_ring";
new const ENTITY_RING_MODEL[] = "models/x/ef_summoner_summoning.mdl";
const Float: ENTITY_RING_KNOCK_RADIUS = 250.0;
const Float: ENTITY_RING_KNOCK_POWER = 50.0;

/* ~ [ Entity: Beam ] ~ */
new const ENTITY_BEAM_CLASSNAME[] = "ent_dn_beam";
new const ENTITY_BEAM_SPRITE[] = "sprites/x/ef_summoner_laserbeam.spr";
const Float: ENTITY_BEAM_WIDTH = 350.0;
const Float: ENTITY_BEAM_BRIGHTNESS = 255.0;
const Float: ENTITY_BEAM_SCROLLRATE = 16.0;
#define ENTITY_BEAM_COLOR {255.0, 255.0, 255.0}

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 61/30.0
#define WEAPON_ANIM_SLASH_TIME 16/30.0
#define WEAPON_ANIM_SLASH_END_TIME 26/30.0
#define WEAPON_ANIM_DRAW_A_TIME 21/30.0
#define WEAPON_ANIM_STAB1_TIME 26/30.0
#define WEAPON_ANIM_STAB2_TIME 21/30.0
#define WEAPON_ANIM_STAB_END_TIME 26/30.0
#define WEAPON_ANIM_DRAW_B_TIME 31/30.0
#define WEAPON_ANIM_CHARGING_S_TIME 40/30.0
#define WEAPON_ANIM_CHARGING_L_TIME 11/30.0
#define WEAPON_ANIM_CHARGING_R_TIME 26/30.0
#define WEAPON_ANIM_SUMMONING_TIME 40/30.0

enum
{
	WEAPON_ANIM_IDLE_A = 0,
	WEAPON_ANIM_SLASH_1,
	WEAPON_ANIM_SLASH_2,
	WEAPON_ANIM_SLASH_3,
	WEAPON_ANIM_SLASH_4,
	WEAPON_ANIM_SLASH_END,
	WEAPON_ANIM_DRAW_A,
	WEAPON_ANIM_IDLE_B,
	WEAPON_ANIM_STAB1, // from A mode
	WEAPON_ANIM_STAB2,
	WEAPON_ANIM_STAB_END,
	WEAPON_ANIM_DRAW_B,
	WEAPON_ANIM_CHARGING_START,
	WEAPON_ANIM_CHARGING_LOOP,
	WEAPON_ANIM_CHARGING_RELEASE,
	WEAPON_ANIM_SUMMONING
};

/* ~ [ Summoner Animations ] ~ */
enum
{
	SUMMONER_ANIM_IDLE = 0,
	SUMMONER_ANIM_SLASH,
	SUMMONER_ANIM_STAB = 5,
	SUMMONER_ANIM_SUMMON
};

#define SUMMONER_ANIM_IDLE_TIME 151/30.0
#define SUMMONER_ANIM_SLASH_TIME 41/30.0 - 0.4
#define SUMMONER_ANIM_STAB_TIME 61/30.0 - 0.5
#define SUMMONER_ANIM_SUMMON_TIME 83/30.0

/* ~ [ Offset's ] ~ */
// Linux extra offsets
#define linux_diff_animating 4
#define linux_diff_weapon 4
#define linux_diff_player 5

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40

// CBasePlayerItem
#define m_pPlayer 41
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iGlock18ShotsFired 70
#define m_iFamasShotsFired 72
#define m_iWeaponState 74

// CBaseMonster
#define m_Activity 73
#define m_IdealActivity 74
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_flLastAttackTime 220
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_szAnimExtention 492

/* ~ [ Param's ] ~ */
new gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Cannon,
	gl_iszAllocString_Summoner,
	gl_iszAllocString_ExplosionRing,
	gl_iszAllocString_Swing,
	gl_iszAllocString_BeamKey,

	gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,
	gl_iszModelIndex_CannonExp,
	gl_iszModelIndex_LaserExp,

	gl_iszModelIndex_Summon,
	gl_iszModelIndex_Unsummon,

	gl_iMsgID_AmmoX,
	gl_iMsgID_CurWeapon,
	gl_iMsgID_WeaponList,
	gl_iMsgID_ScreenFade,

	gl_iBitUserHasDreadNova,
	gl_iBitUserHasSummoner,

	gl_iMaxPlayers;



public plugin_init()
{
	// https://cso.fandom.com/wiki/Dread_Nova
	register_plugin("[ZE] Knife: Dread Nova", "1.0 | 2019", "xUnicorn (t3rkecorejz)");


	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");

	register_forward(FM_UpdateClientData, 	"FM_Hook_UpdateClientData_Post", true);

	// Weapon
	RegisterHam(Ham_Weapon_WeaponIdle, 		WEAPON_REFERENCE, 	"CKnife__Idle_Pre", false);
	RegisterHam(Ham_Item_Deploy, 			WEAPON_REFERENCE, 	"CKnife__Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, 			WEAPON_REFERENCE, 	"CKnife__Holster_Post", true);
	RegisterHam(Ham_Item_PostFrame, 		WEAPON_REFERENCE, 	"CKnife__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, 	WEAPON_REFERENCE, 	"CKnife__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE, 	"CKnife__SecondaryAttack_Pre", false);

	// Entity
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Post", true);
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Think,					"beam",				"CBeam__Think_Pre", false);
	RegisterHam(Ham_Player_PreThink,		"player",			"CPlayer__PreThink_Pre", false);

	gl_iMaxPlayers = get_maxplayers();

	// Messages
	gl_iMsgID_AmmoX = get_user_msgid("AmmoX");
	gl_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	gl_iMsgID_WeaponList = get_user_msgid("WeaponList");
	gl_iMsgID_ScreenFade = get_user_msgid("ScreenFade");
}

public plugin_precache()
{
	// Weapon List
	register_clcmd(WEAPON_WEAPONLIST, "Command__HookWeapon");

	new i;

	// Models
	for(i = 0; i < sizeof WEAPON_MODEL_PLAYER; i++)
		engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER[i]);

	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, ENTITY_CANNON_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_SUMMONER_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_RING_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_SWING_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_BEAM_SPRITE);

	// Sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	for(i = 0; i < sizeof ENTITY_SUMMONER_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, ENTITY_SUMMONER_SOUNDS[i]);

	engfunc(EngFunc_PrecacheSound, ENTITY_CANNON_SOUND);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);

	// Alloc String
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Cannon = engfunc(EngFunc_AllocString, ENTITY_CANNON_CLASSNAME);
	gl_iszAllocString_Summoner = engfunc(EngFunc_AllocString, ENTITY_SUMMONER_CLASSNAME);
	gl_iszAllocString_ExplosionRing = engfunc(EngFunc_AllocString, ENTITY_RING_CLASSNAME);
	gl_iszAllocString_Swing = engfunc(EngFunc_AllocString, ENTITY_SWING_CLASSNAME);
	gl_iszAllocString_BeamKey = engfunc(EngFunc_AllocString, ENTITY_BEAM_CLASSNAME);

	// Model Index
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
	gl_iszModelIndex_CannonExp = engfunc(EngFunc_PrecacheModel, ENTITY_CANNON_SPRITE);

	gl_iszModelIndex_Summon = engfunc(EngFunc_PrecacheModel, ENTITY_SUMMONER_SPRITES[0]);
	gl_iszModelIndex_Unsummon = engfunc(EngFunc_PrecacheModel, ENTITY_SUMMONER_SPRITES[1]);
	gl_iszModelIndex_LaserExp = engfunc(EngFunc_PrecacheModel, ENTITY_SUMMONER_SPRITES[2]);
}

public plugin_natives()
{
	register_native("zp_get_user_dreadnova", "_get_user_dreadnova", 1);
	register_native("zp_give_user_dreadnova", "_give_user_dreadnova", 1);
	register_native("zp_delete_user_dreadnova", "_delete_user_dreadnova", 1);
}

/* ~ [ AMX Mod X ] ~ */
#if AMXX_VERSION_NUM < 183
	public client_disconnect(iPlayer) _delete_user_dreadnova(iPlayer);
#else
	public client_disconnected(iPlayer) _delete_user_dreadnova(iPlayer);
#endif

public Command__HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public _get_user_dreadnova(iPlayer) return get_bit(gl_iBitUserHasDreadNova, iPlayer);
public _give_user_dreadnova(iPlayer)
{
	set_bit(gl_iBitUserHasDreadNova, iPlayer);
	UTIL_WeaponList(iPlayer, WEAPON_WEAPONLIST, 15, 100, -1, -1, 2, 1, 29, 0);

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) == PDATA_SAFE)
	{
		set_pev(iItem, pev_iEnergy, 0);

		if(is_user_alive(iPlayer) && IsCustomItem(iItem))
			ExecuteHamB(Ham_Item_Deploy, iItem);
	}
}

public _delete_user_dreadnova(iPlayer)
{
	set_summoner_state(iPlayer, SUMMONER_DISAPPEAR);

	reset_bit(gl_iBitUserHasDreadNova, iPlayer);
	UTIL_WeaponList(iPlayer, WEAPON_REFERENCE, -1, -1, -1, -1, 2, 1, 29, 0);
}

public ze_user_humanized(iPlayer)
{
	if(IsUserHasDreadNova(iPlayer))
		UTIL_WeaponList(iPlayer, WEAPON_WEAPONLIST, 15, 100, -1, -1, 2, 1, 29, 0);
}

public ze_user_infected(iPlayer)
{
	#if REMOVE_KNIFE_IF_INFECTED == true

		if(IsUserHasDreadNova(iPlayer))
			reset_bit(gl_iBitUserHasSummoner, iPlayer);

	#endif

	UTIL_WeaponList(iPlayer, WEAPON_REFERENCE, -1, -1, -1, -1, 2, 1, 29, 0);
	set_summoner_state(iPlayer, SUMMONER_DISAPPEAR);
}

/* ~ [ Events ] ~ */
public EV_RoundStart()
{
	new iEntity = FM_NULLENT;
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", ENTITY_SUMMONER_CLASSNAME)))
	{
		if(pev_valid(iEntity))
			set_pev(iEntity, pev_flags, FL_KILLME);
	}

	for(new iPlayer = 1; iPlayer <= gl_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;
		if(!IsUserHasDreadNova(iPlayer)) continue;

		new iItem = get_pdata_cbase(iPlayer, m_rpgPlayerItems + 3, linux_diff_player);
		if(pev_valid(iItem) && iItem)
			set_pev(iItem, pev_iEnergy, 0);
	}
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer) || ze_is_user_zombie(iPlayer)) return;
	if(!IsUserHasDreadNova(iPlayer)) return;

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

/* ~ [ HamSandwich ] ~ */
public CKnife__Idle_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(iPlayer, DreadNovaInBMode(iItem) ? WEAPON_ANIM_IDLE_B : WEAPON_ANIM_IDLE_A);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return;

	set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW);
	set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[DreadNovaInBMode(iItem) ? 1 : 0]);

	UTIL_SendWeaponAnim(iPlayer, DreadNovaInBMode(iItem) ? WEAPON_ANIM_DRAW_B : WEAPON_ANIM_DRAW_A);

	set_pev(iItem, pev_flNextEnergy, get_gametime() + 0.1);
	UTIL_AmmoX(iPlayer, 15, pev(iItem, pev_iEnergy));
	UTIL_CurWeapon(iPlayer, 1, CSW_KNIFE, -1);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, WEAPON_ANIMATIONS[DreadNovaInBMode(iItem) ? 1 : 0], -1, linux_diff_player * linux_diff_animating);
	set_pdata_float(iItem, m_flTimeWeaponIdle, DreadNovaInBMode(iItem) ? WEAPON_ANIM_DRAW_B_TIME : WEAPON_ANIM_DRAW_A_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, DreadNovaInBMode(iItem) ? WEAPON_ANIM_DRAW_B_TIME : WEAPON_ANIM_DRAW_A_TIME, linux_diff_player);
}

public CKnife__Holster_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return;

	if(DreadNovaInBMode(iItem))
		set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B, linux_diff_weapon);
	else set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_A, linux_diff_weapon);

	set_summoner_state(iPlayer, SUMMONER_DISAPPEAR);

	set_pev(iItem, pev_flHoldTime, 0.0);
	set_pev(iItem, pev_flNextEnergy, 0.0);
	setComboData(iItem, 0);
	set_pdata_int(iItem, m_iSlashAnim, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CKnife__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return HAM_IGNORED;

	new iButton = pev(iPlayer, pev_button);
	new iWeaponState = get_pdata_int(iItem, m_iAttackState, linux_diff_weapon);
	new Float: flHoldTime; pev(iItem, pev_flHoldTime, flHoldTime);
	
	switch(iWeaponState)
	{
		case WPNSTATE_KNIFE_A_ATTACK: // Slash end
		{
			if(!(iButton & IN_ATTACK))
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SLASH_END);

				set_pdata_int(iItem, m_iSlashAnim, 0, linux_diff_weapon);
				set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_A, linux_diff_weapon);

				set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SLASH_END_TIME - 0.4, linux_diff_player);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SLASH_END_TIME - 0.4, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SLASH_END_TIME - 0.4, linux_diff_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SLASH_END_TIME, linux_diff_weapon);
			}
		}
		case WPNSTATE_KNIFE_B_ATTACK: // Hit
		{
			UTIL_FakeTraceLine(iPlayer, 7, WEAPON_STAB_DISTANCE, WEAPON_STAB_DAMAGE, WEAPON_STAB_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward);

			set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_HIT, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_STAB2_TIME - 9/30.0, linux_diff_player);
		}
		case WPNSTATE_KNIFE_B_HIT: // After hit
		{
			if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0) // Charging start
			{
				if(flHoldTime < WEAPON_ANIM_CHARGING_S_TIME)
				{
					if(pev(iPlayer, pev_weaponanim) != WEAPON_ANIM_CHARGING_START)
						UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHARGING_START);

					set_pev(iItem, pev_flHoldTime, flHoldTime + 0.1);
					set_pdata_float(iItem, m_flNextSecondaryAttack, 0.1, linux_diff_weapon);
					set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHARGING_S_TIME, linux_diff_weapon);
				}
				else set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_CHARGE, linux_diff_weapon); // Charging loop
			}

			if(!(iButton & IN_ATTACK2))
			{
				if(pev(iPlayer, pev_weaponanim) == WEAPON_ANIM_CHARGING_START) // If now in charge start and unhold attack2
				{
					set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_CHARGE, linux_diff_weapon);

					set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_STAB_END_TIME - flHoldTime, linux_diff_player);
					set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_STAB_END_TIME - flHoldTime, linux_diff_weapon);
					set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_STAB_END_TIME - flHoldTime, linux_diff_weapon);
					set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_STAB_END_TIME, linux_diff_weapon);

					return HAM_IGNORED;
				}

				// End stab
				CKnife__StabEnd(iPlayer, iItem);
			}
		}
		case WPNSTATE_KNIFE_B_CHARGE:
		{
			if(iButton & IN_ATTACK2) // Charging loop
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHARGING_LOOP);
				set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[2]);

				set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_CHARGE, linux_diff_weapon);

				set_pdata_float(iPlayer, m_flNextAttack, 0.1, linux_diff_player);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHARGING_L_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHARGING_L_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHARGING_L_TIME, linux_diff_weapon);
			}
			else // Charging release (shoot)
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHARGING_RELEASE);
				emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[1]);

				// Player animation
				static szAnimation[64];
				formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATIONS[1]);
				UTIL_PlayerAnimation(iPlayer, szAnimation);

				set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_CHARGE_HIT, linux_diff_weapon);

				set_pdata_float(iPlayer, m_flNextAttack, 11/30.0, linux_diff_player);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHARGING_R_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHARGING_R_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHARGING_R_TIME, linux_diff_weapon);
			}
		}
		case WPNSTATE_KNIFE_B_CHARGE_HIT:
		{
			Create_KnifeCannon(iPlayer);
			UTIL_FakeTraceLine(iPlayer, 7, WEAPON_STAB_DISTANCE, WEAPON_STAB_DAMAGE, WEAPON_STAB_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward);

			set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_CHARGE_END, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_CHARGING_R_TIME - 11/30.0, linux_diff_player);
		}
		case WPNSTATE_KNIFE_B_CHARGE_END: // Stab end
		{
			CKnife__StabEnd(iPlayer, iItem);
		}
	}

	return HAM_IGNORED;
}

public CKnife__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iAttackState, linux_diff_weapon) >= WPNSTATE_KNIFE_B_ATTACK) return HAM_SUPERCEDE;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return HAM_IGNORED;

	if(CKnife__CheckCombo(iPlayer, iItem, 0) == 1)
	{
		set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_A, linux_diff_weapon);
		return HAM_SUPERCEDE;
	}

	new Float: flNextAttack = WEAPON_NEXT_ATTACK;
	new iSlashAnim = get_pdata_int(iItem, m_iSlashAnim, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SLASH_1 + iSlashAnim);
	emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[iSlashAnim], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[0]);

	// Player animation
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATIONS[0]);
	UTIL_PlayerAnimation(iPlayer, szAnimation);

	if(iSlashAnim >= 2)
	{
		iSlashAnim = 0;
		flNextAttack = WEAPON_NEXT_ATTACK + 0.2;
	}
	else if(iSlashAnim == 1) iSlashAnim = random_num(2,3);
	else iSlashAnim++;

	if(iSlashAnim >= 2)
		UTIL_FakeTraceLine(iPlayer, 6, WEAPON_SLASH_DISTANCE, WEAPON_SLASH_DAMAGE, WEAPON_SLASH_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward);
	else UTIL_FakeTraceLine(iPlayer, 6, WEAPON_SLASH_DISTANCE, WEAPON_SLASH_DAMAGE_EX, WEAPON_SLASH_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward);

	set_summoner_state(iPlayer, SUMMONER_SLASH);
	set_pdata_int(iItem, m_iSlashAnim, iSlashAnim, linux_diff_weapon);
	set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_A_ATTACK, linux_diff_weapon);

	set_pdata_float(iPlayer, m_flNextAttack, flNextAttack, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flNextAttack, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flNextAttack, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SLASH_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iAttackState, linux_diff_weapon) >= WPNSTATE_KNIFE_B_ATTACK) return HAM_SUPERCEDE;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDreadNova(iPlayer) || ze_is_user_zombie(iPlayer)) return HAM_IGNORED;

	if(CKnife__CheckCombo(iPlayer, iItem, 1) == 1)
	{
		set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_A, linux_diff_weapon);
		return HAM_SUPERCEDE;
	}

	new Float: flNextAttack = DreadNovaInBMode(iItem) ? WEAPON_ANIM_STAB2_TIME : WEAPON_ANIM_STAB1_TIME;

	UTIL_SendWeaponAnim(iPlayer, DreadNovaInBMode(iItem) ? WEAPON_ANIM_STAB2 : WEAPON_ANIM_STAB1);
	emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[1]);

	// Player animation
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATIONS[1]);
	UTIL_PlayerAnimation(iPlayer, szAnimation);

	set_summoner_state(iPlayer, SUMMONER_STAB);
	set_pev(iItem, pev_flHoldTime, 0.0);
	set_pdata_int(iItem, m_iSlashAnim, 0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, DreadNovaInBMode(iItem) ? 9/30.0 : 14/30.0, linux_diff_player);
	set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B_ATTACK, linux_diff_weapon);

	set_pdata_float(iItem, m_flNextPrimaryAttack, flNextAttack, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flNextAttack, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flNextAttack, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Touch_Post(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Cannon)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new Float: vecVelocity[3]; pev(iEntity, pev_vuser1, vecVelocity);
		Create_SphereDamage(iEntity, iOwner, vecVelocity, vecOrigin, ENTITY_CANNON_RADIUS, ENTITY_CANNON_DAMAGE, ENTITY_CANNON_DMGTYPE);

		emit_sound(iEntity, CHAN_ITEM, ENTITY_CANNON_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateExplosion(0, vecOrigin, 0.0, gl_iszModelIndex_CannonExp, 10, 32, 2|4|8);

		set_pev(iEntity, pev_solid, SOLID_NOT);
		set_pev(iEntity, pev_velocity, Float: {0.0, 0.0, 0.0});
		engfunc(EngFunc_SetModel, iEntity, "");
		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Swing) // Swing
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
		return HAM_IGNORED;
	}

	if(pev(iEntity, pev_classname) == gl_iszAllocString_ExplosionRing) // Explosion ring
	{
		switch(pev(iEntity, pev_iuser4))
		{
			case 0:
			{
				new Float: flGameTime = get_gametime();

				// Knockback all victims from owner of Summner
				new iVictim = FM_NULLENT;
				new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

				while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_RING_KNOCK_RADIUS)) > 0)
				{
					if(iVictim == iEntity || !is_user_alive(iVictim) || !ze_is_user_zombie(iVictim))
						continue;

					if(!is_wall_between_points(iEntity, iVictim))
						continue;

					UTIL_KnockBackFromCenter(iEntity, iVictim, ENTITY_RING_KNOCK_POWER);
				}

				set_pev(iEntity, pev_iuser4, 1);
				set_pev(iEntity, pev_nextthink, flGameTime + ((81/30.0) - (25/30.0)));
			}
			case 1:
			{
				set_pev(iEntity, pev_flags, FL_KILLME);
			}
		}
	}

	if(pev(iEntity, pev_classname) == gl_iszAllocString_Summoner) // Summoner
	{
		new iOwner = pev(iEntity, pev_owner);
		if(!is_user_connected(iOwner))
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new Float: flNextThink;
		new Float: flGameTime = get_gametime();
		new Float: vecEntOrigin[3]; pev(iEntity, pev_origin, vecEntOrigin);
		new Float: vecOrigin[3]; get_position_for_summoner(iOwner, vecOrigin, -25.0);

		switch(pev(iEntity, pev_iSumState))
		{
			case SUMMONER_SPAWN:
			{
				set_pev(iEntity, pev_iSumState, SUMMONER_IDLE);

				flNextThink = ENTITY_SUMMONER_NEXTTHINK;
			}
			case SUMMONER_IDLE:
			{
				new Float: flSpeed;
				new Float: flDistance = get_distance_f(vecOrigin, vecEntOrigin);
				new Float: vecVelocity[3], Float: vecAngles[3]; pev(iOwner, pev_angles, vecAngles);

				if(flDistance > 50.0)
				{
					if(flDistance > 75.0) flSpeed = flDistance * 3.0;
					else flSpeed = flDistance * 1.5;

					get_speed_vector(vecEntOrigin, vecOrigin, flSpeed, vecVelocity);
					set_pev(iEntity, pev_velocity, vecVelocity);
				}
				else
				{
					if(xs_vec_equal(vecOrigin, vecEntOrigin) || flDistance < 5.0)
						set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
					else
					{
						get_speed_vector(vecEntOrigin, vecOrigin, 100.0, vecVelocity);
						set_pev(iEntity, pev_velocity, vecVelocity);
					}
				}

				if(pev(iEntity, pev_sequence) != SUMMONER_ANIM_IDLE)
					set_entity_anim(iEntity, SUMMONER_ANIM_IDLE);

				set_pev(iEntity, pev_angles, vecAngles);
				flNextThink = ENTITY_SUMMONER_NEXTTHINK;
			}
			case SUMMONER_SLASH:
			{
				new iSumAnim = pev(iEntity, pev_iSumAnim);
				if(iSumAnim >= 3) iSumAnim = 0;
				else iSumAnim++;

				set_entity_anim(iEntity, SUMMONER_ANIM_SLASH + iSumAnim);
				emit_sound(iEntity, CHAN_ITEM, ENTITY_SUMMONER_SOUNDS[0 + iSumAnim], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				Create_SlashSwing(iOwner, iSumAnim);

				set_pev(iEntity, pev_iSumAnim, iSumAnim);
				set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
				set_pev(iEntity, pev_iSumState, SUMMONER_SLASH_HIT);

				flNextThink = 10/30.0;
			}
			case SUMMONER_SLASH_HIT:
			{
				UTIL_FakeTraceLine(iOwner, -1, SUMMONER_SLASH_DISTANCE, SUMMONER_SLASH_DAMAGE, SUMMONER_SLASH_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward);
				set_pev(iEntity, pev_iSumState, SUMMONER_SLASH_END);

				flNextThink = SUMMONER_ANIM_SLASH_TIME - 10/30.0;
			}
			case SUMMONER_STAB:
			{
				set_entity_anim(iEntity, SUMMONER_ANIM_STAB);
				emit_sound(iEntity, CHAN_ITEM, ENTITY_SUMMONER_SOUNDS[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
				set_pev(iEntity, pev_iSumState, SUMMONER_STAB_FIRE);

				flNextThink = 20/30.0;
			}
			case SUMMONER_STAB_FIRE:
			{
				new Float: vecEndPos[3]; fm_get_aim_origin(iOwner, vecEndPos);
				new Float: vecVelocity[3]; velocity_by_aim(iOwner, floatround(ENTITY_EXP_KNOCK_POWER), vecVelocity);

				emit_sound(iEntity, CHAN_ITEM, ENTITY_SUMMONER_SOUNDS[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				UTIL_CreateExplosion(0, vecEndPos, 0.0, gl_iszModelIndex_LaserExp, 10, 32, 2|4|8);
				UTIL_DrawAttachmentBeam(iEntity, ENTITY_BEAM_SPRITE, vecEndPos, (35/30.0) - (20/30.0));

				// Create explosion sound
				new iExpEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
				if(iExpEntity)
				{
					engfunc(EngFunc_SetOrigin, iExpEntity, vecEndPos);
					Create_SphereDamage(iExpEntity, iOwner, vecVelocity, vecEndPos, SUMMONER_STAB_EXP_RADIUS, ENTITY_STAB_EXP_DAMAGE, SUMMONER_STAB_EXP_DMGTYPE);

					emit_sound(iExpEntity, CHAN_ITEM, ENTITY_CANNON_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					set_pev(iExpEntity, pev_flags, FL_KILLME);
				}

				set_pev(iEntity, pev_iSumState, SUMMONER_STAB_END);

				flNextThink = SUMMONER_ANIM_STAB_TIME - 20/30.0;
			}
			case SUMMONER_SLASH_END, SUMMONER_STAB_END:
			{
				set_pev(iEntity, pev_iSumState, SUMMONER_IDLE);

				flNextThink = 0.1;
			}
			case SUMMONER_DISAPPEAR:
			{
				iEntity = FM_NULLENT;
				while((iEntity = fm_find_ent_by_owner(iEntity, ENTITY_SUMMONER_CLASSNAME, iOwner)) > 0)
				{
					UTIL_CreateExplosion(0, vecEntOrigin, 75.0, gl_iszModelIndex_Unsummon, 7, 32, 2|4|8);
					emit_sound(iEntity, CHAN_ITEM, ENTITY_SUMMONER_SOUNDS[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

					set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
					set_pev(iEntity, pev_flags, FL_KILLME);
				}

				return HAM_IGNORED;
			}
		}

		set_pev(iEntity, pev_nextthink, flGameTime + flNextThink);
	}

	return HAM_IGNORED;
}

public CBeam__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_impulse) == gl_iszAllocString_BeamKey)
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CPlayer__PreThink_Pre(iPlayer)
{
	if(!is_user_alive(iPlayer) || ze_is_user_zombie(iPlayer)) return HAM_IGNORED;
	if(!IsUserHasDreadNova(iPlayer)) return HAM_IGNORED;

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE) return HAM_IGNORED;
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	new Float: flGameTime = get_gametime();
	new Float: flNextEnergy; pev(iItem, pev_flNextEnergy, flNextEnergy);
	new iEnergy = pev(iItem, pev_iEnergy);

	if(IsUserHasSummoner(iPlayer))
	{
		if(flNextEnergy < flGameTime && flNextEnergy != 0.0 && iEnergy >= 0)
		{
			if(iEnergy <= 1)
			{
				set_summoner_state(iPlayer, SUMMONER_DISAPPEAR);
				set_pev(iItem, pev_flNextEnergy, flGameTime + 1.0);
			}

			iEnergy--;
			set_pev(iItem, pev_iEnergy, iEnergy);
			set_pev(iItem, pev_flNextEnergy, flGameTime + WEAPON_ENERGY_LEFT);

			UTIL_AmmoX(iPlayer, 15, iEnergy);
		}
	}
	else
	{
		if(flNextEnergy < flGameTime && flNextEnergy != 0.0 && iEnergy < WEAPON_MAX_ENERGY)
		{
			if(iEnergy == WEAPON_MAX_ENERGY - 1)
			{
				emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				UTIL_ScreenFade(iPlayer, (1<<10) * 2, (1<<10) * 2, 0x0000, 0, 0, 200, 70);
			}

			iEnergy++;
			set_pev(iItem, pev_iEnergy, iEnergy);
			set_pev(iItem, pev_flNextEnergy, flGameTime + WEAPON_ENERGY_DELAY);

			UTIL_AmmoX(iPlayer, 15, iEnergy);
		}
	}

	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
public CKnife__StabEnd(iPlayer, iItem)
{
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_STAB_END);

	set_pev(iItem, pev_flHoldTime, 0.0);
	set_pdata_int(iItem, m_iAttackState, WPNSTATE_KNIFE_B, linux_diff_weapon);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_STAB_END_TIME - 0.5, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_STAB_END_TIME - 0.5, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_STAB_END_TIME - 0.5, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_STAB_END_TIME, linux_diff_weapon);
}

public CKnife__CheckCombo(iPlayer, iItem, iValue)
{
	if(pev(iItem, pev_iEnergy) < WEAPON_MAX_ENERGY) return 0;
	if(IsUserHasSummoner(iPlayer)) return 0;

	new iComboData = getComboData(iItem);

	if(WEAPON_COMBO_DATA[iComboData] != iValue)
	{
		iComboData = 0;
	}
	else
	{
		iComboData++;

		if(iComboData >= sizeof WEAPON_COMBO_DATA)
		{
			setComboData(iItem, 0);
			set_bit(gl_iBitUserHasSummoner, iPlayer);

			Create_Summoner(iPlayer);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SUMMONING);

			set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SUMMONING_TIME, linux_diff_player);
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SUMMONING_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SUMMONING_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SUMMONING_TIME, linux_diff_weapon);

			return 1;
		}
	}

	setComboData(iItem, iComboData);
	return 0;
}

public Create_SphereDamage(iEntity, iAttacker, Float: vecVelocity[3], Float: vecOrigin[3], Float: flRadius, Float: flDamage, ibitsDamageBits)
{
	new iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
			continue;

		if(is_user_alive(iVictim))
		{
			if(iVictim == iAttacker || !ze_is_user_zombie(iVictim) || !is_wall_between_points(iEntity, iVictim))
				continue;
		}
		else if(pev(iVictim, pev_solid) == SOLID_BSP)
		{
			if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
				continue;
		}

		if(is_user_alive(iVictim))
			set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

		ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);

		if(is_user_alive(iVictim))
		{
			set_pev(iVictim, pev_velocity, vecVelocity);
			set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);
		}
	}
}

public Create_KnifeCannon(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0] + vecForward[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecForward[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecForward[2] * 20.0;

	vecVelocity[0] *= ENTITY_CANNON_SPEED;
	vecVelocity[1] *= ENTITY_CANNON_SPEED;
	vecVelocity[2] *= ENTITY_CANNON_SPEED;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_CANNON_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Cannon);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 150.0);

	velocity_by_aim(iPlayer, floatround(ENTITY_EXP_KNOCK_POWER), vecVelocity);
	set_pev(iEntity, pev_vuser1, vecVelocity);

	set_entity_anim(iEntity, 1);

	return iEntity;
}

public Create_Summoner(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; get_position_for_summoner(iPlayer, vecOrigin, -25.0);
	new Float: vecAngles[3]; pev(iPlayer, pev_angles, vecAngles);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_SUMMONER_MODEL);
	engfunc(EngFunc_SetSize, iEntity, Float: { -30.0, -30.0, -30.0 }, Float: { 30.0, 30.0, 30.0 });
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Summoner);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_iSumState, SUMMONER_SPAWN);
	set_pev(iEntity, pev_nextthink, flGameTime + SUMMONER_ANIM_SUMMON_TIME);
	set_pev(iEntity, pev_angles, vecAngles);

	set_entity_anim(iEntity, SUMMONER_ANIM_SUMMON);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 150.0);

	Create_ExplosionRing(iPlayer);
	UTIL_CreateExplosion(0, vecOrigin, 42.5, gl_iszModelIndex_Summon, 8, 32, 2|4|8);
	emit_sound(iEntity, CHAN_ITEM, ENTITY_SUMMONER_SOUNDS[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return iEntity;
}

public Create_SlashSwing(iPlayer, iSequence)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; get_position_for_summoner(iPlayer, vecOrigin, 0.0);
	new Float: vecAngles[3]; pev(iPlayer, pev_angles, vecAngles);

	vecOrigin[2] -= 5.0;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_SWING_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Swing)
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_nextthink, flGameTime + 25/30.0);
	set_pev(iEntity, pev_angles, vecAngles);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 255.0);

	set_entity_anim(iEntity, iSequence);

	return iEntity;
}

public Create_ExplosionRing(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; get_position_for_summoner(iPlayer, vecOrigin, -25.0);

	vecOrigin[2] -= 25.0;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_RING_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_ExplosionRing)
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_iuser4, 0);
	set_pev(iEntity, pev_nextthink, flGameTime + 24/30.0);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 255.0);

	set_entity_anim(iEntity, 0);

	return iEntity;
}

/* ~ [ Stock's ] ~ */
stock set_summoner_state(iPlayer, iSummonerState)
{
	if(!IsUserHasSummoner(iPlayer)) return;
	
	static iEntity; iEntity = fm_find_ent_by_owner(-1, ENTITY_SUMMONER_CLASSNAME, iPlayer);
	if(pev_valid(iEntity))
	{
		if(iSummonerState == SUMMONER_DISAPPEAR)
		{
			reset_bit(gl_iBitUserHasSummoner, iPlayer);

			set_pev(iEntity, pev_iSumState, iSummonerState);
			set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);

			iEntity = fm_find_ent_by_owner(-1, ENTITY_RING_CLASSNAME, iPlayer);
			if(pev_valid(iEntity))
				set_pev(iEntity, pev_flags, FL_KILLME);

			return;
		}

		switch(pev(iEntity, pev_iSumState))
		{
			case SUMMONER_SPAWN, SUMMONER_SLASH_HIT, SUMMONER_STAB_FIRE, SUMMONER_SLASH_END, SUMMONER_STAB_END: return;
			default:
			{
				if(iSummonerState == SUMMONER_SLASH || iSummonerState == SUMMONER_STAB)
				{
					new Float: vecEntOrigin[3]; pev(iEntity, pev_origin, vecEntOrigin);
					new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);

					if(get_distance_f(vecOrigin, vecEntOrigin) > 50.0)
					{
						new Float: vecOrigin[3]; get_position_for_summoner(iPlayer, vecOrigin, -25.0);

						engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
					}
				}

				set_pev(iEntity, pev_iSumState, iSummonerState);
			}
		}
	}
}

stock set_entity_anim(iEntity, iSequence)
{
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_sequence, iSequence);
}

stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: vecEnd[3], Float: vecEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, vecEnd);

	engfunc(EngFunc_TraceLine, flStart, vecEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(vecEnd, vecEndPos);
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PlayerAnimation(iPlayer, szAnim[])
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		
	if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;
	
	new Float: flGameTime = get_gametime();

	set_entity_anim(iPlayer, iAnimDesired);
	
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGameTime , linux_diff_animating);
	
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(iPlayer, m_flLastAttackTime, flGameTime , linux_diff_player);
}

stock UTIL_DrawAttachmentBeam(iEntity, const szSpriteName[], Float: vecStart[3], Float: flNextThink)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100) return FM_NULLENT;
	
	static iBeam; iBeam = Beam_Create(szSpriteName, ENTITY_BEAM_WIDTH);
	if(pev_valid(iBeam) != PDATA_SAFE) return FM_NULLENT;
	
	Beam_PointEntInit(iBeam, vecStart, iEntity);
	Beam_SetBrightness(iBeam, ENTITY_BEAM_BRIGHTNESS);
	Beam_SetColor(iBeam, Float: ENTITY_BEAM_COLOR);
	Beam_SetFlags(iBeam, BEAM_FSINE);
	Beam_SetScrollRate(iBeam, ENTITY_BEAM_SCROLLRATE);
	Beam_SetEndAttachment(iBeam, 1);

	set_pev(iBeam, pev_classname, ENTITY_BEAM_CLASSNAME);
	set_pev(iBeam, pev_impulse, gl_iszAllocString_BeamKey);
	set_pev(iBeam, pev_owner, iEntity);
	set_pev(iBeam, pev_nextthink, get_gametime() + flNextThink);
	
	return iBeam;
}

stock UTIL_CreateExplosion(iEntity, Float: vecOrigin[3], Float: vecUp, iszModelIndex, iScale, iFrameRate, iFlags)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION
	if(!iEntity)
		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	else message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, iEntity);

	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + vecUp); // Position Z
	write_short(iszModelIndex); // Model Index
	write_byte(iScale); // Scale
	write_byte(iFrameRate); // Framerate
	write_byte(iFlags); // Flags
	message_end();
}

stock UTIL_FakeTraceLine(iPlayer, iHitSound, Float: flDistance, Float: flDamage, Float: flKnockBack, Float: flSendAngles[], iSendAngles)
{
	enum
	{
		SLASH_HIT_NONE = 0,
		SLASH_HIT_WORLD,
		SLASH_HIT_ENTITY
	};

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0];
	vecOrigin[1] += vecViewOfs[1];
	vecOrigin[2] += vecViewOfs[2];
	
	new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];
	engfunc(EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp);
		
	new iTrace = create_tr2();

	new Float: flTan, Float: flMul;
	new iHitList[10], iHitCount = 0;

	new Float: vecEnd[3];
	new Float: flFraction;
	new pHit, pHitEntity = SLASH_HIT_NONE;
	new iHitResult = SLASH_HIT_NONE;

	for(new i; i < iSendAngles; i++)
	{
		flTan = floattan(flSendAngles[i], degrees);

		vecEnd[0] = (vecForward[0] * flDistance) + (vecRight[0] * flTan * flDistance) + vecUp[0];
		vecEnd[1] = (vecForward[1] * flDistance) + (vecRight[1] * flTan * flDistance) + vecUp[1];
		vecEnd[2] = (vecForward[2] * flDistance) + (vecRight[2] * flTan * flDistance) + vecUp[2];
			
		flMul = (flDistance/vector_length(vecEnd));
		xs_vec_mul_scalar(vecEnd, flMul, vecEnd);
		xs_vec_add(vecEnd, vecOrigin, vecEnd);

		engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, vecOrigin, vecEnd, HULL_HEAD, iPlayer, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);
		
			engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
			pHit = get_tr2(iTrace, TR_pHit);
		}
		else
		{
			pHit = get_tr2(iTrace, TR_pHit);
		}

		if(pHit == iPlayer) continue;

		static bool: bStop; bStop = false;
		for(new iHit = 0; iHit < iHitCount; iHit++)
		{
			if(iHitList[iHit] == pHit)
			{
				bStop = true;
				break;
			}
		}

		if(bStop == true)
			continue;

		iHitList[iHitCount] = pHit;
		iHitCount++;

		if(flFraction != 1.0)
		{
			if(!iHitResult) iHitResult = SLASH_HIT_WORLD;
		}

		if(pHit > 0 && pHitEntity != pHit)
		{
			if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			{
				ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, flDamage, DMG_NEVERGIB | DMG_CLUB);
			}
			else
			{
				UTIL_FakeTraceAttack(pHit, iPlayer, iHitSound == -1 ? 1 : 0, flDamage, vecForward, iTrace, DMG_NEVERGIB | DMG_CLUB);
				UTIL_FakeKnockBack(pHit, vecForward, flKnockBack);
			}

			iHitResult = SLASH_HIT_ENTITY;
			pHitEntity = pHit;
		}
	}

	free_tr2(iTrace);

	if(iHitSound != -1)
	{
		switch(iHitResult)
		{
			case SLASH_HIT_WORLD: emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[8], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			case SLASH_HIT_ENTITY: emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iHitSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

stock UTIL_FakeTraceAttack(iVictim, iAttacker, iSummoner, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
	static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

	if(flTakeDamage == DAMAGE_NO) return 0; 
	if(!(is_user_alive(iVictim))) return 0;

	if(is_user_connected(iVictim)) 
	{
		if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
			return 0;
	}

	static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	if(iSummoner == 1)
		set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
	else
	{
		set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player);

		switch(iHitgroup) 
		{
			case HIT_HEAD:                  flDamage *= 3.0;
			case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
			case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
			case HIT_STOMACH:               flDamage *= 1.5;
		}
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);
	
	if(ze_is_user_zombie(iVictim)) 
	{
		if(iBloodColor != DONT_BLEED) 
		{
			ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, iTrace, ibitsDamageBits);
			UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
		}
	}

	return 1;
}

stock UTIL_FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim) && ze_is_user_zombie(iVictim))) return 0;

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float: vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);

	if(pev(iVictim, pev_flags) & FL_DUCKING) 
		flKnockBack *= 0.7;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	//vecVelocity[2] = 200.0;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

stock UTIL_KnockBackFromCenter(iAttacker, iVictim, Float: flPower)
{
	new Float: vecOrigin[3], Float: vecVictimOrigin[3], Float: vecVelocity[3];

	pev(iAttacker, pev_origin, vecOrigin);
	pev(iVictim, pev_origin, vecVictimOrigin);
	vecOrigin[2] = vecVictimOrigin[2] = 0.0;
	
	xs_vec_sub(vecVictimOrigin, vecOrigin, vecVictimOrigin);
	new Float: fDistance; fDistance = xs_vec_len(vecVictimOrigin);
	xs_vec_mul_scalar(vecVictimOrigin, 1 / fDistance, vecVictimOrigin);
	
	pev(iVictim, pev_velocity, vecVelocity);
	xs_vec_mul_scalar(vecVictimOrigin, flPower, vecVictimOrigin);
	xs_vec_mul_scalar(vecVictimOrigin, 50.0, vecVictimOrigin);
	vecVictimOrigin[2] = xs_vec_len(vecVictimOrigin) * 0.15;
	
	if(pev(iAttacker, pev_flags) &~ FL_ONGROUND)
		xs_vec_mul_scalar(vecVictimOrigin, 1.2, vecVictimOrigin), vecVictimOrigin[2] *= 0.4;

	if(xs_vec_len(vecVictimOrigin) > xs_vec_len(vecVelocity))
		set_pev(iVictim, pev_velocity, vecVictimOrigin);

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);
}

public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

stock UTIL_AmmoX(iPlayer, iPrimaryAmmoID, iPrimaryAmmoAmount)
{
	message_begin(MSG_ONE, gl_iMsgID_AmmoX, _, iPlayer);
	write_byte(iPrimaryAmmoID);
	write_byte(iPrimaryAmmoAmount);
	message_end();
}

stock UTIL_CurWeapon(iPlayer, iActive, CSW_WEAPON, iClip)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, gl_iMsgID_CurWeapon, {0, 0, 0}, iPlayer);
	write_byte(iActive);
	write_byte(CSW_WEAPON);
	write_byte(iClip);
	message_end();
}

stock UTIL_WeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
	message_begin(MSG_ONE, gl_iMsgID_WeaponList, _, iPlayer);
	write_string(szWeaponName);
	write_byte(iPrimaryAmmoID);
	write_byte(iAmmoMaxAmount);
	write_byte(iSecondaryAmmoID);
	write_byte(iSecondaryAmmoMaxAmount);
	write_byte(iSlotID);
	write_byte(iNumberInSlot);
	write_byte(iWeaponID);
	write_byte(iFlags);
	message_end();
}

stock UTIL_ScreenFade(iPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if(!iPlayer)
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, gl_iMsgID_ScreenFade);
	else message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, gl_iMsgID_ScreenFade, _, iPlayer);

	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}

stock UTIL_PrecacheSpritesFromTxt(const szWeaponList[])
{
	new szTxtDir[64], szSprDir[64]; 
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if(!strlen(szFileData)) 
			continue;

		new pos = containi(szFileData, "640");	
			
		if(pos == -1)
			continue;
			
		format(szFileData, charsmax(szFileData), "%s", szFileData[pos+3]);		
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);
		
		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}

	if(iFile) fclose(iFile);
}

stock get_speed_vector(const Float: vecOrigin1[3], const Float: vecOrigin2[3], Float: flSpeed, Float: vecVelocity[3]) 
{
	vecVelocity[0] = vecOrigin2[0] - vecOrigin1[0]; 
	vecVelocity[1] = vecOrigin2[1] - vecOrigin1[1]; 
	vecVelocity[2] = vecOrigin2[2] - vecOrigin1[2]; 

	new Float: flNum = floatsqroot(flSpeed * flSpeed / (vecVelocity[0]*vecVelocity[0] + vecVelocity[1]*vecVelocity[1] + vecVelocity[2]*vecVelocity[2])) 

	vecVelocity[0] *= flNum; 
	vecVelocity[1] *= flNum; 
	vecVelocity[2] *= flNum; 

	return 1; 
}

stock get_position_for_summoner(iPlayer, Float: vecOrigin[3], Float: flForward)
{
	new Float: vecViewOfs[3], Float: vecAngles[3], Float: vecForward[3];

	pev(iPlayer, pev_origin, vecOrigin);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
	pev(iPlayer, pev_angles, vecAngles);
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

	vecOrigin[0] += vecViewOfs[0] + vecForward[0] * flForward;
	vecOrigin[1] += vecViewOfs[1] + vecForward[1] * flForward;
	vecOrigin[2] += ENTITY_SUMMONER_RAISED;

	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
