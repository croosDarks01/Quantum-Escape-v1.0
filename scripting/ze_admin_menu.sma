#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>
#include <ze_class_survivor>
#define LIBRARY_NEMESIS "ze_class_nemesis"
#define LIBRARY_SURVIVOR "ze_class_survivor"

// Keys Menu.
const KEYS_MENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_0

// Gamemodes Name.
stock const ESCAPE_MODE[] = "Escape"
stock const NEMESIS_MODE[] = "Nemesis"
stock const SURVIVOR_MODE[] = "Survivor"

enum _:MENU_PAGES
{
	PAGE_MAKE_HM_ZM = 0,
	PAGE_MAKE_NEMESIS,
	PAGE_MAKE_SURVIVOR,
	PAGE_RESPAWN_MENU
}

// Variables.
new g_iEscapeMode,
	g_iNemesisMode,
	g_iSurvivorMode,
	g_xGameChosen,
	g_bitsMakeHmZm,
	g_bitsMakeNemesis,
	g_bitsMakeSurvivor,
	g_bitsRespawnMenu,
	bool:g_bRoundEnd

// Array.
new g_iPage[MAX_PLAYERS+1][MENU_PAGES]

// String.
new g_szName[MAX_PLAYERS+1][MAX_NAME_LENGTH]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Addon: Admin Menu", "1.0alpha", "z0h1r-LK")

	// Commands.
	register_clcmd("say /am", "cmd_AdminMenu")
	register_clcmd("say_team /am", "cmd_AdminMenu")

	// New Menu's.
	register_menu("Admin_Menu", KEYS_MENU, "handler_Admin_Menu")

	// Initial Value.
	g_xGameChosen = get_xvar_id(X_Core_GamemodeBegin)
	g_iEscapeMode = ze_gamemode_get_id(ESCAPE_MODE)
	g_iNemesisMode = ze_gamemode_get_id(NEMESIS_MODE)
	g_iSurvivorMode = ze_gamemode_get_id(SURVIVOR_MODE)
}

public plugin_cfg()
{
	new szMakeHmZmDefFlags[2] = "d"
	new szMakeNemesisDefFlags[2] = "d"
	new szMakeSurvivorDefFlags[2] = "d"
	new szRespawnMenuDefFlags[2] = "d"

	if (!ini_read_string(ZE_FILENAME, "Access Flags", "MAKE_HM_ZM", szMakeHmZmDefFlags, charsmax(szMakeHmZmDefFlags)))
		ini_write_string(ZE_FILENAME, "Access Flags", "MAKE_HM_ZM", szMakeHmZmDefFlags)
	if (!ini_read_string(ZE_FILENAME, "Access Flags", "MAKE_NEMESIS", szMakeNemesisDefFlags, charsmax(szMakeNemesisDefFlags)))
		ini_write_string(ZE_FILENAME, "Access Flags", "MAKE_NEMESIS", szMakeNemesisDefFlags)
	if (!ini_read_string(ZE_FILENAME, "Access Flags", "MAKE_SURVIVOR", szMakeSurvivorDefFlags, charsmax(szMakeSurvivorDefFlags)))
		ini_write_string(ZE_FILENAME, "Access Flags", "MAKE_SURVIVOR", szMakeSurvivorDefFlags)
	if (!ini_read_string(ZE_FILENAME, "Access Flags", "RESPAWN_MENU", szRespawnMenuDefFlags, charsmax(szRespawnMenuDefFlags)))
		ini_write_string(ZE_FILENAME, "Access Flags", "RESPAWN_MENU", szRespawnMenuDefFlags)

	g_bitsMakeHmZm = read_flags(szMakeHmZmDefFlags)
	g_bitsMakeNemesis = read_flags(szMakeNemesisDefFlags)
	g_bitsMakeSurvivor = read_flags(szMakeSurvivorDefFlags)
	g_bitsRespawnMenu = read_flags(szRespawnMenuDefFlags)
}


