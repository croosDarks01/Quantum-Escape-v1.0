/*
*	Name: SF Tornado Laser
*	Version: 1.0
*	Author: Batcon/t3rkecorejz
*	I edited plugin for Zombie Escape mod, So players can use this Extra Item.
*	You can change the item's cost if you want :)
*/

#include <ze_core>
#include <ze_items_manager>
#include < fakemeta_util >
#include <hamsandwich>

#define PLUGIN "[ZE] Items: SF Tornado Laser"
#define VERSION "1.0"
#define AUTHOR "Batcon/t3rkecorejz"

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_iWeaponState 74
#define m_flNextReload 75

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

#define ANIM_IDLE 2
#define ANIM_ATTACK 5
#define ANIM_ATTACK_END 11
#define ANIM_ATTACK_EMPTY 8
#define ANIM_RELOAD 14
#define ANIM_DRAW 19

#define ANIM_IDLE_TIME 6.04
#define ANIM_RELOAD_TIME 3.54
#define ANIM_DRAW_TIME 1.37

#define WEAPON_KEY 40
#define WEAPON_OLD "weapon_aug"
#define WEAPON_NEW "zombie_escape/weapon_sflaser"
#define WEAPON_LASER "sprites/zombie_escape/laser.spr"


#define WEAPON_MODEL_V "models/zombie_escape/v_sflaser.mdl"
#define WEAPON_MODEL_P "models/zombie_escape/p_sflaser.mdl"
#define WEAPON_MODEL_W "models/zombie_escape/w_sflaser.mdl"
#define WEAPON_SOUND_S "weapons/sflaser-3.wav"
#define WEAPON_SOUND_E "weapons/sflaser-shoot_end.wav"
#define WEAPON_BODY 0

#define WEAPON_CLIP 70
#define WEAPON_AMMO 210
#define WEAPON_RATE 0.09
#define WEAPON_RECOIL 0.3
#define WEAPON_DAMAGE 1.1

new g_AllocString_V, g_AllocString_P, g_AllocString_E
new HamHook:g_fw_TraceAttack[4]
new g_iMsgID_Weaponlist
new iSpriteIndexTrail
new g_iItemID
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Item_Deploy, WEAPON_OLD, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_Holster, WEAPON_OLD, "fw_Item_Holster_Post", 1);
	RegisterHam(Ham_Item_PostFrame, WEAPON_OLD, "fw_Item_PostFrame");
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_OLD, "fw_Item_AddToPlayer_Post", 1);
	
	RegisterHam(Ham_Weapon_Reload, WEAPON_OLD, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_OLD, "fw_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_OLD, "fw_Weapon_PrimaryAttack");
	
	g_fw_TraceAttack[0] = RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack");
	g_fw_TraceAttack[1] = RegisterHam(Ham_TraceAttack, "info_target",    "fw_TraceAttack");
	g_fw_TraceAttack[2] = RegisterHam(Ham_TraceAttack, "player",         "fw_TraceAttack");
	g_fw_TraceAttack[3] = RegisterHam(Ham_TraceAttack, "hostage_entity", "fw_TraceAttack");
	fm_ham_hook(false);
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_SetModel, "fw_SetModel");
	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	register_clcmd(WEAPON_NEW, "HookSelect");
	g_iItemID = ze_register_item("SF Tornado Laser", 400, 0);
}
public plugin_precache() {
	g_AllocString_V = engfunc(EngFunc_AllocString, WEAPON_MODEL_V);
	g_AllocString_P = engfunc(EngFunc_AllocString, WEAPON_MODEL_P);
	g_AllocString_E = engfunc(EngFunc_AllocString, WEAPON_OLD);
	iSpriteIndexTrail = engfunc(EngFunc_PrecacheModel, WEAPON_LASER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_V);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_P);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_W);

	new const WPN_SOUND[][] = {
		"weapons/sflaser_clipin.wav",
		"weapons/sflaser_clipout.wav",
		"weapons/sflaser_drawc.wav"
	}
	for(new i = 0; i < sizeof WPN_SOUND;i++) engfunc(EngFunc_PrecacheSound, WPN_SOUND[i]);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_E);
}
public plugin_natives() {
	register_native("give_weapon_sflaser", "give_weapon", 1);
}
public ze_select_item_pre(id, itemid) {
	// Return Available and we will block it in Post, So it dosen't affect other plugins
	if (itemid != g_iItemID)
		return ZE_ITEM_AVAILABLE
	
	// Available for Humans only, So don't show it for zombies
	if (ze_is_user_zombie(id))
		return ZE_ITEM_DONT_SHOW
	
	return ZE_ITEM_AVAILABLE
}
public ze_select_item_post(iPlayer, itemid) {
	// This is not our item, Block it here
	if (itemid != g_iItemID)
		return
	
	give_weapon(iPlayer)
}
public HookSelect(iPlayer) {
	engclient_cmd(iPlayer, WEAPON_OLD);
	return PLUGIN_HANDLED;
}
public give_weapon(iPlayer) {
	static iEnt; iEnt = engfunc(EngFunc_CreateNamedEntity, g_AllocString_E);
	if(iEnt <= 0) return 0;
	set_pev(iEnt, pev_spawnflags, SF_NORESPAWN);
	set_pev(iEnt, pev_impulse, WEAPON_KEY);
	ExecuteHam(Ham_Spawn, iEnt);
	UTIL_DropWeapon(iPlayer, 1);
	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEnt)) {
		engfunc(EngFunc_RemoveEntity, iEnt);
		return 0;
	}
	ExecuteHamB(Ham_Item_AttachToPlayer, iEnt, iPlayer);
	set_pdata_int(iEnt, m_iClip, WEAPON_CLIP, 4);
	new iAmmoType = m_rgAmmo +get_pdata_int(iEnt, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, m_rgAmmo, 5) < WEAPON_AMMO)
	set_pdata_int(iPlayer, iAmmoType, WEAPON_AMMO, 5);
	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}
