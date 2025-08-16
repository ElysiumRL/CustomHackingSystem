--TODO: TweakDB functions into redscript

--TODO: params for quickhacks

--TODO: classes for quickhack params (to make it a bit easier to write actual quickhacks)

API = {}

--#region Classic Hacks

---@param minigameName string Name of the new TweakDB Record minigame
---@param defaultTimeLimit Float Overrides hack time limit
---@param gridSize Float Size of the playing grid (minimum : 4)
---@param extraDifficulty Float Hacking Difficulty,usually between -20 and +40 or more (Default : 0)
---@param bufferSize userdata|TweakDBID Number of maximum allowed inputs
---@param programsToAdd userdata|table TweakDB record paths
---@return string String 
function API.CreateHackingMinigame(minigameName,defaultTimeLimit,gridSize,extraDifficulty,bufferSize,programsToAdd)
	minigameName = "CustomHackingSystemMinigame."..minigameName
	if TweakDB:GetRecord(minigameName) == nil then
		TweakDB:CloneRecord(minigameName,"minigame_v2.DefaultMinigame")
	end
	TweakDB:SetFlat(minigameName..".timeLimit",defaultTimeLimit)
	TweakDB:SetFlat(minigameName..".gridSize",gridSize)
	TweakDB:SetFlat(minigameName..".extraDifficulty",extraDifficulty)
	TweakDB:SetFlat(minigameName..".bufferSize",bufferSize)

	TweakDB:SetFlat(minigameName..".overrideProgramsList",programsToAdd)
	TweakDB:SetFlat(minigameName..".forbiddenProgramsList",{})
    return minigameName;
end

---@param minigameCategoryName String Name of the Minigame Category
---@return string ReturnValue TweakDB String record path of that new category
function API.CreateHackingMinigameCategory(minigameCategoryName)
	local minigameRecordCategoryName = "MinigameCategory."..minigameCategoryName

	if TweakDB:GetRecord(minigameRecordCategoryName) == nil then
		TweakDB:CreateRecord(minigameRecordCategoryName, "gamedataMinigameCategory_Record")
	end

	TweakDB:SetFlat(minigameRecordCategoryName..".enumName",minigameCategoryName)

	return minigameRecordCategoryName
end

---@param programTypeName String Name of the Program Action Type
---@return string ReturnValue TweakDB String record path of that new action type
function API.CreateProgramActionType(programTypeName)
	local minigameActionTypeName = "MinigameActionType."..programTypeName
	if TweakDB:GetRecord(minigameActionTypeName) == nil then
		TweakDB:CreateRecord(minigameActionTypeName, "gamedataMinigameActionType_Record")
	end
	TweakDB:SetFlat(minigameActionTypeName..".enumName",programTypeName)
	return minigameActionTypeName
end

---@return string ReturnValue TweakDB Record Path of the new program
function API.CreateProgram(programName,programAction_recordPath,bufferSize)
	bufferSize = math.max(bufferSize,1) or 4

	programName = "MinigameProgram."..programName

	if TweakDB:GetRecord(programName) == nil then
		TweakDB:CloneRecord(programName,"minigame_v2.DefaultItemMinigame_inline0")
	end

	TweakDB:SetFlat(programName..".program",programAction_recordPath)

	local bufferTable = {}
	for i = 1, bufferSize do
		bufferTable[i] = -1
	end
	TweakDB:SetFlat(programName..".charactersChain",bufferTable)

	return programName
end

function API.CreateProgramAction(programName,programActionType,minigameCategory,programActionUI,difficulty)
	difficulty = difficulty or 0

	programName = "MinigameProgramAction."..programName

	if TweakDB:GetRecord(programName) == nil then
		TweakDB:CloneRecord(programName,"MinigameAction.NetworkDataMineLootAllMaster")
	end

	TweakDB:SetFlat(programName..".type",programActionType)
	TweakDB:SetFlat(programName..".category",minigameCategory)
	TweakDB:SetFlat(programName..".objectActionUI",programActionUI)
	TweakDB:SetFlat(programName..".complexity",difficulty)
	TweakDB:SetFlat(programName..".rewards",{"RPGActionRewards.Hacking"})

	return programName
