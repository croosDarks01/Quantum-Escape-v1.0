#include <amxmodx>
#include <amxmisc>
#include <ze_core>
#include <ze_class_human>
#include <ze_class_zombie>
#include <ze_knife_menu>
#define LIBRARY_HUMAN "ze_class_human"
#define LIBRARY_ZOMBIE "ze_class_zombie"
#define LIBRARY_crxknives "ze_knife_menu"


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
	if (equal(module, LIBRARY_HUMAN) || equal(module, LIBRARY_ZOMBIE))
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
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \w%L^n", LANG_PLAYER, "MENU_EXTRAITEMS")
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \d%L^n", LANG_PLAYER, "MENU_EXTRAITEMS")
	}

	// New Line.
	szMenu[iLen++] = '^n'

	// 3. Human Classes
	if (module_exists(LIBRARY_HUMAN))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \w%L^n", LANG_PLAYER, "MENU_HCLASSES")
	}

	// 4. Zombie Classes
	if (module_exists(LIBRARY_ZOMBIE))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \w%L^n", LANG_PLAYER, "MENU_ZCLASSES")
	}
	// 5. Knife Menu


	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \w%L^n", LANG_PLAYER, "MENU_KNIFE")


	// New Line.
	szMenu[iLen++] = '^n'
	//6. Unstuck
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \w%L^n", LANG_PLAYER, "MENU_UNSTUCK")
	//7. Cam Menu
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7. \w%L^n", LANG_PLAYER, "MENU_CAM")
	
	// New Line.
	szMenu[iLen++] = '^n'
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8. %L^n", LANG_PLAYER, "MENU_ADMIN")
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
		case 2: // 3. Human Classes.
		{
			if (module_exists(LIBRARY_HUMAN))
			{
				ze_hclass_show_menu(id)
			}
		}
		case 3: // 4. Zombie Classes.
		{
			if (module_exists(LIBRARY_ZOMBIE))
			{
				ze_zclass_show_menu(id)
			}
		}
		
		case 4: // 5. Knife Menu.
		{

			crxknives_knife_show_menu(id, 1)

		}
		case 5: // 6. Unstuck.
		{

			client_cmd(id, "say /unstuck");

		}
		case 6: // 7.CAM MENU
		{
			client_cmd(id, "say /cam");

		}
		case 7: // 8.ADMIN MENU
		{
			client_cmd(id, "say /am");

		}

		case 9: // 0. Exit.
		{
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
