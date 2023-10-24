#include <amxmodx>
#include <engine>
#include <reapi>
#include <ze_core>

// Macro.
#define is_user_nemesis(%0) flag_get_boolean(g_bitsIsNemesis, %0)

// Colors indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// CVars.
new g_iHealth,
	g_iGravity,
	g_iGlowAmount,
	g_iGlowColors[Colors],
	bool:g_bOneHit,
	bool:g_bBlockFrost,
	bool:g_bBlockFire,
	bool:g_bDieExplode,
	bool:g_bGlowEnabled,
	Float:g_flMaxSpeed,
	Float:g_flKnockback,
	Float:g_flMultipleDamage

// Variables.
new g_bitsIsNemesis

// Dynamic Arrays.
new Array:g_aNemesisModel,
	Array:g_aNemesisClaws

public plugin_natives()
{
	register_native("ze_is_user_nemesis", "__native_is_user_nemesis")
	register_native("ze_set_user_nemesis", "__native_set_user_nemesis")
	register_native("ze_reset_user_nemesis", "__native_reset_user_nemesis")
}

public plugin_precache()
{
	// Default Nemesis Models.
	new const szNemesisModel[][] = {"nemesis"}
	new const szNemesisClaws[][] = {"models/v_knife_nemesis.mdl"}

	// Create new dyn Array.
	g_aNemesisModel = ArrayCreate(MAX_NAME_LENGTH, 1)
	g_aNemesisClaws = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Nemesis Models from INI file.
	ini_read_string_array(ZE_FILENAME, "Player Models", "NEMESIS", g_aNemesisModel)
	ini_read_string_array(ZE_FILENAME, "Weapon Models", "NEMESIS_KNIFE", g_aNemesisClaws)

	if (!ArraySize(g_aNemesisModel))
	{
		for (new i = 0; i < sizeof(szNemesisModel); i++)
			ArrayPushString(g_aNemesisModel, szNemesisModel[i])

		// Write Nemesis Models on INI file.
		ini_write_string_array(ZE_FILENAME, "Player Models", "NEMESIS", g_aNemesisModel)
	}

	if (!ArraySize(g_aNemesisClaws))
	{
		for (new i = 0; i < sizeof(szNemesisClaws); i++)
			ArrayPushString(g_aNemesisClaws, szNemesisClaws[i])

		// Write Nemesis Claws on INI file.
		ini_write_string_array(ZE_FILENAME, "Weapon Models", "NEMESIS_KNIFE", g_aNemesisClaws)
	}

	new szPlayerModel[MAX_NAME_LENGTH], szModel[MAX_RESOURCE_PATH_LENGTH], iFiles

	// Precache Models.
	iFiles = ArraySize(g_aNemesisModel)
	for (new i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aNemesisModel, i, szPlayerModel, charsmax(szPlayerModel))
		format(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModel)
	}

	iFiles = ArraySize(g_aNemesisClaws)
	for (new i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aNemesisClaws, i, szModel, charsmax(szModel))
		precache_model(szModel)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Nemesis", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_CBasePlayer_Killed, "fw_PlayerKilled_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Pre", 0)

	// CVars.
	bind_pcvar_num(register_cvar("ze_nemesis_health", "2000"), g_iHealth)
	bind_pcvar_num(register_cvar("ze_nemesis_gravity", "500"), g_iGravity)
	bind_pcvar_float(register_cvar("ze_nemesis_maxspeed", "320.0"), g_flMaxSpeed)

	bind_pcvar_num(register_cvar("ze_nemesis_glow", "1"), g_bGlowEnabled)
	bind_pcvar_num(register_cvar("ze_nemesis_glow_red", "200"), g_iGlowColors[Red])
	bind_pcvar_num(register_cvar("ze_nemesis_glow_green", "0"), g_iGlowColors[Green])
	bind_pcvar_num(register_cvar("ze_nemesis_glow_blue", "0"), g_iGlowColors[Blue])
	bind_pcvar_num(register_cvar("ze_nemesis_glow_amount", "16"), g_iGlowAmount)

	bind_pcvar_num(register_cvar("ze_nemesis_explode", "1"), g_bDieExplode)
	bind_pcvar_num(register_cvar("ze_nemesis_onehit", "0"), g_bOneHit)
	bind_pcvar_float(register_cvar("ze_nemesis_damage", "2.0"), g_flMultipleDamage)

	bind_pcvar_num(register_cvar("ze_nemesis_frost", "0"), g_bBlockFrost)
	bind_pcvar_num(register_cvar("ze_nemesis_fire", "0"), g_bBlockFire)

	bind_pcvar_float(register_cvar("ze_nemesis_knockback", "200.0"), g_flKnockback)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	// Remove player Nemesis Flag.
	flag_unset(g_bitsIsNemesis, id)
}