end

function API.CreateProgramActionUI(actionUIName,caption_LocKey,description_LocKey,icon_TDBID)
	local defaultUIName = actionUIName
	actionUIName = "MinigameProgramActionUI."..actionUIName

	if TweakDB:GetRecord(actionUIName) == nil then
		TweakDB:CloneRecord(actionUIName,"Interactions.NetworkGainAccessProgram")
	end

	TweakDB:SetFlat(actionUIName..".caption",caption_LocKey)

	local captionIcon = "UICaptionIcon."..defaultUIName

	if TweakDB:GetRecord(captionIcon) == nil then
		TweakDB:CreateRecord(captionIcon,"gamedataChoiceCaptionIconPart_Record")
	end

	TweakDB:SetFlat(captionIcon..".mappinVariant","Mappins.InvalidVariant")
	TweakDB:SetFlat(captionIcon..".partType","ChoiceCaptionPartType.Icon")
	TweakDB:SetFlat(captionIcon..".texturePartID",icon_TDBID)
	TweakDB:SetFlat(captionIcon..".enumName",CName.new(defaultUIName))

	TweakDB:SetFlat(actionUIName..".captionIcon",captionIcon)
	TweakDB:SetFlat(actionUIName..".description",description_LocKey)
	TweakDB:SetFlat(actionUIName..".name",defaultUIName)
	return actionUIName

end

function API.CreateUIIcon(partName,atlasPath)
	local iconPath = "CustomUIIcon."..partName

	if TweakDB:GetRecord(iconPath) == nil then
		TweakDB:CreateRecord(iconPath,"gamedataUIIcon_Record")
	end
	TweakDB:SetFlat(iconPath..".atlasPartName",CName.new(partName))
	TweakDB:SetFlat(iconPath..".atlasResourcePath",atlasPath)
	return iconPath;
end

--#endregion

--#region Quickhacks

function API.CreateRemoteBreachQuickhack(quickhackName,gameplayCategory,quickhackInteractionBaseUI,cost,cooldownTime)
	local deviceActionRecordName = "DeviceAction."..quickhackName

	if TweakDB:GetRecord(deviceActionRecordName) == nil then
		TweakDB:CloneRecord(deviceActionRecordName,"DeviceAction.RemoteBreach")
	end

	local quickhackPath = deviceActionRecordName

	--local quickhackCostPath = Quickhack.CreateQuickhackMemoryStatModifier(quickhackName,"CostValue","Additive",cost)

	local quickhackCostStatPoolPath = quickhackPath.."Cost"

	if TweakDB:GetRecord(quickhackCostStatPoolPath) == nil then
		TweakDB:CloneRecord(quickhackCostStatPoolPath,"DeviceAction.DeviceQuickHack_inline1")
	end


	TweakDB:SetFlat(quickhackCostStatPoolPath..".costMods",
	{
		"QuickHack.MemoryCostReductionMod",
		"QuickHack.TargetResistance",
		"QuickHack.ConsumableCostReduction",
		"QuickHack.DeviceMemoryCostReductionMod",
		cost
	})

	--5th element in the array corresponds to the mem real cost, others are memory reduction & target resistance (or whatever that means)
	TweakDB:SetFlat(quickhackPath..".actionName",quickhackName)
	TweakDB:SetFlat(quickhackPath..".costs",	{quickhackCostStatPoolPath})
	--TweakDB:SetFlat(quickhackPath..".gameplayCategory",gameplayCategory)
	TweakDB:SetFlat(quickhackPath..".objectActionUI",quickhackInteractionBaseUI)
	TweakDB:SetFlat(quickhackPath..".rewards",{"RPGActionRewards.CombatHacking"})
	TweakDB:SetFlat(quickhackPath..".targetActivePrereqs",{})
	TweakDB:SetFlat(quickhackPath..".instigatorPrereqs",{})


	if cooldownTime ~= 0.0 then
		local cooldown = API.CreateCooldown(quickhackName,cooldownTime,"RemoteBreach",LocKey(14985))
		TweakDB:SetFlat(quickhackPath..".startEffects",
		{
			"QuickHack.QuickHack_inline12",
			"QuickHack.QuickHack_inline13",
			cooldown.ObjectAction
		}

	)
	local cooldownPrereq = API.CreateCooldownPrereq(cooldown.ObjectAction,cooldown.StatusEffect)
		TweakDB:SetFlat(quickhackPath..".instigatorPrereqs",{ cooldownPrereq})
	else
		TweakDB:SetFlat(quickhackPath..".startEffects",
		{
			"QuickHack.QuickHack_inline12",
			"QuickHack.QuickHack_inline13"
		})

	end


	return quickhackPath
