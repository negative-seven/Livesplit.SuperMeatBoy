state("SuperMeatBoy")
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