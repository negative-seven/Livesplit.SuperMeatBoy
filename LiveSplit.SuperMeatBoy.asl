state("SuperMeatBoy", "ogversion")
{
	byte playing         : "SuperMeatBoy.exe", 0x1B6638;
	float ILTime         : "SuperMeatBoy.exe", 0x1B6A88;
	byte world           : "SuperMeatBoy.exe", 0x1B7CBC;
	byte notCutscene     : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A0;
	byte inSpecialLevel  : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A4;
	byte levelBeaten     : "SuperMeatBoy.exe", 0x2D54A0;
	byte exit            : "SuperMeatBoy.exe", 0x2D54BC, 0x14;
	int deathCount       : "SuperMeatBoy.exe", 0x2D55AC, 0x1c8c;
	byte level           : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D0;
	byte uiState         : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D4;
	byte levelTransition : "SuperMeatBoy.exe", 0x2D5EA8;
	uint fetus           : "SuperMeatBoy.exe", 0x2D64BC, 0x10C;
}

state ("SuperMeatBoy", "1.2.5")
{
	// Currently unsupported
}

startup
{
	settings.Add("menuReset", false, "Reset on main menu");
	settings.Add("individualLevels", false, "Split after each level");
	
	settings.Add("bossSplit", false, "Split when entering selected bosses");
	for (int world = 1; world <= 6; world++)
	{
		string name = String.Format("boss{0}Split", world);
		string description = String.Format("Split before boss {0}", world);
		settings.Add(name, false, description, "bossSplit");
	}
		
	settings.Add("deathDisp", false, "Death count display");
	
	settings.Add("ilDisp", false, "Last IL Time display");
	settings.SetToolTip("ilDisp", "Times are truncated to 3 places (The game shows times rounded to two)");
	
	settings.Add("createUI", true, "Create UI if needed");
}

init
{
	var mainModuleSize = modules.Where(m => m.ModuleName == "SuperMeatBoy.exe").First().ModuleMemorySize;
	
	switch (mainModuleSize)
	{
	case 0x342000:
		version = "ogversion";
		break;
	case 0x33c000:
		version = "1.2.5";
		MessageBox.Show(
			timer.Form,
			"This autosplitter does not support game version 1.2.5.\n" +
			"To switch to the supported \"ogversion\" on Steam, right click on Super Meat Boy in your library, select Properties, go to the Betas tab and choose \"ogversion\".\n" +
			"It is not possible to revert to this version on other platforms.",
			"Autosplitter: Unsupported game version",
			MessageBoxButtons.OK,
			MessageBoxIcon.Information
		);
		break;
	default:
		version = "unknown";
		MessageBox.Show(
			timer.Form,
			String.Format("Cannot determine the game version. Main module size: 0x{0:x}.", mainModuleSize),
			"Autosplitter: Unknown game version",
			MessageBoxButtons.OK,
			MessageBoxIcon.Error
		);
		break;
	}
	
	// LiveSplit display by @zment (from Defy Gravity auto-splitter)
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
	
	// Format and Display a given float value
	vars.DisplaySeconds = (Action<string, float>)((name, f) =>
	{
		int decimalPlaces = 3;
		
		// Convert float to string
		string s;
		s = f.ToString();
		
		// Find where the decimal place is, if at all
		int decimalLocation = -1;
		for (int i = 0; i < s.Length; i++)
		{
			if (s[i] == '.')
			{
				decimalLocation = i;
			}
		}
		
		// Add a decimal place, if absent (EG "5" -> "5.")
		if (decimalLocation == -1)
		{
			decimalLocation = s.Length;
			s += ".";
		}
		
		// Define length of final string
		int finalLength = decimalLocation + 1 + decimalPlaces;
		
		// Concatenate '0's to reach final length, if needed
		while (s.Length < finalLength )
		{
			s += '0';
		}		
		
		// Truncate
		string t = "";
		for (int i = 0; i < finalLength; i++)
		{
			t += s[i];
		}
		s = t;
		
		// Display final string
		vars.SetTextComponent(name, s, settings["createUI"]);
	});
	
	// Initialize death count
	if (settings["deathDisp"])
	{
		vars.SetTextComponent("Deaths", current.deathCount.ToString(), settings["createUI"]);
	}
	
	// Initialize IL display
	vars.DisplaySeconds("Last IL Time", 0f);
}

update
{
	// Update death count	
	if (
		settings["deathDisp"]
		&& current.deathCount != old.deathCount
	)
	{
		vars.SetTextComponent("Deaths", current.deathCount.ToString(), settings["createUI"]);
	}
	
	// Update IL display
	if (
		settings["ilDisp"]
		&& old.ILTime == 100000000 // ILTime stays at 100000000 while playing the level
		&& current.ILTime != 100000000 // When the level is completed, ILTime contains your... IL time lol
	)
	{
		vars.DisplaySeconds("Last IL Time", current.ILTime);
	}
}

start
{
	return current.uiState == 13; // State: pressed "Start Game"
}

split
{
	if (
		current.uiState == 0 // State: inside a level
		&& current.notCutscene == 0
		&& old.notCutscene == 1
		&& (current.world != 6 || settings["individualLevels"]) // Don't split after Dr. Fetus phase 1 (unless using IL splits)
		&& current.level == 99 // Inside a boss fight
	)
	{
		return true;
	}
	
	if (
		current.fetus == 0x80000000 // Split after Dr. Fetus phase 2
		&& old.fetus != 0x80000000
	)
	{
		return true;
	}
	
	if (settings["individualLevels"]) // "Split on each level" setting enabled
	{
		if (
			current.levelBeaten == 1
			&& old.levelBeaten == 0
		)
		{
			return true;
		}
		
		if (
			current.levelTransition == 1
			&& old.levelTransition == 0
			&& current.uiState == 0 // State: inside a level
			&& current.playing == 0
		)
		{
			return true;
		}
	}
	
	if (
		current.world >= 1
		&& current.world <= 6
		&& settings[String.Format("boss{0}Split", current.world)] // "Split on boss" setting enabled for current world
		&& current.uiState == 7 // State: entering a level
		&& current.inSpecialLevel == 1
		&& old.inSpecialLevel == 0
	)
	{
		return true;
	}
	
	return false;
}

reset
{
	if (current.exit == 1) // Exiting game (only works if exiting through "Exit Game")
	{
		return true;
	}
	
	if (current.uiState == 11) // State: on title screen
	{
		return true;
	}
	
	if (
		settings["menuReset"] // "Reset on main menu" setting enabled
		&& current.uiState == 15 // State: main menu
	)
	{
		return true;
	}
	
	return false;
}