end

function API.CreateCooldown(quickhackName,cooldownTime,uiIconPartName,cooldownDescription_LocKey)
	local quickhackObjectActionEffect = "DeviceAction."..quickhackName.."_CooldownActionEffect"

	if TweakDB:GetRecord(quickhackObjectActionEffect) == nil then
		TweakDB:CloneRecord(quickhackObjectActionEffect,"DeviceAction.RemoteBreach_inline1")
	end

	local durationStatusEffect = "DeviceAction."..quickhackName.."_CooldownStatusEffect"

	if TweakDB:GetRecord(durationStatusEffect) == nil then
		TweakDB:CloneRecord(durationStatusEffect,"BaseStatusEffect.RemoteBreachCooldown")
	end

	local durationStatModifierGroup = "DeviceAction."..quickhackName.."_CooldownDurationModifierGroup"

	if TweakDB:GetRecord(durationStatModifierGroup) == nil then
		TweakDB:CloneRecord(durationStatModifierGroup,"BaseStatusEffect.RemoteBreachCooldown_inline0")
	end

	local durationUIData = "DeviceAction."..quickhackName.."_CooldownUIData"

	if TweakDB:GetRecord(durationUIData) == nil then
		TweakDB:CloneRecord(durationUIData,"BaseStatusEffect.RemoteBreachCooldown_inline2")
	end

	TweakDB:SetFlat(durationUIData..".displayName",cooldownDescription_LocKey)
	TweakDB:SetFlat(durationUIData..".iconPath",uiIconPartName)

	TweakDB:SetFlat(durationStatusEffect..".uiData",durationUIData)

	local durationModifier = API.CreateQuickhackMaxDurationModifier(quickhackName,"MaxCooldown","Additive",cooldownTime)

	TweakDB:SetFlat(durationStatModifierGroup..".statModifiers",
	{
		"BaseStatusEffect.QuickHackCooldownDuration_inline0",
		durationModifier
	})
	TweakDB:SetFlat(durationStatusEffect..".duration",durationStatModifierGroup)
	TweakDB:SetFlat(quickhackObjectActionEffect..".statusEffect",durationStatusEffect)
	return
	{
		ObjectAction = quickhackObjectActionEffect,
		StatusEffect = durationStatusEffect
	}

end

function API.CreateCooldownPrereq(cooldownObjectAction,cooldownStatusEffect)
	local cooldownPath = cooldownObjectAction.."_Prereq"
	if TweakDB:GetRecord(cooldownPath) == nil then
		TweakDB:CloneRecord(cooldownPath,"DeviceAction.RemoteBreach_inline0")
	end
	TweakDB:SetFlat(cooldownPath..".statusEffect",cooldownStatusEffect)
	return cooldownPath
end

