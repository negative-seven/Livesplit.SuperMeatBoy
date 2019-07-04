// ---------------Credits--------------
//            -7: creator
//   Thermospore: displays, DE splits
//        zment4: display framework
//      6DPSMETA: IW splits
//         rJade: suggestions, bug reports
// SMB community: feedback, bug reports
// ------------------------------------

state("SuperMeatBoy", "ogversion")
{
	byte playing         : "SuperMeatBoy.exe", 0x1b6638;
	float ILTime         : "SuperMeatBoy.exe", 0x1b6a88;
	byte world           : "SuperMeatBoy.exe", 0x1b7cbc;
	byte notCutscene     : "SuperMeatBoy.exe", 0x2d4c6c, 0x3a0;
	byte inSpecialLevel  : "SuperMeatBoy.exe", 0x2d4c6c, 0x3a4;
	byte levelBeaten     : "SuperMeatBoy.exe", 0x2d54a0;
	byte exit            : "SuperMeatBoy.exe", 0x2d54bc, 0x14;
	byte fetusType       : "SuperMeatBoy.exe", 0x2d54bc, 0x2d2;
	int deathCount       : "SuperMeatBoy.exe", 0x2d55ac, 0x1c8c;
	int characters       : "SuperMeatBoy.exe", 0x2d55ac, 0x1d24;
	byte level           : "SuperMeatBoy.exe", 0x2d5ea0, 0x8d0;
	byte uiState         : "SuperMeatBoy.exe", 0x2d5ea0, 0x8d4;
	byte levelTransition : "SuperMeatBoy.exe", 0x2d5ea8;
	uint fetus           : "SuperMeatBoy.exe", 0x2d64bc, 0x10c;
}

state ("SuperMeatBoy", "1.2.5")
{
	// Currently unsupported
}

startup
{
	settings.Add("menuReset", false, "Reset on main menu");
	
	settings.Add("ilSplit", false, "Split after every level");
	
	settings.Add("iwSplit", false, "IW start & end split");
	settings.Add("iwSplit_FirstLvl", true, "Only start on first level of world", "iwSplit");
	
	settings.Add("deSplit", false, "Dark Ending mode");
	settings.SetToolTip("deSplit", "Splits when boss unlocks for ch1-5 and disables light fetus split. \nYou don't need to enable this if you are already splitting on every level");
	
	settings.Add("bossSplit", false, "Split when entering selected bosses");
	for (int world = 1; world <= 6; world++)
	{
		string name = String.Format("boss{0}Split", world);
		string description = String.Format("Boss {0}", world);
		settings.Add(name, false, description, "bossSplit");
	}
	
	settings.Add("deathDisp", false, "Death count display");
	settings.Add("deathDisp_Pause", true, "Pause death count when run ends", "deathDisp");
	settings.SetToolTip("deathDisp_Pause", "Prevents post-run deaths from getting into your death count (ex: Escape deaths during credits).\nDeath counting resumes when the timer is reset");
	
	settings.Add("ilDisp", false, "Last IL Time display");
	settings.SetToolTip("ilDisp", "Times are truncated to 3 places (The game shows times rounded to two)");
	
	
	
	// LiveSplit display by @zment (from Defy Gravity auto-splitter)
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
		var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
		var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
		if (textSetting == null)
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
	
	// Code to execute on startup
	vars.timer_OnStart = (EventHandler)((s, e) =>
	{
		// Set death count normalization on timer start
		if (settings["deathDisp"])
		{
			vars.deathCountOffset = old.deathCount;
			vars.SetTextComponent("Deaths", (current.deathCount - vars.deathCountOffset).ToString());
		}
	});
	timer.OnStart += vars.timer_OnStart;
	
	// Initialize death count
	if (settings["deathDisp"])
	{
		vars.SetTextComponent("Deaths", current.deathCount.ToString());
		vars.deathCountOffset = 0; // Used to store death count on timer start, for normalization
	}
	
	// Initialize IL display
	if (settings["ilDisp"])
	{
		vars.SetTextComponent("Last IL Time", "[none]");
	}
}

shutdown // Autosplitter close
{
	// Unsubscribe startup event for death count normalization
	timer.OnStart -= vars.timer_OnStart;
}

exit // Game close
{
	// Clear death count on game close
	if (settings["deathDisp"])
	{
		vars.SetTextComponent("Deaths", "-");
		vars.deathCountOffset = 0; // Reset normalization
	}
	
	// Clear Last IL Time on game close
	if (settings["ilDisp"])
	{
		vars.SetTextComponent("Last IL Time", "-");
	}
}

