#include <amxmodx>
#include <nvault>
#include <reapi>
#include <sqlx>

#include <ze_core>
#include <ini_file>

// Defines
#define TASK_SHOWHUD 2020

#define LEVEL_VERSION "2.1"

#define FADE_OUT     0x0000
#define FADE_COLOR_R 0
#define FADE_COLOR_G 200
#define FADE_COLOR_B 0
#define FADE_ALPHA   127

// Custom Forwards.
enum _:FORWARDS
{
	FORWARD_USER_XP_CHANGED = 0,
	FORWARD_USER_LEVEL_CHANGED
}

// Constants
new const g_szVaultLevels[] = "ZE_Levels"
new const g_szLogFile[] = "SQL_Levels.log" // MySQL Errors log file
new const g_szTable[] = "\
CREATE TABLE IF NOT EXISTS `ze_levels` (\
`AuthID` varchar(64) NOT NULL,\
`Level` int(20) NOT NULL DEFAULT 0,\
`XP` int(20) NOT NULL DEFAULT 0,\
`MaxXP` int(20) NOT NULL DEFAULT 0,\
PRIMARY KEY(AuthID));\
"

// HUD Positions.
const Float:HUD_SPECT_X = -1.0
const Float:HUD_SPECT_Y = 0.81

const Float:HUD_STATS_X = -1.0
const Float:HUD_STATS_Y = 0.92

// Colors indexes
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Level Up Sound.
new g_szLevelUpSound[MAX_RESOURCE_PATH_LENGTH] = "events/task_complete.wav"

// Variables.
new g_iMsgSyncHUD,
	g_iVaultLevels,
	g_msgFadeScreen,
	g_msgShakeScreen

// Cvars.
new g_iSaveType,
	g_iStartXP,
	g_iHudStyle,
	g_iMaxLevels,
	g_iDamageAward,
	g_iZombieInfect,
	g_iIncrementMode,
	g_iEscapeSuccess,
	g_iTargetXPNextLevel,
	g_iHumanHUDColor[Colors],
	g_iZombieHUDColor[Colors],
	g_iSpectHUDColor[Colors],
	bool:g_bLevelUpSound,
	bool:g_bEnableDamage,
	bool:g_bLevelEffects,
	bool:g_bDecreaseReqXP,
	Float:g_flRequiredDamage,
	Float:g_flIncrementValue

// Arrays.
new g_iXP[MAX_PLAYERS+1],
	g_iMaxXP[MAX_PLAYERS+1],
	g_iLevels[MAX_PLAYERS+1],
	g_iForwards[FORWARDS],
	Float:g_flDamage[MAX_PLAYERS+1]

// String.
new g_szName[MAX_PLAYERS+1][MAX_NAME_LENGTH]

// MySQL Handle.
new Handle:g_hTuple

public plugin_natives()
{
	register_library("ze_levels")
	register_native("ze_get_user_xp", "__native_get_user_xp")
	register_native("ze_set_user_xp", "__native_set_user_xp")
	register_native("ze_get_user_level", "__native_get_user_level")
	register_native("ze_set_user_level", "__native_set_user_level")
	register_native("ze_get_user_maxxp", "__native_get_user_maxxp")
	register_native("ze_set_user_maxxp", "__native_set_user_maxxp")
	register_native("ze_get_max_level", "__native_get_max_level")
}

