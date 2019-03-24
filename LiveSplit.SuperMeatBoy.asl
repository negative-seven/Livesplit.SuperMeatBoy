state("SuperMeatBoy", "ogversion")
{
	byte uiState : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D4;
	byte playing : "SuperMeatBoy.exe", 0x1B6638;
	byte inSpecialLevel : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A4;
	byte levelBeaten : "SuperMeatBoy.exe", 0x2D54A0;
	byte levelTransition : "SuperMeatBoy.exe", 0x2D5EA8;
	byte notCutscene : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A0;
	byte exit : "SuperMeatBoy.exe", 0x2D54BC, 0x14;
	byte world : "SuperMeatBoy.exe", 0x1B7CBC;
	byte level : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D0;
	uint fetus : "SuperMeatBoy.exe", 0x2D64BC, 0x10C;
}

state ("SuperMeatBoy", "1.2.5")
{
	// currently unsupported
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
		&& current.world != 6 // Don't split after Dr. Fetus phase 1
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