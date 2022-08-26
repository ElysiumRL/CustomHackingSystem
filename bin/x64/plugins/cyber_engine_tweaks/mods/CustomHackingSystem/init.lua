CustomHackingSystem = {
    description = "CustomHackingSystem",
}

function CustomHackingSystem:new()

	CustomHackingSystem.API = require("Modules/TweakDBUtils.lua")

	registerForEvent("onInit", function()
	--#region Security
		if CustomHackingSystem:IsHackingSystemInstalled() == false then
			print("[CustomHackingSystem] Error : ###########")
			print("[CustomHackingSystem] Error : Redscript files for the mod not found")
			print("[CustomHackingSystem] Error : Either Redscript is not installed, or the mod is not properly installed")
			print("[CustomHackingSystem] Error : ###########")
		end

	--#region Params
		local addTemplateToGame = false
	--#endregion

	--#region Template
		if addTemplateToGame then
			local Template = require("Modules/HackTemplate.lua")
			Template.Generate()
			print("[Custom Hacking System] Template Generated!")
		end
	--#endregion
	end)
	return CustomHackingSystem
end

--- Returns true if the CustomHackingSystem Scriptable System is found (i.e : redscript files are found)
---@return boolean
function CustomHackingSystem:IsHackingSystemInstalled()
	local container = Game.GetScriptableSystemsContainer()
	local system = container:Get("HackingExtensions.CustomHackingSystem")
	return system ~= nil
end

return CustomHackingSystem:new()