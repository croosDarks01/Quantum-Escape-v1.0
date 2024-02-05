#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ze_class_const>
#include <ze_class_survivor>
#define LIBRARY_HUDINFO "ze_hud_info"
#define LIBRARY_SURVIVOR "ze_class_survivor"
#define LIBRARY_WPNMODELS "ze_weap_models_api"

// Macro.
#define FIsWrongClass(%0) (ZE_CLASS_INVALID>=(%0)>=g_iNumHumans)

// Human Attributes.
enum _:HUMAN_ATTRIB
{
	HUMAN_NAME[MAX_NAME_LENGTH] = 0,
	HUMAN_DESC[64],
	HUMAN_MODEL[MAX_NAME_LENGTH],
	Float:HUMAN_HEALTH,
	Float:HUMAN_ARMOR,
	HUMAN_SPEED_FACTOR,
	Float:HUMAN_SPEED,
	Float:HUMAN_GRAVITY
}

// Colors indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Default Human Attributes.
stock const DEFAULT_HUMAN_NAME[] = "Regular Human"
stock const DEFAULT_HUMAN_DESC[] = "-= Balanced =-"
stock const DEFAULT_HUMAN_MODEL[] = "gign"
stock Float:DEFAULT_HUMAN_HEALTH = 10000.0
stock Float:DEFAULT_HUMAN_ARMOR = 0.0
stock DEFAULT_HUMAN_SPEED_FACTOR = 1
stock Float:DEFAULT_HUMAN_SPEED = 25.0
stock Float:DEFAULT_HUMAN_GRAVITY = 800.0

// Variable.
new g_iNumHumans

// Cvars.
new bool:g_bHumanShield,
	g_iHudColor[Colors]

// Arrays.
new g_iNext[MAX_PLAYERS+1],
	g_iPage[MAX_PLAYERS+1],
	g_iCurrent[MAX_PLAYERS+1]

// Dynamic Array.
new Array:g_aHumanClass

public plugin_natives()
{
	register_library("ze_class_human")
	register_native("ze_hclass_register", "__native_hclass_register")
	register_native("ze_hclass_get_current", "__native_hclass_get_current")
	register_native("ze_hclass_get_next", "__native_hclass_get_next")
	register_native("ze_hclass_is_valid", "__native_hclass_is_valid")
	register_native("ze_hclass_get_name", "__native_hclass_get_name")
	register_native("ze_hclass_get_desc", "__native_hclass_get_desc")
	register_native("ze_hclass_get_model", "__native_hclass_get_model")
	register_native("ze_hclass_get_health", "__native_hclass_get_health")
	register_native("ze_hclass_get_armor", "__native_hclass_get_armor")
	register_native("ze_hclass_is_speed_factor", "__native_hclass_is_speed_factor")
	register_native("ze_hclass_get_speed", "__native_hclass_get_speed")
	register_native("ze_hclass_get_gravity", "__native_hclass_get_gravity")
	register_native("ze_hclass_set_current", "__native_hclass_set_current")
	register_native("ze_hclass_set_next", "__native_hclass_set_next")
	register_native("ze_hclass_set_name", "__native_hclass_set_name")
	register_native("ze_hclass_set_desc", "__native_hclass_set_desc")
	register_native("ze_hclass_set_health", "__native_hclass_set_health")
	register_native("ze_hclass_set_armor", "__native_hclass_set_armor")
	register_native("ze_hclass_set_speed_factor", "__native_hclass_set_speed_factor")
	register_native("ze_hclass_set_speed", "__native_hclass_set_speed")
	register_native("ze_hclass_set_gravity", "__native_hclass_set_gravity")
	register_native("ze_hclass_show_menu", "__native_hclass_show_menu")

	set_module_filter("fw_module_filter")
	set_native_filter("fw_native_filter")

	// Create new dyn Array.
	g_aHumanClass = ArrayCreate(HUMAN_ATTRIB, 1)
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_HUDINFO) || equal(module, LIBRARY_WPNMODELS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Human", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_human_shield", "1"), g_bHumanShield)

	bind_pcvar_num(register_cvar("ze_hud_info_human_red", "0"), g_iHudColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_human_green", "127"), g_iHudColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_human_blue", "255"), g_iHudColor[Blue])

	// Commands.
	register_clcmd("say /hm", "cmd_ShowClassesMenu")
	register_clcmd("say_team /hm", "cmd_ShowClassesMenu")
	register_clcmd("say /hclass", "cmd_ShowClassesMenu")
	register_clcmd("say_team /hclass", "cmd_ShowClassesMenu")
}

