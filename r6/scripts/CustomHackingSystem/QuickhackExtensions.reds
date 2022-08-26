//Little modification here to allow custom quickhacks to be implemented with the system
import HackingExtensions.*
import CustomHackingSystem.Tools.*

@replaceMethod(Device)
private func TranslateActionsIntoQuickSlotCommands(actions: array<ref<DeviceAction>>, out commands: array<ref<QuickhackData>>) -> Void 
{
	let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
	let customHackSystem:ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;

	let actionCompletionEffects: array<wref<ObjectActionEffect_Record>>;
	let actionMatchDeck: Bool;
	let actionRecord: wref<ObjectAction_Record>;
	let actionStartEffects: array<wref<ObjectActionEffect_Record>>;
	let choice: InteractionChoice;
	let emptyChoice: InteractionChoice;
	let i: Int32;
	let i1: Int32;
	let newCommand: ref<QuickhackData>;
	let sAction: ref<ScriptableDeviceAction>;
	let statModifiers: array<wref<StatModifier_Record>>;
	let playerRef: ref<PlayerPuppet> = GetPlayer(this.GetGame());
	let iceLVL: Float = 0.0;
	let actionOwnerName: CName = StringToName(this.GetDisplayName());
	let playerQHacksList: array<PlayerQuickhackData> = RPGManager.GetPlayerQuickHackListWithQuality(playerRef);

	let customActionsFound:array<wref<ObjectAction_Record>>;
	if ArraySize(playerQHacksList) == 0 {
	  newCommand = new QuickhackData();
	  newCommand.m_title = "LocKey#42171";
	  newCommand.m_isLocked = true;
	  newCommand.m_actionState = EActionInactivityReson.Invalid;
	  newCommand.m_actionOwnerName = StringToName(this.GetDisplayName());
	  newCommand.m_description = "LocKey#42172";
	  ArrayPush(commands, newCommand);
	}
	else
	{
	  i = 0;
	  while i < ArraySize(playerQHacksList)
	  {
		newCommand = new QuickhackData();
		sAction = null;
		ArrayClear(actionStartEffects);
		actionRecord = playerQHacksList[i].actionRecord;
		if NotEquals(actionRecord.ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack)
		{
		}
		else {
		  actionMatchDeck = false;
		  i1 = 0;
		  while i1 < ArraySize(actions) {
			sAction = actions[i1] as ScriptableDeviceAction;
			if Equals(actionRecord.ActionName(), sAction.GetObjectActionRecord().ActionName()) {
			  actionMatchDeck = true;
			  if actionRecord.Priority() >= sAction.GetObjectActionRecord().Priority() {
				sAction.SetObjectActionID(playerQHacksList[i].actionRecord.GetID());
			  } else {
				actionRecord = sAction.GetObjectActionRecord();
			  };
			  newCommand.m_uploadTime = sAction.GetActivationTime();
			  newCommand.m_duration = sAction.GetDurationValue();
			  break;
			};
			if customHackSystem.customDeviceActions.KeyExist(NameToString(sAction.actionName)) 
			&& !ArrayContains(customActionsFound,sAction.GetObjectActionRecord())
			{
			  //LogChannel(n"DEBUG","Matches Deck");
			  actionMatchDeck = true;
			  actionRecord = sAction.GetObjectActionRecord();
			  newCommand.m_uploadTime = sAction.GetActivationTime();
			  newCommand.m_duration = sAction.GetDurationValue();
			  ArrayPush(customActionsFound,sAction.GetObjectActionRecord());
			  break;
			};

			i1 += 1;
		  };
		  newCommand.m_actionOwnerName = actionOwnerName;
		  newCommand.m_title = LocKeyToString(actionRecord.ObjectActionUI().Caption());
		  newCommand.m_description = LocKeyToString(actionRecord.ObjectActionUI().Description());
		  newCommand.m_icon = actionRecord.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
		  newCommand.m_iconCategory = actionRecord.GameplayCategory().IconName();
		  newCommand.m_type = actionRecord.ObjectActionType().Type();
		  newCommand.m_actionOwner = this.GetEntityID();
		  newCommand.m_isInstant = false;
		  newCommand.m_ICELevel = iceLVL;
		  newCommand.m_ICELevelVisible = false;
		  newCommand.m_vulnerabilities = this.GetDevicePS().GetActiveQuickHackVulnerabilities();
		  newCommand.m_actionState = EActionInactivityReson.Locked;
		  newCommand.m_quality = playerQHacksList[i].quality;
		  newCommand.m_costRaw = BaseScriptableAction.GetBaseCostStatic(playerRef, actionRecord);
		  newCommand.m_category = actionRecord.HackCategory();
		  ArrayClear(actionCompletionEffects);
		  actionRecord.CompletionEffects(actionCompletionEffects);
		  newCommand.m_actionCompletionEffects = actionCompletionEffects;
		  actionRecord.StartEffects(actionStartEffects);
		  i1 = 0;
		  while i1 < ArraySize(actionStartEffects) {
			if Equals(actionStartEffects[i1].StatusEffect().StatusEffectType().Type(), gamedataStatusEffectType.PlayerCooldown) {
			  actionStartEffects[i1].StatusEffect().Duration().StatModifiers(statModifiers);
			  newCommand.m_cooldown = RPGManager.CalculateStatModifiers(statModifiers, this.GetGame(), playerRef, Cast<StatsObjectID>(playerRef.GetEntityID()), Cast<StatsObjectID>(playerRef.GetEntityID()));
			  newCommand.m_cooldownTweak = actionStartEffects[i1].StatusEffect().GetID();
			  ArrayClear(statModifiers);
			};
			if newCommand.m_cooldown != 0.00 {
			  break;
			};
			i1 += 1;
		  };
		  if actionMatchDeck {
			if !IsDefined(this as GenericDevice) {
			  choice = emptyChoice;
			  choice = sAction.GetInteractionChoice();
			  if TDBID.IsValid(choice.choiceMetaData.tweakDBID) {
				newCommand.m_titleAlternative = LocKeyToString(TweakDBInterface.GetInteractionBaseRecord(choice.choiceMetaData.tweakDBID).Caption());
			  };
			};
			newCommand.m_cost = sAction.GetCost();
			if sAction.IsInactive() {
			  newCommand.m_isLocked = true;
			  newCommand.m_inactiveReason = sAction.GetInactiveReason();
			  if this.HasActiveQuickHackUpload() {
				newCommand.m_action = sAction;
			  };
			} else {
			  if !sAction.CanPayCost() {
				newCommand.m_actionState = EActionInactivityReson.OutOfMemory;
				newCommand.m_isLocked = true;
				newCommand.m_inactiveReason = "LocKey#27398";
			  };
			  if GameInstance.GetStatPoolsSystem(this.GetGame()).HasActiveStatPool(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.QuickHackUpload) {
				newCommand.m_isLocked = true;
				newCommand.m_inactiveReason = "LocKey#27398";
			  };
			  if !sAction.IsInactive() || this.HasActiveQuickHackUpload() {
				newCommand.m_action = sAction;
			  };
			};
		  } else {
			newCommand.m_isLocked = true;
			newCommand.m_inactiveReason = "LocKey#10943";
		  };
		  newCommand.m_actionMatchesTarget = actionMatchDeck;
		  if !newCommand.m_isLocked {
			newCommand.m_actionState = EActionInactivityReson.Ready;
		  };
		  ArrayPush(commands, newCommand);
		};
		i += 1;
	  };
	};
	i = 0;
	while i < ArraySize(commands) {
	  if commands[i].m_isLocked && IsDefined(commands[i].m_action) {
		(commands[i].m_action as ScriptableDeviceAction).SetInactiveWithReason(false, commands[i].m_inactiveReason);
	  };
	  i += 1;
	};
	QuickhackModule.SortCommandPriority(commands, this.GetGame());
}
