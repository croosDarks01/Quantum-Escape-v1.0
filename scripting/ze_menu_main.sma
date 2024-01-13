#include <amxmodx>
#include <amxmisc>

#include <ze_core>
#include <ze_class_zombie>
#define LIBRARY_ZOMBIE "ze_class_zombie"

// Keys Menu.
const KEYS_MENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

// Menu Sounds.
new g_szSelectSound[MAX_RESOURCE_PATH_LENGTH] = "buttons/lightswitch2.wav"
new g_szDisplaySound[MAX_RESOURCE_PATH_LENGTH] = "buttons/lightswitch2.wav"

// Variable.
new bool:g_bMenuSound

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_ZOMBIE))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	// Read menu sounds from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sounds", "MENU_SELECT", g_szSelectSound, charsmax(g_szSelectSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "MENU_SELECT", g_szSelectSound)
	if (!ini_read_string(ZE_FILENAME, "Sounds", "MENU_DISPLAY", g_szDisplaySound, charsmax(g_szDisplaySound)))
		ini_write_string(ZE_FILENAME, "Sounds", "MENU_DISPLAY", g_szDisplaySound)

	new szSound[MAX_RESOURCE_PATH_LENGTH]

	// Precache Sounds.
	formatex(szSound, charsmax(szSound), "sound/%s", g_szSelectSound)
	precache_generic(szSound)
	formatex(szSound, charsmax(szSound), "sound/%s", g_szDisplaySound)
	precache_generic(szSound)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Menu Main", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_menu_sounds", "1"), g_bMenuSound)

	// Commands.
	register_clcmd("jointeam", "cmd_MenuMain")
	register_clcmd("chooseteam", "cmd_MenuMain")
	register_clcmd("say /menu", "cmd_MenuMain")
	register_clcmd("say_team /menu", "cmd_MenuMain")

	// New Menu's.
	register_menu("Menu_Main", KEYS_MENU, "handler_Menu_Main")
}

public cmd_MenuMain(const id)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE

	show_Menu_Main(id)
	return PLUGIN_HANDLED_MAIN
}

public show_Menu_Main(const id)
{
	static szMenu[MAX_MENU_LENGTH], iLen
	szMenu = NULL_STRING

	// Menu Title.
	iLen = formatex(szMenu, charsmax(szMenu), "\r%L \y%L:^n^n", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_MAIN_TITLE")

	// 1. Weapons Menu.
	if (is_user_alive(id))
	{
		if (ze_auto_buy_enabled(id))
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \d%L^n", LANG_PLAYER, "MENU_RE_WEAPONS")
		}
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%L^n", LANG_PLAYER, "MENU_WEAPONS")
		}
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \d%L^n", LANG_PLAYER, "MENU_WEAPONS")
	}

	// 2. Extra Items.
	if (is_user_alive(id))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \y%L^n", LANG_PLAYER, "MENU_EXTRAITEMS")
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \d%L^n", LANG_PLAYER, "MENU_EXTRAITEMS")
	}

	// 3. Zombie Classes
	if (module_exists(LIBRARY_ZOMBIE))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \y%L^n", LANG_PLAYER, "MENU_ZCLASSES")
	}

	// New Line.
	szMenu[iLen++] = '^n'

	// 0. Exit.
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \w%L", LANG_PLAYER, "MENU_EXIT")

	if (g_bMenuSound)
	{
		// Play display sound.
		PlaySound(id, g_szDisplaySound)
	}

	// Show the Menu for player.
	show_menu(id, KEYS_MENU, szMenu, 30, "Menu_Main")
}

public handler_Menu_Main(const id, iKey)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED

	if (g_bMenuSound)
	{
		// Play select sound.
		PlaySound(id, g_szSelectSound)
	}

	switch (iKey)
	{
		case 0: // 1. Weapons Menu.
		{
			if (ze_auto_buy_enabled(id))
			{
				ze_set_auto_buy(id)
			}
			else
			{
				ze_show_weapons_menu(id)
			}
		}
		case 1: // 2. Extra Items.
		{
			// Show Extra-Items menu for player.
			ze_item_show_menu(id)
		}
		case 2: // 3. Zombie Classes.
		{
			if (module_exists(LIBRARY_ZOMBIE))
			{
				ze_zclass_show_menu(id)
			}
		}
		case 9: // 0. Exit.
		{
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_HANDLED
}