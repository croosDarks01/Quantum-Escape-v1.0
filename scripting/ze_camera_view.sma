#include <amxmodx>
#include <engine>

new bool:g_bEnabled[33]

public plugin_init()
{
    register_plugin("Camera Changer", "1.0", "XunTric")

    register_clcmd("say /cam", "setview")
    register_clcmd("say_team /cam", "setview")  
    register_native("ze_toggle_cam", "toggle_cam")
	
	arrayset(g_bEnabled, false, 32)
}

public plugin_precache()
{
    precache_model("models/rpgrocket.mdl")
}

public setview(id)
{
	if (g_bEnabled[id] == false)
	{
		set_view(id, CAMERA_3RDPERSON)
		g_bEnabled[id] = true
	}
	else
	{
		set_view(id, CAMERA_NONE)
		g_bEnabled[id] = false
	}
}

public toggle_cam(id)
{
	setview(id)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