public fw_Item_Deploy_Post(iItem) {
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	set_pev_string(iPlayer, pev_viewmodel2, g_AllocString_V);
	set_pev_string(iPlayer, pev_weaponmodel2, g_AllocString_P);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, "m249", -1, 20);
	UTIL_SendWeaponAnim(iPlayer, ANIM_DRAW);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_DRAW_TIME, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_DRAW_TIME, 4);
	set_pdata_float(iItem, m_flNextReload, 0.0, 4);
	set_pdata_int(iItem, m_iWeaponState, 0, 4);
}
public fw_Item_Holster_Post(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	new iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	emit_sound(iPlayer, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	return HAM_IGNORED;
}
public fw_Item_PostFrame(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(get_pdata_int(iItem, m_fInReload, 4) == 1) {
		static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, 5);
		static j; j = min(WEAPON_CLIP - iClip, iAmmo);
		set_pdata_int(iItem, m_iClip, iClip+j, 4);
		set_pdata_int(iPlayer, iAmmoType, iAmmo-j, 5);
		set_pdata_int(iItem, m_fInReload, 0, 4);
	}
	if(!(pev(iPlayer, pev_oldbuttons) & IN_ATTACK)) {
		if(get_pdata_int(iItem, m_iWeaponState, 4) == 1) {
			set_pdata_int(iItem, m_iWeaponState, 0, 4);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_E, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			UTIL_SendWeaponAnim(iPlayer, ANIM_ATTACK_END);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.7, 4);
			set_pdata_float(iItem, m_flNextReload, 0.0, 4);
			set_pdata_float(iPlayer, m_flNextAttack, 0.7, 5);
		}
	}
	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(iItem, iPlayer) {
	switch(pev(iItem, pev_impulse)) {
		case WEAPON_KEY: s_weaponlist(iPlayer, true);
		case 0: s_weaponlist(iPlayer, false);
	}
}
public fw_Weapon_Reload(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	if(iClip >= WEAPON_CLIP) return HAM_SUPERCEDE;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, iAmmoType, 5) <= 0) return HAM_SUPERCEDE

	set_pdata_int(iItem, m_iClip, 0, 4);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, 4);
	set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_RELOAD_TIME, 5);

	UTIL_SendWeaponAnim(iPlayer, ANIM_RELOAD);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	UTIL_SendWeaponAnim(get_pdata_cbase(iItem, m_pPlayer, 4), ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, 4);
	return HAM_SUPERCEDE;
}
public fw_Weapon_PrimaryAttack(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(get_pdata_int(iItem, m_iClip, 4) == 0) {
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, 4);
		if(pev(iPlayer, pev_weaponanim) != ANIM_ATTACK_EMPTY) {
			UTIL_SendWeaponAnim(iPlayer, ANIM_ATTACK_EMPTY);
		}
		return HAM_SUPERCEDE;
	}
	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", 1);
	fm_ham_hook(true);
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	state FireBullets: Disabled;
	unregister_forward(FM_TraceLine, fw_TraceLine, 1);
	fm_ham_hook(false);
	static Float:vecPunchangle[3];
	static Float:vecOrigin[3]; fm_get_aim_origin(iPlayer, vecOrigin);

	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_RECOIL;
	vecPunchangle[1] *= WEAPON_RECOIL;
	vecPunchangle[2] *= WEAPON_RECOIL;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	if(get_pdata_float(iItem, m_flNextReload, 4) <= get_gametime()) {
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_float(iItem, m_flNextReload, get_gametime() + 10.0, 4);
	}
	if(pev(iPlayer, pev_weaponanim) != ANIM_ATTACK) {
		UTIL_SendWeaponAnim(iPlayer, ANIM_ATTACK);
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iPlayer | 0x1000);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(iSpriteIndexTrail);
	write_byte(0); // framestart
	write_byte(1); // framerate
	write_byte(2); // life
	write_byte(10); // width
	write_byte(3); // noise
	write_byte(0); // red
	write_byte(128); // green
	write_byte(255); // blue
	write_byte(200); // brightness
	write_byte(10); // speed
	message_end();

	set_pdata_int(iItem, m_iWeaponState, 1, 4);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.5, 4);

	return HAM_SUPERCEDE;
}
public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <> { return FMRES_IGNORED; }
public fw_TraceAttack(iVictim, iAttacker, Float:flDamage) {
	if(!is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
        SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}
public fw_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle) {
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
	set_cd(CD_Handle, CD_flNextAttack, 999999.0);
}
public fw_SetModel(iEnt) {
	static i, szClassname[32], iItem; 
	pev(iEnt, pev_classname, szClassname, 31);
	if(!equal(szClassname, "weaponbox")) return FMRES_IGNORED;
	for(i = 0; i < 6; i++) {
		iItem = get_pdata_cbase(iEnt, m_rgpPlayerItems_CWeaponBox + i, 4);
		if(iItem > 0 && CustomItem(iItem)) {
			engfunc(EngFunc_SetModel, iEnt, WEAPON_MODEL_W);
			set_pev(iEnt, pev_body, WEAPON_BODY);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public fw_TraceLine_Post(const Float:flOrigin1[3], const Float:flOrigin2[3], iFrag, iIgnore, tr) {
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;
	static pHit; pHit = get_tr2(tr, TR_pHit);
	if(pHit > 0) {
		if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;
	}
	return FMRES_IGNORED;
}
public fm_ham_hook(bool:on) {
	if(on) {
		EnableHamForward(g_fw_TraceAttack[0]);
		EnableHamForward(g_fw_TraceAttack[1]);
		EnableHamForward(g_fw_TraceAttack[2]);
		EnableHamForward(g_fw_TraceAttack[3]);
	}
	else {
		DisableHamForward(g_fw_TraceAttack[0]);
		DisableHamForward(g_fw_TraceAttack[1]);
		DisableHamForward(g_fw_TraceAttack[2]);
		DisableHamForward(g_fw_TraceAttack[3]);
	}
}
stock UTIL_SendWeaponAnim(iPlayer, iSequence) {
	set_pev(iPlayer, pev_weaponanim, iSequence);
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iSequence);
	write_byte(0);
	message_end();
}
stock UTIL_DropWeapon(iPlayer, iSlot) {
	static iEntity, iNext, szWeaponName[32]; 
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, 5);
	if(iEntity > 0) {       
                do{
                        iNext = get_pdata_cbase(iEntity, m_pNext, 4)
                        if(get_weaponname(get_pdata_int(iEntity, m_iId, 4), szWeaponName, 31)) {  
                                engclient_cmd(iPlayer, "drop", szWeaponName);
			}
                } while(( iEntity = iNext) > 0);
	}
}
//  4,  90, -1, -1, 0, 14,8,  0, // weapon_aug
stock s_weaponlist(iPlayer, bool:on) {
	message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
	write_string(on ? WEAPON_NEW : WEAPON_OLD);
	write_byte(4);
	write_byte(on ? WEAPON_AMMO : 90);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(14);
	write_byte(8);
	write_byte(0);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
