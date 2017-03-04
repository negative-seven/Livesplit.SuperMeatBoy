// Work in progress!

state("SuperMeatBoy")
{
	byte state : "SuperMeatBoy.exe", 0x2D5EA0, 0x8D4;
	byte world : "SuperMeatBoy.exe", 0x1B7CBC;
	byte notCutscene : "SuperMeatBoy.exe", 0x2D4C6C, 0x3A0;
}

init
{
	return true;
}

start
{
	return current.state == 13;
}

split
{
	return current.notCutscene == 0
	&& old.notCutscene == 1
	&& current.state == 0 
	&& current.world != 6; // Don't split after Dr. Fetus phase 1
}