update
{
	// Disable script on invalid/unsupported game version
	if (version != "ogversion")
	{
		return false;
	}
	
	// uiState debug output
	// if (old.uiState != current.uiState) {print("uiState: " + old.uiState.ToString() + "->" + current.uiState.ToString());}
	
	// Update death count	
	if (
		settings["deathDisp"]
		&& current.deathCount > old.deathCount
		&& (
			timer.CurrentPhase != TimerPhase.Ended // The run must not be finished
			|| !settings["deathDisp_Pause"]        // Or the setting must be disabled
		)
		
	)
	{
		vars.SetTextComponent("Deaths", (current.deathCount - vars.deathCountOffset).ToString());
	}
	
	// Update IL display
	if (
		settings["ilDisp"]
		&& old.ILTime == 100000000 // ILTime stays at 100000000 while playing the level
		&& current.ILTime != 100000000 // When the level is completed, ILTime contains your... IL time lol
	)
	{
		if (current.ILTime == 0f)
		{
			vars.SetTextComponent("Last IL Time", "[timer glitch]");
		}
		else
		{
			vars.SetTextComponent("Last IL Time", String.Format("{0:0.000}", current.ILTime));
		}
	}
	
	return true;
}

start
{
	// Fullgame start
	if (
		!settings["iwSplit"]
		&& current.uiState == 13 // State: pressed "Start Game"
	) 
	{
		return true;
	}
	
	// IW start
	if (
		settings["iwSplit"]
		&& (
			( // Case: Character select screen is unlocked
				current.characters != 1 // Characters other than meatboy are unlocked
				&& old.uiState == 4 // State: in character select
				&& current.uiState == 5 // State: entering level through character select
			)
			|| ( // Case: No character select screen
				( 
					current.characters == 1 // Only meatboy is unlocked
					|| ( // Exception: if you are on End or Cotton other characters can be unlocked
						current.world >= 6 
						&& current.world <= 7
					)
				)
				&& current.uiState == 7 // State: entering level in world map
				&& old.uiState == 1 // State: in world map
			)
		)
		&& ( // Require being on first level of world for IW start, unless the option is off
			current.level == 0
			|| !settings["iwSplit_FirstLvl"]
		)
	)
	{
		return true;
	}
	
	return false;
}

split
{
	// Boss completion splits
	if (
		current.uiState == 0 // State: inside a level
		&& current.notCutscene == 0
		&& old.notCutscene == 1
		&& (current.world != 6 || settings["ilSplit"]) // Don't split after Dr. Fetus phase 1 (unless using IL splits)
		&& current.level == 99 // Inside a boss fight
	)
	{
		return true;
	}
	
	// Final cutscene splits
	if (
		current.fetus == 0x80000000 // Split after Dr. Fetus phase 2
		&& old.fetus != 0x80000000
		&& (
			!( // Do not split on light fetus when Dark Ending splits are enabled
				current.fetusType == 0
				&& settings["deSplit"]
			)
			|| settings["ilSplit"] // ...Unless you have IL splits enabled
		)
	)
	{
		return true;
	}
	
	// IL splits
	if (settings["ilSplit"]) // "Split on each level" setting enabled
	{
		// When continuing to next level
		if (
			current.levelBeaten == 1
			&& old.levelBeaten == 0
		)
		{
			return true;
		}
		
		// When using keyboard "S" to exit to map
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
	
	// Boss entrance splits
	if (
		current.world >= 1
		&& current.world <= 6
		&& settings[String.Format("boss{0}Split", current.world)] // "Split on boss" setting enabled for current world
		&& current.uiState == 7 // State: entering level in world map
		&& current.inSpecialLevel == 1
		&& old.inSpecialLevel == 0
	)
	{
		return true;
	}

	// IW ending split
	if (
		settings["iwSplit"]
		&& (
			(
				current.world == 6
				&& current.level == 4 // Be in either last level of The End or...
			)
			|| current.level == 19 // Last level of any other world.
		)
		&& old.playing == 1 // Ensures you were playing a level
		&& old.ILTime == 100000000 // Changes to IL time upon level completion
		&& current.ILTime != 100000000
	)
	{
		return true;
	}
	
	// Dark Ending splits
	if (
		settings["deSplit"]
		&& !settings["ilSplit"] // IL splits make this redundant
		&& old.uiState == 0 // State: inside a level
		&& current.uiState == 22 // State: boss unlocking on world map
		&& current.world >= 1
		&& current.world <= 5
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