public plugin_precache()
{
	// Read Level Up sound from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sounds", "LEVEL_UP", g_szLevelUpSound, charsmax(g_szLevelUpSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "LEVEL_UP", g_szLevelUpSound)

	// Precache Sound.
	new szSound[MAX_RESOURCE_PATH_LENGTH]
	formatex(szSound, charsmax(szSound), "sound/%s",g_szLevelUpSound)
	precache_generic(szSound)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Level-XP System", LEVEL_VERSION, ZE_AUTHORS)

	// Hook Chain.
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Post", 1)

	// Create Forwards.
	g_iForwards[FORWARD_USER_XP_CHANGED] = CreateMultiForward("ze_fw_user_xp", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_USER_LEVEL_CHANGED] = CreateMultiForward("ze_fw_user_level", ET_IGNORE, FP_CELL, FP_CELL)


	// Cvars.
	bind_pcvar_num(register_cvar("ze_levels_save_type", "0"), g_iSaveType) // 0 = nVault | 1 = MySQL

	bind_pcvar_num(register_cvar("ze_levels_zombie_infect", "2"), g_iZombieInfect)
	bind_pcvar_num(register_cvar("ze_levels_escape_success", "8"), g_iEscapeSuccess)

	bind_pcvar_num(register_cvar("ze_levels_dmg_enable", "1"), g_bEnableDamage)
	bind_pcvar_num(register_cvar("ze_levels_dmg_award", "3"), g_iDamageAward)
	bind_pcvar_float(register_cvar("ze_levels_dmg_require", "8000.0"), g_flRequiredDamage)

	bind_pcvar_num(register_cvar("ze_levels_start_xp", "0"), g_iStartXP)
	bind_pcvar_num(register_cvar("ze_levels_dec_req_xp", "0"), g_bDecreaseReqXP)
	bind_pcvar_num(register_cvar("ze_levels_max_xp_target", "10"), g_iTargetXPNextLevel)

	bind_pcvar_num(register_cvar("ze_levels_system_type", "0"), g_iIncrementMode)
	bind_pcvar_float(register_cvar("ze_levels_system_increment", "2.0"), g_flIncrementValue)

	bind_pcvar_num(register_cvar("ze_levels_up_sound", "1"), g_bLevelUpSound)
	bind_pcvar_num(register_cvar("ze_levels_up_effects", "1"), g_bLevelEffects)

	bind_pcvar_num(register_cvar("ze_levels_maximum", "100"), g_iMaxLevels)

	bind_pcvar_num(register_cvar("ze_levels_hud_style", "1"), g_iHudStyle)

	bind_pcvar_num(register_cvar("ze_levels_hud_human_red", "0"), g_iHumanHUDColor[Red])
	bind_pcvar_num(register_cvar("ze_levels_hud_human_green", "127"), g_iHumanHUDColor[Green])
	bind_pcvar_num(register_cvar("ze_levels_hud_human_blue", "255"), g_iHumanHUDColor[Blue])

	bind_pcvar_num(register_cvar("ze_levels_hud_zombie_red", "0"), g_iZombieHUDColor[Red])
	bind_pcvar_num(register_cvar("ze_levels_hud_zombie_green", "127"), g_iZombieHUDColor[Green])
	bind_pcvar_num(register_cvar("ze_levels_hud_zombie_blue", "255"), g_iZombieHUDColor[Blue])

	bind_pcvar_num(register_cvar("ze_levels_hud_spectator_red", "200"), g_iSpectHUDColor[Red])
	bind_pcvar_num(register_cvar("ze_levels_hud_spectator_green", "200"), g_iSpectHUDColor[Green])
	bind_pcvar_num(register_cvar("ze_levels_hud_spectator_blue", "200"), g_iSpectHUDColor[Blue])

	// Initial Values.
	g_iMsgSyncHUD = CreateHudSyncObj()
	g_msgFadeScreen = get_user_msgid("ScreenFade")
	g_msgShakeScreen = get_user_msgid("ScreenShake")
}

public plugin_cfg()
{
	switch (g_iSaveType)
	{
		case 0: // nVault.
		{
			g_iVaultLevels = nvault_open(g_szVaultLevels)

			// Disable plugin.
			if (g_iVaultLevels == INVALID_HANDLE)
				set_fail_state("Error in opening the nVault (-1)")
		}
		case 1: // MySQL.
		{
			MySQL_Init()
		}
	}
}

public plugin_end()
{
	switch (g_iSaveType)
	{
		case 0: // nVault.
		{
			nvault_close(g_iVaultLevels)
		}
		case 1:
		{
			if (g_hTuple != Empty_Handle)
				SQL_FreeHandle(g_hTuple)
		}
	}
}

public MySQL_Init()
{
	new szHost[64], szUser[64], szPass[64], szDB[64]

	get_pcvar_string(register_cvar("amx_sql_host", "127.0.0.1", FCVAR_PROTECTED), szHost, charsmax(szHost))
	get_pcvar_string(register_cvar("amx_sql_user", "root", FCVAR_PROTECTED), szUser, charsmax(szUser))
	get_pcvar_string(register_cvar("amx_sql_pass", "", FCVAR_PROTECTED), szPass, charsmax(szPass))
	get_pcvar_string(register_cvar("amx_sql_db", "amx", FCVAR_PROTECTED), szDB, charsmax(szDB))
	new const iTimeOut = get_pcvar_num(register_cvar("amx_sql_timeout", "60", FCVAR_PROTECTED))

	g_hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB, iTimeOut)

	// Let's ensure that the g_hTuple will be valid, we will access the database to make sure
	new iErrorCode, szError[512], Handle:hSQLConnection

	// Connect SQL database.
	hSQLConnection = SQL_Connect(g_hTuple, iErrorCode, szError, charsmax(szError))

	if (hSQLConnection != Empty_Handle)
	{
		log_amx("[MySQL][LVL] Successfully connected to host: %s (ALL IS OK).", szHost)

		// Frees SQL handle.
		SQL_FreeHandle(hSQLConnection)
	}
	else
	{
		// Disable plugin
		set_fail_state("[MySQL][LVL] Failed to connect to MySQL database: %s.", szError)
	}

	SQL_ThreadQuery(g_hTuple, "query_CreateTable", g_szTable)
}