public plugin_cfg()
{
	if (!g_iNumHumans)
	{
		new aArray[HUMAN_ATTRIB]

		// Default Zombie.
		copy(aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME, DEFAULT_HUMAN_NAME)
		copy(aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC, DEFAULT_HUMAN_DESC)
		copy(aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL, DEFAULT_HUMAN_MODEL)
		aArray[HUMAN_HEALTH] = DEFAULT_HUMAN_HEALTH
		aArray[HUMAN_ARMOR] = DEFAULT_HUMAN_ARMOR
		aArray[HUMAN_SPEED_FACTOR] = 1
		aArray[HUMAN_SPEED] = DEFAULT_HUMAN_SPEED
		aArray[HUMAN_GRAVITY] = DEFAULT_HUMAN_GRAVITY

		// Copy Array on dyn Array.
		ArrayPushArray(g_aHumanClass, aArray)
		g_iNumHumans = 1
	}
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aHumanClass)
}

public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iCurrent[id] = ZE_CLASS_INVALID
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iPage[id] = 0
	g_iNext[id] = 0
	g_iCurrent[id] = 0
}

public cmd_ShowClassesMenu(const id)
{
	show_Humans_Menu(id)
	return PLUGIN_CONTINUE
}

public ze_user_humanized(id)
{
	// Ignore Survivor!
	if (module_exists(LIBRARY_SURVIVOR) && ze_is_user_survivor(id)) return

	// Player hasn't chosen a class yet?
	if (g_iCurrent[id] == ZE_CLASS_INVALID)
		show_Humans_Menu(id)

	new const iClassID = g_iCurrent[id] = g_iNext[id]

	// Get Zombie attributes.
	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, iClassID, aArray)

	set_entvar(id, var_health, aArray[HUMAN_HEALTH])
	set_entvar(id, var_max_health, aArray[HUMAN_HEALTH])
	set_entvar(id, var_gravity, (aArray[HUMAN_GRAVITY] / 800.0))

	ze_set_user_speed(id, aArray[HUMAN_SPEED], bool:aArray[HUMAN_SPEED_FACTOR])

	if (module_exists(LIBRARY_HUDINFO))
	{
		ze_hud_info_set(id, aArray[HUMAN_NAME], g_iHudColor)
	}

	rg_set_user_model(id, aArray[HUMAN_MODEL], true)

	if (module_exists(LIBRARY_WPNMODELS))
	{
		ze_remove_user_view_model(id, CSW_KNIFE)
		ze_remove_user_weap_model(id, CSW_KNIFE)
	}
}

public show_Humans_Menu(const id)
{
	new szLang[MAX_MENU_LENGTH]

	// Title.
	formatex(szLang, charsmax(szLang), "\r%L \y%L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_HUMANS_TITLE")
	new iMenu = menu_create(szLang, "handler_Humans_Menu")

	for (new aArray[HUMAN_ATTRIB], iItemData[2], i = 0; i < g_iNumHumans; i++)
	{
		ArrayGetArray(g_aHumanClass, i, aArray)

		if (i == g_iCurrent[id])
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s \d[\r%L\d]", aArray[HUMAN_NAME], aArray[HUMAN_DESC], LANG_PLAYER, "CURRENT")
		else if (i == g_iNext[id])
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s \d[\r%L\d]", aArray[HUMAN_NAME], aArray[HUMAN_DESC], LANG_PLAYER, "NEXT")
		else
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s", aArray[HUMAN_NAME], aArray[HUMAN_DESC])

		iItemData[0] = i

		menu_additem(iMenu, szLang, iItemData)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	// Show the Menu for player.
	menu_display(id, iMenu, g_iPage[id], 20)
}

public handler_Humans_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			menu_destroy(iMenu)
			return PLUGIN_HANDLED
		}
		default:
		{
			new aArray[HUMAN_ATTRIB], iItemData[2]
			menu_item_getinfo(iMenu, iKey, .info = iItemData, .infolen = charsmax(iItemData))

			// Get Zombie Attributes.
			new i = iItemData[0]
			ArrayGetArray(g_aHumanClass, i, aArray)

			g_iNext[id] = i
			g_iPage[id] = iKey / 7

			// Send colored message on chat for player.
			ze_colored_print(id, "%L", LANG_PLAYER, "MSG_HUMAN_NAME", aArray[HUMAN_NAME])
			ze_colored_print(id, "%L", LANG_PLAYER, "MSG_HUMAN_INFO", aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], LANG_PLAYER, aArray[HUMAN_SPEED_FACTOR] ? "DYNAMIC" : "STATIC", aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY])
		}
	}

	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