public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	// Get player's name.
	get_user_name(id, g_szName[id], charsmax(g_szName[]))
}

public client_infochanged(id)
{
	// Player disconnected or HLTV Proxy?
	if (!is_user_connected(id) || is_user_hltv(id))
		return

	get_user_info(id, "name", g_szName[id], charsmax(g_szName[]))
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_szName[id] = NULL_STRING
}

public ze_game_started()
{
	g_bRoundEnd = false
}

public cmd_AdminMenu(const id)
{
	if (!is_user_admin(id))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ACCESS")
		return PLUGIN_HANDLED_MAIN
	}

	show_Admin_Menu(id)
	return PLUGIN_HANDLED_MAIN
}

public show_Admin_Menu(const id)
{
	new szMenu[MAX_MENU_LENGTH], iLen

	new const bitsFlags = get_user_flags(id)

	// Title.
	iLen = formatex(szMenu, charsmax(szMenu), "%L %L:^n^n", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_ADMIN_TITLE")

	// 1. Make Human/Zombie.
	if (bitsFlags & g_bitsMakeHmZm)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%L^n", LANG_PLAYER, "MENU_MAKE_HM_ZM")
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \d%L^n", LANG_PLAYER, "MENU_MAKE_HM_ZM")

	// 2. Make Nemesis.
	if (bitsFlags & g_bitsMakeNemesis && module_exists(LIBRARY_NEMESIS))
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \w%L^n", LANG_PLAYER, "MENU_MAKE_NEMESIS")
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \d%L^n", LANG_PLAYER, "MENU_MAKE_NEMESIS")

	// 3. Make Survivor.
	if (bitsFlags & g_bitsMakeSurvivor && module_exists(LIBRARY_SURVIVOR))
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \w%L^n", LANG_PLAYER, "MENU_MAKE_SURVIVOR")
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \d%L^n", LANG_PLAYER, "MENU_MAKE_SURVIVOR")

	// 4. Respawn Menu.
	if (bitsFlags & g_bitsRespawnMenu)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \w%L^n", LANG_PLAYER, "MENU_RESPAWN")
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \d%L^n", LANG_PLAYER, "MENU_RESPAWN")

	// New Line.
	szMenu[iLen++] = '^n'

	// 0. Exit.
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \w%L", LANG_PLAYER, "MENU_EXIT")

	// Show Menu for the player.
	show_menu(id, KEYS_MENU, szMenu, 30, "Admin_Menu")
}

public handler_Admin_Menu(const id, iKey)
{
	switch (iKey)
	{
		case 0:
		{
			if (!module_exists(LIBRARY_NEMESIS) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				return PLUGIN_HANDLED
			}

			if (!(get_user_flags(id) & g_bitsMakeHmZm))
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ACCESS")
				return PLUGIN_HANDLED
			}

			show_MakeHmZm_Menu(id)
		}
		case 1:
		{
			if (!module_exists(LIBRARY_NEMESIS) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				return PLUGIN_HANDLED
			}

			if (!(get_user_flags(id) & g_bitsMakeNemesis))
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ACCESS")
				return PLUGIN_HANDLED
			}

			show_MakeNemesis_Menu(id)
		}
		case 2:
		{
			if (!module_exists(LIBRARY_SURVIVOR) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				return PLUGIN_HANDLED
			}

			if (!(get_user_flags(id) & g_bitsMakeSurvivor))
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ACCESS")
				return PLUGIN_HANDLED
			}

			show_MakeSurvivor_Menu(id)
		}
		case 3:
		{
			if (!(get_user_flags(id) & g_bitsRespawnMenu))
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ACCESS")
				return PLUGIN_HANDLED
			}

			show_Respawn_Menu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_HANDLED
}