public ze_user_humanized(id)
{
	// Is Nemesis?
	if (is_user_nemesis(id))
	{
		unset_User_Nemesis(id)
	}
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	if (!iInfector)
		return ZE_CONTINUE

	// Is not Nemesis?
	if (is_user_nemesis(iInfector))
		return ZE_STOP // Block infection event, Keep damage taken.

	return ZE_CONTINUE
}

public fw_PlayerKilled_Pre(const iVictim, iAttacker, iGibs)
{
	// Is Alive?
	if (is_user_alive(iVictim) || !is_user_nemesis(iVictim))
		return HC_CONTINUE

	if (g_bDieExplode)
	{
		SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS)
	}

	return HC_CONTINUE
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	// Is Nemesis?
	if (is_user_nemesis(iVictim))
	{
		flag_unset(g_bitsIsNemesis, iVictim)
	}
}

public fw_TakeDamage_Pre(const iVictim, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	// Victim not on game or damage himself?
	if (iVictim == iAttacker || !is_user_connected(iVictim))
		return HC_CONTINUE

	// Teammates?
	if (is_user_nemesis(iVictim) == is_user_nemesis(iAttacker))
		return HC_CONTINUE

	if (is_user_nemesis(iAttacker))
	{
		if (bitsDamageType & DMG_BULLET)
		{
			if (g_flMultipleDamage > 0.0)
			{
				// Multiple Damage.
				SetHookChainArg(4, ATYPE_FLOAT, flDamage * g_flMultipleDamage)
			}
		}
	}

	return HC_CONTINUE
}

public ze_frost_freeze_start(id)
{
	if (is_user_nemesis(id) && g_bBlockFrost)
		return ZE_STOP
	return ZE_CONTINUE
}

public ze_fire_burn_start(id)
{
	if (is_user_nemesis(id) && g_bBlockFire)
		return ZE_STOP
	return ZE_CONTINUE
}

/**
 * -=| Functions |=-
 */
set_User_Nemesis(const id)
{
	// Is not Zombie?
	if (!ze_is_user_zombie(id))
		ze_set_user_zombie(id)

	// Is not Nemesis?
	if (!is_user_nemesis(id))
		flag_set(g_bitsIsNemesis, id)

	if (g_iHealth > 0)
	{
		new Float:fHealth = float(g_iHealth)
		set_entvar(id, var_health, fHealth)
		set_entvar(id, var_max_health, fHealth)
	}

	if (g_flMaxSpeed > 0.0)
	{
		ze_set_user_speed(id, g_flMaxSpeed)
	}

	if (g_iGravity > 0)
	{
		set_entvar(id, var_gravity, float(g_iGravity) / 800.0)
	}

	if (g_bGlowEnabled)
	{
		set_ent_rendering(id, kRenderFxGlowShell, g_iGlowColors[Red], g_iGlowColors[Green], g_iGlowColors[Blue], kRenderNormal, g_iGlowAmount)
	}

	if (g_flKnockback > 0.0)
	{
		// Set knockback.
		ze_set_zombie_knockback(id, g_flKnockback)
	}

	new szModel[MAX_RESOURCE_PATH_LENGTH]

	// Set player custom Model.
	ArrayGetString(g_aNemesisModel, random_num(0, ArraySize(g_aNemesisModel) - 1), szModel, charsmax(szModel))
	rg_set_user_model(id, szModel, true)

	// Set player custom Knife Model.
	ArrayGetString(g_aNemesisClaws, random_num(0, ArraySize(g_aNemesisClaws) - 1), szModel, charsmax(szModel))
	ze_set_user_view_model(id, CSW_KNIFE, szModel)
	ze_set_user_weap_model(id, CSW_KNIFE, "")
}

public unset_User_Nemesis(const id)
{
	// Remove player Flag Nemesis.
	flag_unset(g_bitsIsNemesis, id)

	// Reset player Max-Speed.
	ze_reset_user_speed(id)

	// Reset player rendering.
	set_ent_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
}

/**
 * -=| Natives |=-
 */
public __native_is_user_nemesis(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	return flag_get_boolean(g_bitsIsNemesis, id)
}

public __native_set_user_nemesis(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	set_User_Nemesis(id)
	return true
}

public __native_reset_user_nemesis(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	unset_User_Nemesis(id)

	if (get_param(2))
	{
		ze_set_user_human(id)
	}
	else
	{
		ze_set_user_zombie(id)
	}

	return true
}