function API.CreateQuickhack(quickhackName,gameplayCategory,quickhackInteractionBaseUI,cost,cooldownTime,baseUploadTime)
	local quickhackPath = "DeviceAction."..quickhackName
	if TweakDB:GetRecord(quickhackPath) == nil then
		TweakDB:CloneRecord(quickhackPath,"DeviceAction.PingDevice")
	end
	local quickhackCostStatPoolPath = quickhackPath.."Cost"

	--local quickhackCostPath = API.CreateQuickhackMemoryStatModifier(quickhackName,"CostValue","Additive",cost)
	if TweakDB:GetRecord(quickhackCostStatPoolPath) == nil then
		TweakDB:CloneRecord(quickhackCostStatPoolPath,"DeviceAction.DeviceQuickHack_inline1")
	end

	if baseUploadTime ~= 0.0 then
		local uploadTime = API.CreateQuickhackUploadTimeModifier(quickhackName,"UploadTime","Additive",baseUploadTime)
		TweakDB:SetFlat(quickhackPath..".activationTime",
		{
		"QuickHack.QuickHack_inline0",
		"QuickHack.QuickHack_inline1",
		"QuickHack.QuickHack_inline2",
		"DeviceAction.DeviceQuickHack_inline0",
		uploadTime
		})
	end


	TweakDB:SetFlat(quickhackCostStatPoolPath..".costMods",
	{
		"QuickHack.MemoryCostReductionMod",
		"QuickHack.TargetResistance",
		"QuickHack.ConsumableCostReduction",
		"QuickHack.DeviceMemoryCostReductionMod",
		cost
	})

	--5th element in the array corresponds to the mem real cost, others are memory reduction & target resistance (or whatever that means)
	TweakDB:SetFlat(quickhackPath..".actionName",quickhackName)
	TweakDB:SetFlat(quickhackPath..".costs",	{quickhackCostStatPoolPath})
	--TweakDB:SetFlat(quickhackPath..".gameplayCategory",gameplayCategory)
	TweakDB:SetFlat(quickhackPath..".objectActionUI",quickhackInteractionBaseUI)
	TweakDB:SetFlat(quickhackPath..".targetActivePrereqs",{})

	if cooldownTime ~= 0.0 then
		local cooldown = API.CreateCooldown(quickhackName,cooldownTime,"RemoteBreach",LocKey(14985))
		TweakDB:SetFlat(quickhackPath..".startEffects",
		{
			"QuickHack.QuickHack_inline12",
			"QuickHack.QuickHack_inline13",
			cooldown.ObjectAction
		})

		local cooldownPrereq = API.CreateCooldownPrereq(cooldown.ObjectAction,cooldown.StatusEffect)
		TweakDB:SetFlat(quickhackPath..".instigatorPrereqs",
		{
			"QuickHack.QuickHack_inline3",
			cooldownPrereq
		})
	else
		TweakDB:SetFlat(quickhackPath..".startEffects",
		{
			"QuickHack.QuickHack_inline12",
			"QuickHack.QuickHack_inline13"
		})

	end

	return quickhackPath
end

---@param quickhackName String
---@param modifierName String
---@param statModifierType String
---@param value Float
function API.CreateQuickhackMemoryStatModifier(quickhackName,modifierName,statModifierType,value)
	local statModifierPath = "DeviceAction."..quickhackName.."_"..modifierName

	if TweakDB:GetRecord(statModifierPath) == nil then
		TweakDB:CreateRecord(statModifierPath,"gamedataConstantStatModifier_Record")
	end

	TweakDB:SetFlat(statModifierPath..".modifierType",statModifierType)
	TweakDB:SetFlat(statModifierPath..".statType","BaseStats.Memory")
	TweakDB:SetFlat(statModifierPath..".value",value)
	return statModifierPath
end