public show_MakeHmZm_Menu(const id)
{
	new szLang[64]

	// Title.
	formatex(szLang, charsmax(szLang), "%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_MAKE_HM_ZM")
	new iMenu = menu_create(szLang, "handler_MakeHmZm_Menu")

	new iClients[MAX_PLAYERS], iAliveNum
	get_players(iClients, iAliveNum, "ah")
	new const fNemesisLib = module_exists(LIBRARY_NEMESIS)

	for (new iItemData[2], iClient, i = 0; i < iAliveNum; i++)
	{
		iClient = iClients[i]

		if (fNemesisLib && ze_is_user_nemesis(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_NEMESIS")
		else if (ze_is_user_zombie(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_ZOMBIE")
		else // Human.
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_HUMAN")

		iItemData[0] = iClient
		menu_additem(iMenu, szLang, iItemData)
	}

	if (!menu_items(iMenu))
	{
		formatex(szLang, charsmax(szLang), "\d%L", LANG_PLAYER, "MENU_NO_PLAYERS")
		menu_addtext2(iMenu, szLang)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	if (g_iPage[id][PAGE_MAKE_HM_ZM] > menu_pages(iMenu))
		g_iPage[id][PAGE_MAKE_HM_ZM] = 0

	// Show Menu for the player.
	menu_display(id, iMenu, g_iPage[id][PAGE_MAKE_HM_ZM], 30)
}

public handler_MakeHmZm_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CLOSE_MENU
		}
		default:
		{
			new iItemData[2], iClient
			menu_item_getinfo(iMenu, iKey, _, iItemData, charsmax(iItemData))
			iClient = iItemData[0]

			if (!is_user_connected(iClient) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				show_MakeHmZm_Menu(id)
				goto CLOSE_MENU
			}

			if (g_iEscapeMode != ZE_GAME_INVALID && !get_xvar_num(g_xGameChosen))
			{
				ze_gamemode_start(g_iEscapeMode, iClient)
				ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_ZOMBIE", g_szName[id], g_szName[iClient])
			}
			else if (module_exists(LIBRARY_NEMESIS) && ze_is_user_nemesis(iClient))
			{
				if (get_member_game(m_iNumTerrorist) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_ZOMBIE")
				}
				else
				{
					ze_remove_user_nemesis(iClient, true)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_HUMAN", g_szName[id], g_szName[iClient])
				}
			}
			else if (ze_is_user_zombie(iClient))
			{
				if (get_member_game(m_iNumTerrorist) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_ZOMBIE")
				}
				else
				{
					ze_set_user_human(iClient)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_HUMAN", g_szName[id], g_szName[iClient])
				}
			}
			else // Human.
			{
				if (get_member_game(m_iNumCT) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_HUMAN")
				}
				else
				{
					ze_set_user_zombie(iClient)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_ZOMBIE", g_szName[id], g_szName[iClient])
				}
			}

			g_iPage[id][PAGE_MAKE_HM_ZM] = iKey/7
			show_MakeHmZm_Menu(id)
		}
	}

	CLOSE_MENU: // Free the Memory.
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public show_MakeNemesis_Menu(const id)
{
	new szLang[64]

	// Title.
	formatex(szLang, charsmax(szLang), "%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_MAKE_NEMESIS")
	new iMenu = menu_create(szLang, "handler_MakeNemesis_Menu")

	new iClients[MAX_PLAYERS], iAliveNum
	get_players(iClients, iAliveNum, "ah")
	new const fNemesisLib = module_exists(LIBRARY_NEMESIS)

	for (new iItemData[2], iClient, i = 0; i < iAliveNum; i++)
	{
		iClient = iClients[i]

		if (fNemesisLib && ze_is_user_nemesis(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_NEMESIS")
		else if (ze_is_user_zombie(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_ZOMBIE")
		else // Human.
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_HUMAN")

		iItemData[0] = iClient
		menu_additem(iMenu, szLang, iItemData)
	}

	if (!menu_items(iMenu))
	{
		formatex(szLang, charsmax(szLang), "\d%L", LANG_PLAYER, "MENU_NO_PLAYERS")
		menu_addtext2(iMenu, szLang)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	if (g_iPage[id][PAGE_MAKE_NEMESIS] > menu_pages(iMenu))
		g_iPage[id][PAGE_MAKE_NEMESIS] = 0

	// Show Menu for the player.
	menu_display(id, iMenu, g_iPage[id][PAGE_MAKE_NEMESIS], 30)
}

public handler_MakeNemesis_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CLOSE_MENU
		}
		default:
		{
			new iItemData[2], iClient
			menu_item_getinfo(iMenu, iKey, _, iItemData, charsmax(iItemData))
			iClient = iItemData[0]

			if (!is_user_connected(iClient) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				show_MakeNemesis_Menu(id)
				goto CLOSE_MENU
			}

			if (g_iNemesisMode != ZE_GAME_INVALID && !get_xvar_num(g_xGameChosen))
			{
				ze_gamemode_start(g_iNemesisMode, iClient)
				ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_NEMESIS", g_szName[id], g_szName[iClient])
			}
			else if (module_exists(LIBRARY_NEMESIS) && ze_is_user_nemesis(iClient))
			{
				if (get_member_game(m_iNumTerrorist) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_ZOMBIE")
				}
				else
				{
					ze_remove_user_nemesis(iClient, true)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_HUMAN", g_szName[id], g_szName[iClient])
				}
			}
			else if (ze_is_user_zombie(iClient))
			{
				ze_set_user_nemesis(iClient)
				ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_NEMESIS", g_szName[id], g_szName[iClient])
			}
			else // Human.
			{
				if (get_member_game(m_iNumCT) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_HUMAN")
				}
				else
				{
					ze_set_user_nemesis(iClient)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_NEMESIS", g_szName[id], g_szName[iClient])
				}
			}

			g_iPage[id][PAGE_MAKE_NEMESIS] = iKey/7
			show_MakeNemesis_Menu(id)
		}
	}

	CLOSE_MENU: // Free the Memory.
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public show_MakeSurvivor_Menu(const id)
{
	new szLang[64]

	// Title.
	formatex(szLang, charsmax(szLang), "%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_MAKE_SURVIVOR")
	new iMenu = menu_create(szLang, "handler_MakeSurvivor_Menu")

	new iClients[MAX_PLAYERS], iAliveNum
	get_players(iClients, iAliveNum, "ah")
	new const fNemesisLib = module_exists(LIBRARY_NEMESIS)
	new const fSurvivorLib = module_exists(LIBRARY_SURVIVOR)

	for (new iItemData[2], iClient, i = 0; i < iAliveNum; i++)
	{
		iClient = iClients[i]

		if (fSurvivorLib && ze_is_user_survivor(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_SURVIVOR")
		else if (fNemesisLib && ze_is_user_nemesis(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_NEMESIS")
		else if (ze_is_user_zombie(iClient))
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_ZOMBIE")
		else // Human.
			formatex(szLang, charsmax(szLang), "%s \r[%L]", g_szName[iClient], LANG_PLAYER, "CLASS_HUMAN")

		iItemData[0] = iClient
		menu_additem(iMenu, szLang, iItemData)
	}

	if (!menu_items(iMenu))
	{
		formatex(szLang, charsmax(szLang), "\d%L", LANG_PLAYER, "MENU_NO_PLAYERS")
		menu_addtext2(iMenu, szLang)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	if (g_iPage[id][PAGE_MAKE_SURVIVOR] > menu_pages(iMenu))
		g_iPage[id][PAGE_MAKE_SURVIVOR] = 0

	// Show Menu for the player.
	menu_display(id, iMenu, g_iPage[id][PAGE_MAKE_SURVIVOR], 30)
}

public handler_MakeSurvivor_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CLOSE_MENU
		}
		default:
		{
			new iItemData[2], iClient
			menu_item_getinfo(iMenu, iKey, _, iItemData, charsmax(iItemData))
			iClient = iItemData[0]

			if (!is_user_connected(iClient) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				show_MakeSurvivor_Menu(id)
				goto CLOSE_MENU
			}

			if (g_iSurvivorMode != ZE_GAME_INVALID && !get_xvar_num(g_xGameChosen))
			{
				ze_gamemode_start(g_iSurvivorMode, iClient)
				ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_SURVIVOR", g_szName[id], g_szName[iClient])
			}
			else if (module_exists(LIBRARY_SURVIVOR) && ze_is_user_survivor(iClient))
			{
				if (get_member_game(m_iNumCT) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_HUMAN")
				}
				else
				{
					ze_remove_user_survivor(iClient, true)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_ZOMBIE", g_szName[id], g_szName[iClient])
				}
			}
			else if (ze_is_user_zombie(iClient))
			{
				if (get_member_game(m_iNumTerrorist) == 1)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "CMD_LAST_ZOMBIE")
				}
				else
				{
					ze_set_user_survivor(iClient)
					ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_SURVIVOR", g_szName[id], g_szName[iClient])
				}
			}
			else // Human.
			{
				ze_set_user_survivor(iClient)
				ze_colored_print(0, "%L", LANG_PLAYER, "MSG_TURNED_SURVIVOR", g_szName[id], g_szName[iClient])
			}

			g_iPage[id][PAGE_MAKE_SURVIVOR] = iKey/7
			show_MakeSurvivor_Menu(id)
		}
	}

	CLOSE_MENU: // Free the Memory.
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public show_Respawn_Menu(const id)
{
	new szLang[64]

	// Title.
	formatex(szLang, charsmax(szLang), "%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_RESPAWN")
	new iMenu = menu_create(szLang, "handler_Respawn_Menu")

	new iClients[MAX_PLAYERS], iDeadNum
	get_players(iClients, iDeadNum, "bh")

	for (new iItemData[2], iClient, i = 0; i < iDeadNum; i++)
	{
		iClient = iClients[i]

		if (id == iClient)
			formatex(szLang, charsmax(szLang), "\y%s\r*", g_szName[iClient])
		else
			formatex(szLang, charsmax(szLang), "\w%s", g_szName[iClient])

		iItemData[0] = iClient
		menu_additem(iMenu, szLang, iItemData)
	}

	if (!menu_items(iMenu))
	{
		formatex(szLang, charsmax(szLang), "\d%L", LANG_PLAYER, "MENU_NO_PLAYERS")
		menu_addtext2(iMenu, szLang)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "MENU_EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	if (g_iPage[id][PAGE_RESPAWN_MENU] > menu_pages(iMenu))
		g_iPage[id][PAGE_RESPAWN_MENU] = 0

	// Show Menu for the player.
	menu_display(id, iMenu, g_iPage[id][PAGE_RESPAWN_MENU], 30)
}

public handler_Respawn_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CLOSE_MENU
		}
		default:
		{
			new iItemData[2], iClient
			menu_item_getinfo(iMenu, iKey, _, iItemData, charsmax(iItemData))
			iClient = iItemData[0]

			if (!is_user_connected(iClient) || is_user_alive(iClient) || g_bRoundEnd)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT")
				show_MakeSurvivor_Menu(id)
				goto CLOSE_MENU
			}

			// Re-spawn player.
			rg_round_respawn(iClient)
			ze_colored_print(0, "%L", LANG_PLAYER, "MSG_PLAYER_REVIVED", g_szName[id], g_szName[iClient])

			g_iPage[id][PAGE_RESPAWN_MENU] = iKey/7
			show_Respawn_Menu(id)
		}
	}

	CLOSE_MENU: // Free the Memory.
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public ze_roundend(iWinTeam)
{
	g_bRoundEnd = true
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
