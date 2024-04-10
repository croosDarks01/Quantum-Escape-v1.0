#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>

// File Name.
new const ZE_MODELS_FILENAME[] = "ze_users_models"

// pArray[ ]
enum _:MODEL_DATA
{
	MDATA_FLAG = 0,
	MDATA_AUTH[MAX_AUTHID_LENGTH],
	MDATA_HMODEL[MAX_NAME_LENGTH],
	MDATA_ZMODEL[MAX_NAME_LENGTH],
	MDATA_ZCLAWS[MAX_RESOURCE_PATH_LENGTH],
}

// Flags.
enum (+=1)
{
	FLG_INVALID = -1,
	FLG_NAME,
	FLG_NAME_SENS,
	FLG_AUTHID,
	FLG_ADMIN_FLAGS
}

// Variable.
new g_iMaxSkins

// Array.
new g_iCurrent[MAX_PLAYERS+1]

// Dynamic Array.
new Array:g_aModelArr

public plugin_precache()
{
	// Load Plug-In.
	register_plugin("[ZE] Player Models Manager", "1.0", "z0h1r-LK")

	new szCfgDir[24], szFile[45]
	g_aModelArr = ArrayCreate(MODEL_DATA, 1)

	// Get configs directory.
	get_configsdir(szCfgDir, charsmax(szCfgDir))

	// Read models from INI file.
	formatex(szFile, charsmax(szFile), "%s/%s.ini", szCfgDir, ZE_MODELS_FILENAME)
	read_Models(szFile)
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aModelArr)
}

public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	set_task(1.0, "DelayCheck", id)
}

public DelayCheck(id)
{
	if (is_user_connected(id))
		g_iCurrent[id] = check_Player(id)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iCurrent[id] = 0
}

public ze_user_humanized(id)
{
	static i

	if ((i = g_iCurrent[id]) == INVALID_HANDLE)
		return

	new pArray[MODEL_DATA]
	ArrayGetArray(g_aModelArr, i, pArray)

	if (pArray[MDATA_HMODEL] != EOS)
	{
		rg_set_user_model(id, pArray[MDATA_HMODEL], true)
	}
}

public ze_user_infected(iVictim, iInfector)
{
	static i

	if ((i = g_iCurrent[iVictim]) == INVALID_HANDLE)
		return

	new pArray[MODEL_DATA]
	ArrayGetArray(g_aModelArr, i, pArray)

	if (pArray[MDATA_ZMODEL] != EOS)
	{
		rg_set_user_model(iVictim, pArray[MDATA_ZMODEL], true)
	}

	if (pArray[MDATA_ZCLAWS] != EOS)
	{
		ze_set_user_view_model(iVictim, CSW_KNIFE, pArray[MDATA_ZCLAWS])
		ze_set_user_weap_model(iVictim, CSW_KNIFE)
	}
}

/**
 * -=| Function |=-
 */
read_Models(const szFile[])
{
	new hFile
	if ((hFile = fopen(szFile, "rt")))
	{
		new szRead[256], szTemp[4][64], szFlags[8], iFlag, iLine
		new szModel[MAX_RESOURCE_PATH_LENGTH], pArray[MODEL_DATA]

		while (!feof(hFile))
		{
			iLine++
			szRead = NULL_STRING

			if (!fgets(hFile, szRead, charsmax(szRead)))
				break

			trim(szRead)
			replace(szRead, charsmax(szRead), "^n", "")

			// Comment/Empty?
			switch (szRead[0]) { case '#', ';', 0: continue; }

			szFlags = NULL_STRING
			szTemp[0] = NULL_STRING
			szTemp[1] = NULL_STRING
			szTemp[2] = NULL_STRING
			szTemp[3] = NULL_STRING

			// Parse text.
			if (parse(szRead, szFlags, 7, szTemp[0], 63, szTemp[1], 63, szTemp[2], 63, szTemp[3], 63) < 3)
			{
				log_amx("[ZE] ^'%s^': error in arguments (Line #%i)", ZE_MODELS_FILENAME, iLine)
				continue
			}

			remove_quotes(szFlags)
			remove_quotes(szTemp[0])
			remove_quotes(szTemp[1])
			remove_quotes(szTemp[2])
			remove_quotes(szTemp[2])

			if ((iFlag = parse_Flags(szFlags)) != FLG_INVALID)
			{
				pArray[MDATA_FLAG] = iFlag
				copy(pArray[MDATA_AUTH], charsmax(pArray) - MDATA_AUTH, szTemp[0])
				copy(pArray[MDATA_HMODEL], charsmax(pArray) - MDATA_HMODEL, szTemp[1])
				copy(pArray[MDATA_ZMODEL], charsmax(pArray) - MDATA_ZMODEL, szTemp[2])
				copy(pArray[MDATA_ZCLAWS], charsmax(pArray) - MDATA_ZCLAWS, szTemp[3])

				// Pre-Load MODELs.
				if (pArray[MDATA_HMODEL] != EOS)
				{
					formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szTemp[1], szTemp[1])
					precache_model(szModel)
				}

				if (pArray[MDATA_ZMODEL] != EOS)
				{
					formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szTemp[2], szTemp[2])
					precache_model(szModel)
				}

				if (pArray[MDATA_ZCLAWS] != EOS)
				{
					precache_model(szTemp[3])
				}

				// Copy Array on dyn Array.
				ArrayPushArray(g_aModelArr, pArray)
				g_iMaxSkins++
			}
		}

		// Close the file.
		fclose(hFile)
	}
}

parse_Flags(const szFlag[])
{
	switch (szFlag[0])
	{
		case 'n': return FLG_NAME
		case 'N': return FLG_NAME_SENS
		case 'a': return FLG_AUTHID
		case 'f': return FLG_ADMIN_FLAGS
	}

	return FLG_INVALID
}

check_Player(const id)
{
	new szName[MAX_NAME_LENGTH], szSteamID[MAX_AUTHID_LENGTH], bitsFlags = get_user_flags(id)
	get_user_name(id, szName, charsmax(szName))
	get_user_authid(id, szSteamID, charsmax(szSteamID))

	for (new pArray[MODEL_DATA], i = 0; i < g_iMaxSkins; i++)
	{
		ArrayGetArray(g_aModelArr, i, pArray)

		switch (pArray[MDATA_FLAG])
		{
			case FLG_NAME:
			{
				if (equali(pArray[MDATA_AUTH], szName))
					return i
			}
			case FLG_NAME_SENS:
			{
				if (equal(pArray[MDATA_AUTH], szName))
					return i
			}
			case FLG_AUTHID:
			{
				if (equali(pArray[MDATA_AUTH], szSteamID))
					return i
			}
			case FLG_ADMIN_FLAGS:
			{
				if (bitsFlags & read_flags(pArray[MDATA_AUTH]))
					return i
			}
		}
	}

	return INVALID_HANDLE
}