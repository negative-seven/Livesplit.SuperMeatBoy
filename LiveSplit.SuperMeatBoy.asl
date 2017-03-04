state("SuperMeatBoy")
{
	byte uiState : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D4;
	byte notCutscene : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A0;
	byte world : "SuperMeatBoy.exe", 0x1B7CBC;
	uint fetus : "SuperMeatBoy.exe", 0x2D64BC, 0x10C;
}

start
{
	return current.uiState == 13; // Pressed "Start Game"
}

split
{
	return
	(current.notCutscene == 0
	&& old.notCutscene == 1
	&& current.uiState == 0 // Inside a level
	&& current.world != 6) // Don't split after Dr. Fetus phase 1
	||
	(current.fetus == 0x80000000 // Split after Dr. Fetus phase 2 (slightly hacky but working solution)
	&& old.fetus != 0x80000000);
}

reset
{
	return current.uiState == 11; // On title screen
}