public query_CreateTable(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id) || is_user_bot(id))
		return

	// Get player's name.
	get_user_name(id, g_szName[id], charsmax(g_szName[]))

	// Other tasks.
	set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, .flags = "b")
}

public client_authorized(id, const authid[])
{
	// HLTV Proxy?
	if (is_user_hltv(id) || equali(authid, "BOT"))
		return

	read_Data(id, authid)
}

public client_infochanged(id)
{
	if (!is_user_connected(id))
		return

	// Fake Client?
	if (is_user_hltv(id) || is_user_bot(id))
		return

	// Get player's name.
	get_user_info(id, "name", g_szName[id], charsmax(g_szName[]))
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id) || is_user_bot(id))
		return

	write_Data(id)

	g_szName[id] = NULL_STRING

	// Remove Task.
	remove_task(id+TASK_SHOWHUD)
}

public ShowHUD(taskid)
{
	static target, id

	id = target = taskid - TASK_SHOWHUD

	if (!is_user_alive(id))
	{
		if (get_entvar(id, var_iuser1) == OBS_ROAMING)
		{
			get_user_aiming(id, target)
		}
		else
		{
			target = get_entvar(id, var_iuser2)
		}

		if (!is_user_alive(target))
		{
			return
		}
	}

	if(id != target)
	{
		set_hudmessage(g_iSpectHUDColor[Red], g_iSpectHUDColor[Green], g_iSpectHUDColor[Blue], HUD_SPECT_X, HUD_SPECT_Y, 0, 1.0, 1.0, 0.0, 0.1, -1)

		switch (g_iHudStyle)
		{
			case 0: // Disabled
			{
				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_SPEC_LEVEL", g_iLevels[target], g_iXP[target], g_iMaxXP[target])
			}
			case 1: // Percentage.
			{
				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_SPEC_LEVEL_PERC", g_iLevels[target], ( float(g_iXP[target]) / float(g_iMaxXP[target]) ) * 100.0)
			}
			case 2: //
			{
				static szLevel[32], szXP[32], szMaxXP[32]
				szLevel = NULL_STRING, szXP = NULL_STRING, szMaxXP = NULL_STRING

				AddCommas(g_iXP[target], szXP, charsmax(szXP))
				AddCommas(g_iMaxXP[target], szMaxXP, charsmax(szMaxXP))
				AddCommas(g_iLevels[target], szLevel, charsmax(szLevel))

				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_SPEC_LEVEL_COMMAS", szLevel, szXP, szMaxXP)
			}
			case 3:
			{
				static szLevel[32], szXP[32], szMaxXP[32]
				szLevel = NULL_STRING, szXP = NULL_STRING, szMaxXP = NULL_STRING

				NumAbbrev(g_iXP[target], szXP, charsmax(szXP))
				NumAbbrev(g_iMaxXP[target], szMaxXP, charsmax(szMaxXP))
				NumAbbrev(g_iLevels[target], szLevel, charsmax(szLevel))

				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_SPEC_LEVEL_NUM_ABBR", szLevel, szXP, szMaxXP)
			}
		}
	}
	else
	{
		if (ze_is_user_zombie(id))
		{
			set_hudmessage(g_iZombieHUDColor[Red], g_iZombieHUDColor[Green], g_iZombieHUDColor[Blue], HUD_STATS_X, HUD_STATS_Y, 0, 1.0, 1.0, 0.0, 0.1, -1)
		}
		else // Human.
		{
			set_hudmessage(g_iHumanHUDColor[Red], g_iHumanHUDColor[Green], g_iHumanHUDColor[Blue], HUD_STATS_X, HUD_STATS_Y, 0, 1.0, 1.0, 0.0, 0.1, -1)
		}

		switch (g_iHudStyle)
		{
			case 0: // Disabled
			{
				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_USER_LEVEL", g_iLevels[id], g_iXP[id], g_iMaxXP[id])
			}
			case 1: // Percentage.
			{
				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_USER_LEVEL_PERC", g_iLevels[id], ( float(g_iXP[id]) / float(g_iMaxXP[id]) ) * 100.0)
			}
			case 2: //
			{
				static szLevel[32], szXP[32], szMaxXP[32]
				szLevel = NULL_STRING, szXP = NULL_STRING, szMaxXP = NULL_STRING

				AddCommas(g_iXP[id], szXP, charsmax(szXP))
				AddCommas(g_iMaxXP[id], szMaxXP, charsmax(szMaxXP))
				AddCommas(g_iLevels[id], szLevel, charsmax(szLevel))

				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_USER_LEVEL_COMMAS", szLevel, szXP, szMaxXP)
			}
			case 3:
			{
				static szLevel[32], szXP[32], szMaxXP[32]
				szLevel = NULL_STRING, szXP = NULL_STRING, szMaxXP = NULL_STRING

				NumAbbrev(g_iXP[id], szXP, charsmax(szXP))
				NumAbbrev(g_iMaxXP[id], szMaxXP, charsmax(szMaxXP))
				NumAbbrev(g_iLevels[id], szLevel, charsmax(szLevel))

				ShowSyncHudMsg(id, g_iMsgSyncHUD, "%L", LANG_PLAYER, "HUD_USER_LEVEL_NUM_ABBR", szLevel, szXP, szMaxXP)
			}
		}
	}
}