/**
 * -=| Natives |=-
 */
public __native_hclass_register(const plugin_id, const num_params)
{
	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register new class without name.")
		return ZE_CLASS_INVALID
	}

	new aArray[HUMAN_ATTRIB]
	for (new i = 0; i < g_iNumHumans; i++)
	{
		ArrayGetArray(g_aHumanClass, i, aArray)

		if (equal(szName, aArray[HUMAN_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't register new class with exist name.")
			return ZE_CLASS_INVALID
		}
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "NAME", aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME))
	{
		copy(aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME, szName)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "NAME", aArray[HUMAN_NAME])
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "DESC", aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC))
	{
		get_string(2, aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "DESC", aArray[HUMAN_DESC])
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "MODEL", aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL))
	{
		get_string(3, aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "MODEL", aArray[HUMAN_MODEL])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "HEALTH", aArray[HUMAN_HEALTH]))
	{
		aArray[HUMAN_HEALTH] = get_param_f(4)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "HEALTH", aArray[HUMAN_HEALTH])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "ARMOR", aArray[HUMAN_ARMOR]))
	{
		aArray[HUMAN_ARMOR] = get_param_f(5)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "ARMOR", aArray[HUMAN_ARMOR])
	}

	if (!ini_read_int(ZE_FILENAME_HCLASS, szName, "SPEED_FACTOR", aArray[HUMAN_SPEED_FACTOR]))
	{
		aArray[HUMAN_SPEED_FACTOR] = get_param(6)
		ini_write_int(ZE_FILENAME_HCLASS, szName, "SPEED_FACTOR", aArray[HUMAN_SPEED_FACTOR])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "SPEED", aArray[HUMAN_SPEED]))
	{
		aArray[HUMAN_SPEED] = get_param_f(7)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "SPEED", aArray[HUMAN_SPEED])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "GRAVITY", aArray[HUMAN_GRAVITY]))
	{
		aArray[HUMAN_GRAVITY] = get_param_f(8)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "GRAVITY", aArray[HUMAN_GRAVITY])
	}

	new szModel[MAX_RESOURCE_PATH_LENGTH]

	// Precache Models.
	formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", aArray[HUMAN_MODEL], aArray[HUMAN_MODEL])
	precache_model(szModel)

	// Copy array on dyn Array.
	ArrayPushArray(g_aHumanClass, aArray)
	return ++g_iNumHumans - 1
}

public __native_hclass_get_current(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return ZE_CLASS_INVALID
	}

	return g_iCurrent[id]
}

public __native_hclass_get_next(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return ZE_CLASS_INVALID
	}

	return g_iNext[id]
}

public __native_hclass_is_valid(const plugin_id, const num_params)
{
	if (FIsWrongClass(get_param(1)))
		return false
	return true
}

public __native_hclass_get_name(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	set_string(2, aArray[HUMAN_NAME], get_param(3))
	return true
}

public __native_hclass_get_desc(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	set_string(2, aArray[HUMAN_DESC], get_param(3))
	return true
}

public __native_hclass_get_model(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	set_string(2, aArray[HUMAN_MODEL], get_param(3))
	return true
}

public Float:__native_hclass_get_health(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_HEALTH]
}

public Float:__native_hclass_get_armor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_ARMOR]
}

public __native_hclass_is_speed_factor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return ZE_CLASS_INVALID
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_SPEED_FACTOR]
}

public Float:__native_hclass_get_speed(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_SPEED]
}

public Float:__native_hclass_get_gravity(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_GRAVITY]
}

public __native_hclass_set_current(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new const i = get_param(2)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	g_iCurrent[id] = i

	if (get_param(3))
	{
		ze_set_user_zombie(id)
	}

	return true
}

public __native_hclass_set_next(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new const i = get_param(2)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	g_iNext[id] = i
	return true
}

public __native_hclass_set_name(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	get_string(2, aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_desc(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	get_string(2, aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_health(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_HEALTH] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_armor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_ARMOR] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_speed_factor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_SPEED_FACTOR] = get_param(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_speed(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_SPEED] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_gravity(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_GRAVITY] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_show_menu(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	show_Humans_Menu(id)
	return true
}