---@param quickhackName String
---@param modifierName String
---@param statModifierType String
---@param value Float
function API.CreateQuickhackMaxDurationModifier(quickhackName,modifierName,statModifierType,value)
	local statModifierPath = "DeviceAction."..quickhackName.."_"..modifierName

	if TweakDB:GetRecord(statModifierPath) == nil then
		TweakDB:CreateRecord(statModifierPath,"gamedataConstantStatModifier_Record")
	end

	TweakDB:SetFlat(statModifierPath..".modifierType",statModifierType)
	TweakDB:SetFlat(statModifierPath..".statType","BaseStats.MaxDuration")
	TweakDB:SetFlat(statModifierPath..".value",value)
	return statModifierPath
end

---@param quickhackName String
---@param modifierName String
---@param statModifierType String
---@param value Float
function API.CreateQuickhackUploadTimeModifier(quickhackName,modifierName,statModifierType,value)
	local statModifierPath = "DeviceAction."..quickhackName.."_"..modifierName

	if TweakDB:GetRecord(statModifierPath) == nil then
		TweakDB:CreateRecord(statModifierPath,"gamedataConstantStatModifier_Record")
	end
	TweakDB:SetFlat(statModifierPath..".modifierType",statModifierType)
	TweakDB:SetFlat(statModifierPath..".statType","BaseStats.QuickHackUpload")
	TweakDB:SetFlat(statModifierPath..".value",value)
	return statModifierPath
end



function API.CreateQuickhackGameplayCategory(categoryName,uiIcon,descriptionLocKey,nameLocKey)
	local categoryPath = "ActionCategories."..categoryName

	if TweakDB:GetRecord(categoryPath) == nil then
		TweakDB:CloneRecord(categoryPath,"ActionCategories.Ping")
	end

	TweakDB:SetFlat(categoryPath..".friendlyName",categoryName)
	TweakDB:SetFlat(categoryPath..".iconRecord",uiIcon)
	local iconNameSplit = Split(uiIcon,".")
	local iconName = iconNameSplit[#iconNameSplit]
	TweakDB:SetFlat(categoryPath..".iconName",iconName)
	TweakDB:SetFlat(categoryPath..".localizedDescription",descriptionLocKey)
	TweakDB:SetFlat(categoryPath..".localizedName",nameLocKey)

end

function API.CreateInteractionUI(interactionUIName,caption_LocKey,description_LocKey,icon_TDBID)
	local defaultUIName = interactionUIName
	interactionUIName = "CustomInteractions."..interactionUIName

	if TweakDB:GetRecord(interactionUIName) == nil then
		TweakDB:CloneRecord(interactionUIName,"Interactions.PingHack")
	end

	TweakDB:SetFlat(interactionUIName..".caption",caption_LocKey)

	local captionIcon = "UICaptionIcon."..defaultUIName

	if TweakDB:GetRecord(captionIcon) == nil then
		TweakDB:CreateRecord(captionIcon,"gamedataChoiceCaptionIconPart_Record")
	end
	TweakDB:SetFlat(captionIcon..".mappinVariant","Mappins.InvalidVariant")
	TweakDB:SetFlat(captionIcon..".partType","ChoiceCaptionPartType.Icon")
	TweakDB:SetFlat(captionIcon..".texturePartID",icon_TDBID)
	TweakDB:SetFlat(captionIcon..".enumName",CName.new(defaultUIName))

	TweakDB:SetFlat(interactionUIName..".captionIcon",captionIcon)
	TweakDB:SetFlat(interactionUIName..".description",description_LocKey)
	TweakDB:SetFlat(interactionUIName..".name",defaultUIName)
	TweakDB:SetFlat(interactionUIName..".action","Choice1")

	return interactionUIName

end

--#endregion

--Thank you StackOverflow,I hate lua
function Split (string, separator)
	if separator == nil then
		separator = "%s"
	end
	local t={}
	for str in string.gmatch(string, "([^"..separator.."]+)") do
		table.insert(t, str)
	end
	return t
end

return API