public check_NextLevel(const id)
{
	if (g_iLevels[id] >= g_iMaxLevels)
		return

	// Fix crashs server!
	if (g_iMaxXP[id] <= 0)
		return

	new bool:bLevelUp
	while (g_iXP[id] >= g_iMaxXP[id])
	{
		if (g_bDecreaseReqXP)
		{
			g_iXP[id] -= g_iTargetXPNextLevel
		}

		g_iLevels[id]++

		switch (g_iIncrementMode)
		{
			case 0: // {MAX_XP} = ( {MAX_XP} + {TARGET_XP} )
			{
				g_iMaxXP[id] += g_iTargetXPNextLevel
			}
			case 1: // {MAX_XP} = ( {MAX_XP} * {INCREAMENT} )
			{
				g_iMaxXP[id] = floatround( g_iMaxXP[id] * g_flIncrementValue )
			}
		}

		bLevelUp = true

		// Call forward ze_fw_user_level(param1, param2)
		ExecuteForward(g_iForwards[FORWARD_USER_LEVEL_CHANGED], _/* Ignore return value */, id, g_iLevels[id])

		// Send colored message on chat for player.
		ze_colored_print(0, "%L", LANG_PLAYER, "MSG_LEVEL_UP", g_szName[id], g_iLevels[id])
	}

	if (bLevelUp)
	{
		if (g_bLevelUpSound)
		{
			PlaySound(id, g_szLevelUpSound)
		}

		if (g_bLevelEffects)
		{
			// Screen Fade
			message_begin(MSG_ONE_UNRELIABLE, g_msgFadeScreen, .player = id)
			write_short(BIT(12)) // Duration.
			write_short(0) // Hold time.
			write_short(FADE_OUT) // Fade type.
			write_byte(FADE_COLOR_R) // Red.
			write_byte(FADE_COLOR_G) // Green.
			write_byte(FADE_COLOR_B) // Blue.
			write_byte(FADE_ALPHA) // Brightness.
			message_end()

			// Screen Shake
			message_begin(MSG_ONE_UNRELIABLE, g_msgShakeScreen, .player = id)
			write_short(BIT(12)) // Duration.
			write_short(4 * BIT(12)) // Amplitude.
			write_short(3 * BIT(12)) // Frequency.
			message_end()
		}
	}
}

public ze_user_infected(iVictim, iInfector)
{
	if (!iInfector)
		return

	if (g_iZombieInfect > 0)
	{
		// +XP
		g_iXP[iInfector] += g_iZombieInfect
		check_NextLevel(iInfector)

		// Call forward ze_fw_user_xp(id, iXP)
		ExecuteForward(g_iForwards[FORWARD_USER_XP_CHANGED], _/* Ignore return value */, iInfector, g_iXP[iInfector])
	}
}

public fw_TakeDamage_Post(iVictim, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	if (!g_bEnableDamage || g_flRequiredDamage <= 0.0)
		return

	if (iVictim == iAttacker || !is_user_connected(iAttacker))
		return

	if (!ze_is_user_zombie(iVictim))
		return

	if (!ze_is_user_zombie(iAttacker))
	{
		g_flDamage[iAttacker] += flDamage

		while (g_flDamage[iAttacker] >= g_flRequiredDamage)
		{
			g_iXP[iAttacker] += g_iDamageAward
			g_flDamage[iAttacker] -= g_flRequiredDamage
			check_NextLevel(iAttacker)
		}
	}
}

