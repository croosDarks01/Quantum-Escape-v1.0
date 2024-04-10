#include <amxmodx>
#include <amxmisc>
#include <ze_core>

// Cvars
new g_iMaxJumps,
	g_iMultiJump,
	g_iParachute,
	Float:g_flFallSpeed

// Variables.
new g_bitsMultiJump,
	g_bitsParachute

// Array.
new g_iJumpsNum[MAX_PLAYERS+1]

public plugin_natives()
{
	register_native("ze_set_user_multijump", "__native_set_user_multijump")
	register_native("ze_set_user_parachute", "__native_set_user_parachute")
}

public plugin_init()
{
	register_plugin("[ZE] Addon: Multi-Jumps/Parachute", "1.2", ZE_AUTHORS)

	// Hook Chains
	RegisterHookChain(RG_PM_AirMove, "fw_PM_AirMove_Pre")
	RegisterHookChain(RG_CBasePlayer_Jump, "fw_PlayerJump_Pre")

	// Cvars
	bind_pcvar_num(register_cvar("ze_multijumps_enable", "1"), g_iMultiJump)
	bind_pcvar_num(register_cvar("ze_multijumps_count", "2"), g_iMaxJumps)
	bind_pcvar_num(register_cvar("ze_parachute_enable", "1"), g_iParachute)
	bind_pcvar_float(register_cvar("ze_parachute_fallspeed", "100.0"), g_flFallSpeed)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iJumpsNum[id] = 0
	flag_unset(g_bitsMultiJump, id)
	flag_unset(g_bitsParachute, id)
}

public fw_PM_AirMove_Pre(const id)
{
	// Disabled!
	if (!g_iParachute)
		return

	if (!flag_get_boolean(g_bitsParachute, id) || g_iParachute != 1)
	{
		switch (g_iParachute)
		{
			case 2: // Human only?
			{
				if (ze_is_user_zombie(id))
					return
			}
			case 3: // Zombie only?
			{
				if (!ze_is_user_zombie(id))
					return
			}
		}
	}

	if (!(get_entvar(id, var_button) & IN_USE) || get_entvar(id, var_waterlevel) > 0)
		return

	static Float:vSpeed[3]
	get_entvar(id, var_velocity, vSpeed);

	if (vSpeed[2] < 0.0)
	{
		vSpeed[2] = (vSpeed[2] + 40.0 < -100.0) ? vSpeed[2] + 40.0 : -g_flFallSpeed

		// Flying animation.
		set_entvar(id, var_sequence, ACT_WALK);
		set_entvar(id, var_gaitsequence, ACT_IDLE);

		set_pmove(pm_velocity, vSpeed);
		set_movevar(mv_gravity, 80.0);
	}
}

public fw_PlayerJump_Pre(const id)
{
	// Disabled?
	if (!g_iMultiJump)
		return HC_CONTINUE

	if (!is_user_alive(id))
		return HC_CONTINUE

	static bitsFlags; bitsFlags = get_entvar(id, var_flags)

	if (bitsFlags & FL_WATERJUMP || get_entvar(id, var_waterlevel) >= 2 || !(get_member(id, m_afButtonPressed) & IN_JUMP))
		return HC_CONTINUE

	if (bitsFlags & FL_ONGROUND)
	{
		g_iJumpsNum[id] = 0
		return HC_CONTINUE
	}

	if (!flag_get_boolean(g_bitsMultiJump, id) || g_iMultiJump != 1)
	{
		switch (g_iMultiJump)
		{
			case 2: // Human only?
			{
				if (ze_is_user_zombie(id))
					return HC_CONTINUE
			}
			case 3: // Zombie only?
			{
				if (!ze_is_user_zombie(id))
					return HC_CONTINUE
			}
		}
	}

	if (++g_iJumpsNum[id] < g_iMaxJumps)
	{
		static Float:vSpeed[3]; vSpeed = NULL_VECTOR
		get_entvar(id, var_velocity, vSpeed)

		// +1 Jump.
		vSpeed[2] = 268.328157

		set_entvar(id, var_velocity, vSpeed), vSpeed = NULL_VECTOR
		return HC_SUPERCEDE
	}

	return HC_CONTINUE
}

/**
 * -=| Natives |=-
 */
public __native_set_user_multijump(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (!get_param(2))
		flag_set(g_bitsMultiJump, id)
	else
		flag_unset(g_bitsMultiJump, id)
	return true
}

public __native_set_user_parachute(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (!get_param(2))
		flag_set(g_bitsParachute, id)
	else
		flag_unset(g_bitsParachute, id)
	return true
}