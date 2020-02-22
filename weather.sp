#include <sdktools>
#include <sdkhooks>

char
	g_sWeather[3],
	g_sDensity[3],
	g_sAmount[3];
	
ConVar
	cvWeather,
	cvDensity,
	cvAmount;
	
float
	vMins[3],
	vMaxs[3],
	m_vecOrigin[3];
	
public OnPluginStart()
{
	cvWeather = CreateConVar("weather_default", "3", "Default Precipitation");
	cvWeather.GetString(g_sWeather, sizeof(g_sWeather));
	
	cvDensity = CreateConVar("weather_density", "0", "Density of Precipitation");
	cvDensity.GetString(g_sDensity, sizeof(g_sDensity));
	
	cvAmount = CreateConVar("weather_amount", "0", "Amount of Precipitation");
	cvAmount.GetString(g_sAmount, sizeof(g_sAmount));
	
	// hooking cvar changes
	cvWeather.AddChangeHook(OnCvarChanged);
	cvDensity.AddChangeHook(OnCvarChanged);
	cvAmount.AddChangeHook(OnCvarChanged);
	
	RegAdminCmd("sm_weather", Admin_SetWeather, ADMFLAG_GENERIC);
}

// called when a cvar is changed
public int OnCvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	// updating cvar values when they change
	if (cvar == cvWeather)
		cvWeather.GetString(g_sWeather, sizeof(g_sWeather));
		
	if (cvar == cvDensity)
		cvDensity.GetString(g_sDensity, sizeof(g_sDensity));
		
	if (cvar == cvAmount)
		cvAmount.GetString(g_sAmount, sizeof(g_sAmount));
		
	UpdateWeather();
}

public void OnMapStart() {
	// char sRandom[][] = {"0", "1", "3", "6"};
	// Format(g_sWeather, sizeof(g_sWeather), sRandom[GetRandomInt(0, sizeof(sRandom))]);
	
	GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	
	while (TR_PointOutsideWorld(vMins)) 
	{
		vMins[0]++;
		vMins[1]++;
		vMins[2]++;
	}
		
	while (TR_PointOutsideWorld(vMaxs)) 
	{
		vMaxs[0]--;
		vMaxs[1]--;
		vMaxs[2]--;
	}
	
	m_vecOrigin[0] = (vMins[0] + vMaxs[0]) / 2;
	m_vecOrigin[1] = (vMins[1] + vMaxs[1]) / 2;
	m_vecOrigin[2] = (vMins[2] + vMaxs[2]) / 2;
	
	UpdateWeather();
}

public Action Admin_SetWeather(iClient, Args)
{
	if (!IsValidClient(iClient))
		return;
		
	Handle hMenu = CreateMenu(Admin_SetWeather_Callback);
	SetMenuTitle(hMenu, "Weather\n \n");
	AddMenuItem(hMenu, "0", "None");
	AddMenuItem(hMenu, "1", "Heavy Rain");
	AddMenuItem(hMenu, "3", "Snow");
	AddMenuItem(hMenu, "6", "Light Rain");
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int Admin_SetWeather_Callback(Handle hMenu, MenuAction maAction, int iClient, int iArgs)
{
	if (maAction == MenuAction_End)
		CloseHandle(hMenu);
		
	else if (maAction == MenuAction_Select)
	{
		int iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "func_precipitation")) != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iEntity, "Kill");
			
		if (iArgs != 0)
		{
			char sType[2];
			GetMenuItem(hMenu, iArgs, sType, sizeof(sType));
			
			Format(g_sWeather, sizeof(g_sWeather), sType);
			UpdateWeather();
		}
	}
}

stock void UpdateWeather()
{
	int iValue;
	int iEntity = -1;
	
	while ((iEntity = FindEntityByClassname(iEntity, "func_precipitation")) != INVALID_ENT_REFERENCE)
	{
		iValue = GetEntProp(iEntity, Prop_Data, "m_nPrecipType");
		if (iValue < 0 || iValue == 4 || iValue > 5)
			AcceptEntityInput(iEntity, "Kill");
	}
	
	iEntity = CreateEntityByName("func_precipitation");
	if (iEntity != -1)
	{
		char sBuffer[128];
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		Format(sBuffer, sizeof(sBuffer), "maps/%s.bsp", sBuffer);
		
		DispatchKeyValue(iEntity, "model", sBuffer);
		DispatchKeyValue(iEntity, "targetname", "silver_rain");
		DispatchKeyValue(iEntity, "preciptype", g_sWeather);
		DispatchKeyValue(iEntity, "density", g_sDensity);
		DispatchKeyValue(iEntity, "renderamt", g_sAmount);
		DispatchKeyValue(iEntity, "minSpeed", "25");
		DispatchKeyValue(iEntity, "maxSpeed", "35");
		
		SetEntPropVector(iEntity, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vMaxs);
		
		DispatchSpawn(iEntity);
		ActivateEntity(iEntity);
		
		TeleportEntity(iEntity, m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	
	else
		LogError("Failed to create 'func_precipitation'");
}

stock bool IsValidClient(int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

public Plugin myinfo =
{
	name		= 	"Titan 2 - Weather",
	author	  	= 	"myst",
	version	 	= 	"2.0",
};