public ze_roundend(iWinTeam)
{
	if (g_iEscapeSuccess > 0)
	{
		if (iWinTeam == ZE_TEAM_HUMAN)
		{
			// Get index of all alive players.
			new iPlayers[MAX_PLAYERS], iAliveNum
			get_players(iPlayers, iAliveNum, "ah")

			for(new id, i = 0; i < iAliveNum; i++)
			{
				id = iPlayers[i]

				// Isn't Human?
				if (ze_is_user_zombie(id))
					continue

				g_iXP[id] += g_iEscapeSuccess
				check_NextLevel(id)
			}
		}
	}
}

public read_Data(id, const szAuthId[])
{
	switch (g_iSaveType)
	{
		case 0: // nVault.
		{
			// Read Data from Vault.
			new szData[128]
			if (nvault_get(g_iVaultLevels, szAuthId, szData, charsmax(szData)))
			{
				new szLevel[16], szXP[32], szMaxXP[32]

				// Parse the text.
				parse(szData, szLevel, charsmax(szLevel), szXP, charsmax(szXP), szMaxXP, charsmax(szMaxXP))

				g_iXP[id] = str_to_num(szXP)
				g_iLevels[id] = str_to_num(szLevel)
				g_iMaxXP[id] = str_to_num(szMaxXP)
			}
			else
			{
				g_iLevels[id] = 0
				g_iXP[id] = g_iStartXP
				g_iMaxXP[id] = g_iTargetXPNextLevel
			}
		}
		case 1: // MySQL.
		{
			new szQuery[128], szData[4]
			formatex(szQuery, charsmax(szQuery), "SELECT * FROM `ze_levels` WHERE `AuthID` = '%s';", szAuthId)

			num_to_str(id, szData, charsmax(szData))
			SQL_ThreadQuery(g_hTuple, "query_SelectData", szQuery, szData, charsmax(szData))
		}
	}
}

public query_SelectData(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if (SQL_IsFail(iFailState, iError, szError, g_szLogFile))
		return

	new const id = str_to_num(szData)

	// No results for this query means this is new player
	if (!SQL_NumResults(hQuery))
	{
		g_iXP[id] = g_iStartXP
		g_iMaxXP[id] = g_iTargetXPNextLevel
		g_iLevels[id] = 0
	}
	else
	{
		g_iXP[id] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "XP"))
		g_iLevels[id] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "Level"))
		g_iMaxXP[id] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "MaxXP"))
	}

	check_NextLevel(id)
}

public write_Data(id)
{
	// Get player's authid.
	new szAuthId[MAX_AUTHID_LENGTH]
	get_user_authid(id, szAuthId, charsmax(szAuthId))

	// Set Him to max if he Higher than Max Value
	if (g_iLevels[id] > g_iMaxLevels)
		g_iLevels[id] = g_iMaxLevels

	if (g_iXP[id] > g_iMaxXP[id])
		g_iXP[id] = g_iMaxXP[id]

	switch (g_iSaveType)
	{
		case 0: // nVault.
		{
			new szData[128]
			formatex(szData , charsmax(szData), "%i %i %i", g_iLevels[id], g_iXP[id], g_iMaxXP[id])
			nvault_pset(g_iVaultLevels, szAuthId, szData)
		}
		case 1: // MySQL.
		{
			new szQuery[128]
			formatex(szQuery, charsmax(szQuery), "REPLACE INTO `ze_levels` (`AuthID`, `Level`, `XP`, `MaxXP`) VALUES ('%s', %d, %d, %d);", szAuthId, g_iLevels[id], g_iXP[id], g_iMaxXP[id])
			SQL_ThreadQuery(g_hTuple, "query_SetData", szQuery)
		}
	}
}

public query_SetData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

public __native_get_user_xp(const plugin_id, const num_params)
{
	static id; id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return NULLENT
	}

	return g_iXP[id]
}

public __native_set_user_xp(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (get_param(3))
		g_iXP[id] += get_param(2)
	else
		g_iXP[id] = get_param(2)

	check_NextLevel(id)
	return true
}

public __native_get_user_level(const plugin_id, const num_params)
{
	static id; id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return NULLENT
	}

	return g_iLevels[id]
}

public __native_set_user_level(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (get_param(3))
		g_iLevels[id] += get_param(2)
	else
		g_iLevels[id] = get_param(2)

	return true
}

public __native_get_user_maxxp(const plugin_id, const num_params)
{
	static id; id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return NULLENT
	}

	return g_iMaxXP[id]
}

public __native_set_user_maxxp(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (get_param(3))
		g_iMaxXP[id] += get_param(2)
	else
		g_iMaxXP[id] = get_param(2)

	check_NextLevel(id)
	return true
}
public __native_get_max_level()
{    
    return g_iMaxLevels
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
