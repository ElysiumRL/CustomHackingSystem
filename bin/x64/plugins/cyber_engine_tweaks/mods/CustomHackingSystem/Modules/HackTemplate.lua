Template = {}
--TODO: Remake all tweakdb functions in redscript (this is going to be a pain)

--[[

	HackTemplate.lua - How to create a Hacking Minigame and it's programs ?
	you can check TweakDBUtils.lua (in the same folder) for all the functions used here

	What's is in this file ?
		- 2 fully custom programs 
		- 3 programs made by CDPR (Datamine_V1,Datamine_V2 and Datamine_V3 programs from Access Points)
		- 1 custom Hacking Minigame instance (that can host all of those programs) with different difficulties

	What do I need to do ?
		- Read. (or simply hover the functions if you have VSCode)

]]

function Template.Generate()

	local api = require("Modules/TweakDBUtils.lua")

	local customHackingType = api.CreateHackingMinigameCategory("Custom")
	local customRewardType = api.CreateProgramActionType("CustomRewards")

	--#region Program
	--In order to create your own custom program, you need the following :
	-- UI (ProgramActionUI)
	-- The TweakDBID key for your redscript Script you want to trigger (ProgramAction)
	-- The Program (Daemon,hack,minigame objective or whatever you want to call it) you're playing with it's buffer size (Program)
	local NUTSProgramUI = api.CreateProgramActionUI("NutsIcon",LocKey(4986),LocKey(45737),"UIIcon.nut_ring")
	local NUTSProgramAction = api.CreateProgramAction("Nuts",customRewardType,customHackingType,NUTSProgramUI,-10)
	local NUTSProgram = api.CreateProgram("Nuts",NUTSProgramAction,3)

	--#endregion
	--Since we are running on custom and borked instances of the hack minigame,you need to create programs for already existing programs
	--This also means you can create completly different behaviors from "normal" programs using redscript
	--warning (and note too): these are separate and completly new,custom programs that ONLY work in the custom hacking system, they won't be intefering with anything else (like Access Points)
	local datamineV1Program = api.CreateProgram("DatamineV1","MinigameAction.NetworkDataMineLootAll",3)
	local datamineV2Program = api.CreateProgram("DatamineV2","MinigameAction.NetworkDataMineLootAllAdvanced",4)
	local datamineV3Program = api.CreateProgram("DatamineV3","MinigameAction.NetworkDataMineLootAllMaster",6)

	--Once you have all your programs, you can add them into a table for your new hack minigame
	--The order matters : first program you add here will be displayed on top, 2nd on 2nd row etc...
	local myCustomPrograms =
	{
		datamineV1Program,
		datamineV2Program,
		datamineV3Program
	}
	local myMinigameWithMyPrograms = api.CreateHackingMinigame("MyMinigame",0.00,9,40,10,myCustomPrograms,{})

	--If you want to create different difficulties for your hacks, just create different minigames but with different programs
	--Here is an example from the VehicleSecurityRework mod (that is supposed to be a demo of the system)

	--local unlockVehiclehackingMinigameEasy = CustomHackingSystem.API.CreateHackingMinigame("UnlockVehicleEasy",0.00,5,-40,6,unlockVehicleHackEasy,{})
	--local unlockVehiclehackingMinigameMedium = CustomHackingSystem.API.CreateHackingMinigame("UnlockVehicleMedium",0.00,5,0,7,unlockVehicleHackMedium,{})
	--local unlockVehiclehackingMinigameHard = CustomHackingSystem.API.CreateHackingMinigame("UnlockVehicleHard",0.00,6,20,9,unlockVehicleHackHard,{})
	--local unlockVehiclehackingMinigameImpossible = CustomHackingSystem.API.CreateHackingMinigame("UnlockVehicleImpossible",0.00,9,40,12,unlockVehicleHackImpossible,{})



	--(Optional,it's not needed and generally overridden by the call for a new hack instance)
	--api.SetCurrentCustomMinigame(unlockVehiclehackingMinigameEasy)
end

return Template
