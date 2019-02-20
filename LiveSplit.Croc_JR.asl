/*
by: Thermospore

Only works with J2ME Wireless Toolkit.
Supported .jar resolutions: 176x208, 176x220

to-do:
-find automatic resolution detection
-add 128x128
-maybe find a less janky way to get to the uiState byte
*/

state("zayit") //j2me WTK
{
	//State of the user interface (decimal)
	byte uiState_208	: "zayit.dll", 0x317C00, 0xFFFFFB9C; //176x208 resolution
	byte uiState_220	: "zayit.dll", 0x317C00, 0xFFFFFBAC; //176x220 resolution
	/*
	 3 - pause menu
	 4 - gameplay
	 8 - purple dialog screen
	 9 - "LEVEL CLEAR" screen
	10 - game over
	11 - "KEYS" menu at start of game
	12 - level entrance/accept screen
	13 - language select
	*/
	
	byte lvlGems	: "zayit.dll", 0x40B12C, 0x18; //# gems collected in current level
	
	//respawn tile info. death abuse respawn locations.
	byte daMinusX	: "zayit.dll", 0x40B12C, 0x20; //-x axis. FE for bounceback
	byte daPlusX	: "zayit.dll", 0x40B12C, 0x21;

	//increases by one for each level beaten, including boss. range: 0 to 9
	byte vilProgB	: "zayit.dll", 0x40B12C, 0x25; //second village
	byte vilProgA	: "zayit.dll", 0x40B12C, 0x26; //first village
}

startup
{
	settings.Add("gemSplit", false, "Split on gems");
	settings.Add("dwDisp", false, "Death warp display");
	settings.Add("220", true, "[Resolution] Yes:220 | No:208");
	
	//liveSplit display by @zment (from Defy Gravity autosplitter)
	vars.SetTextComponent = (Action<string, string, bool>)((id, text, create) =>
	{
		var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
		var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
		if (textSetting == null && create)
		{
			var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
			var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
			timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

			textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
			textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
		}

		if (textSetting != null)
			textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
	});
}

init
{
	//initialize DW coordinate display
	vars.daCoords_old = "?";
	vars.daCoords = "?";
	if (settings["dwDisp"])
	{
		vars.SetTextComponent("DW Coords [old]", vars.daCoords_old, true);
		vars.SetTextComponent("DW Coords [cur]", vars.daCoords, true);
	}
}

start
{
	if (settings["220"])
	{
		if (old.uiState_220 == 3 && current.uiState_220 == 11)
		{return true;}
	}
	else
	{
		if (old.uiState_208 == 3 && current.uiState_208 == 11)
		{return true;}
	}	
}

update
{
	//DW Display
	if (settings["dwDisp"] && ((current.uiState_208 == 4) || (current.uiState_220 == 4)))
	{
		if ((current.daMinusX != old.daMinusX) ||
		(current.daPlusX  != old.daPlusX) ||
		(vars.daCoords == "?"))
		{
			vars.daCoords_old = vars.daCoords;
			
			if (current.daMinusX == 0xFE)
			{
				vars.daCoords = "Behind";
			}
			else
			{
				vars.daCoords = "(" + current.daMinusX.ToString() + "," + current.daPlusX.ToString() +")";
			}
			
			vars.SetTextComponent("DW Coords [old]", vars.daCoords_old, true);
			vars.SetTextComponent("DW Coords [cur]", vars.daCoords, true);
		}
	}
}

split
{	
	if //split when level is beaten, except on last level where we will split on purple textbox
	( 
		(current.vilProgA == old.vilProgA + 1) ||
		((current.vilProgB == old.vilProgB + 1) && (current.vilProgB < 9))
	)
	{return true;}
	
	if (settings["220"]) //split on king dialog 
	{
		if
		(
			current.vilProgB == 9 && current.vilProgA == 9 &&
			old.uiState_220 == 4 && current.uiState_220 == 8
		)
		{return true;}
	}
	else
	{
		if 
		(
			current.vilProgB == 9 && current.vilProgA == 9 &&
			old.uiState_208 == 4 && current.uiState_208 == 8
		)
		{return true;}
	}
	
	if (settings["gemSplit"]) //split when grabbing gem (for Hubred%[sic])
	{
		if (current.lvlGems == old.lvlGems + 1)
		{return true;}
	}
}