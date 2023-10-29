import HackingExtensions.*
import CustomHackingSystem.Tools.*

//Little modification here to allow custom quickhacks to be implemented with the system

@replaceMethod(QuickHackableHelper)
public final static func TranslateActionsIntoQuickSlotCommands(const actions: array<ref<DeviceAction>>, commands: script_ref<array<ref<QuickhackData>>>, gameObject: ref<GameObject>, scriptableComponentPS: ref<ScriptableDeviceComponentPS>) -> Void
{
	  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameObject.GetGame());
	  let customHackSystem:ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
    let actionCompletionEffects: array<wref<ObjectActionEffect_Record>>;
    let actionMatchDeck: Bool;
    let actionRecord: ref<ObjectAction_Record>;
    let actionStartEffects: array<wref<ObjectActionEffect_Record>>;
    let choice: InteractionChoice;
    let emptyChoice: InteractionChoice;
    let i: Int32 = 0;
    let i1: Int32;
    let isQueuePerkBought: Bool;
    let newCommand: ref<QuickhackData>;
    let sAction: ref<ScriptableDeviceAction>;
    let statModifiers: array<wref<StatModifier_Record>>;
    let playerRef: ref<PlayerPuppet> = GetPlayer(gameObject.GetGame());
    let iceLVL: Float = QuickHackableHelper.GetICELevel(gameObject);
    let actionOwnerName: CName = StringToName(gameObject.GetDisplayName());
    let playerQHacksList: array<PlayerQuickhackData> = RPGManager.GetPlayerQuickHackListWithQuality(playerRef);

    //This is used to avoid an issue where the Ping quickhack would get duplicated onto regular device quickhacks
    let addedQuickacksNames: array<CName>;
    //The trick here is to inject all the quickhacks registered, as if they were in the player's quickhack list, but they get sorted later
    for quickhack in customHackSystem.customDeviceActions.GetValues()
    {
      let quickhackCasted: ref<ScriptableDeviceAction> = quickhack as ScriptableDeviceAction;
      let newPlayerQuickhackData: PlayerQuickhackData = new PlayerQuickhackData(ItemID.None(),quickhackCasted.GetObjectActionRecord(),5);
      ArrayPush(playerQHacksList,newPlayerQuickhackData);
    }

    //Removed Debug calls for better code clarity

    if (ArraySize(playerQHacksList) == 0)
    {
      newCommand = new QuickhackData();
      newCommand.m_title = "LocKey#42171";
      newCommand.m_isLocked = true;
      newCommand.m_actionState = EActionInactivityReson.Invalid;
      newCommand.m_actionOwnerName = StringToName(gameObject.GetDisplayName());
      newCommand.m_description = "LocKey#42172";
      newCommand.m_noQuickhackData = true;
      ArrayPush(Deref(commands), newCommand);
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

        //Removed a condition here that would block the quickhack checks for custom categories 

        actionMatchDeck = false;
        i1 = 0;
        while i1 < ArraySize(actions)
        {
          sAction = actions[i1] as ScriptableDeviceAction;

          if (Equals(actionRecord.ActionName(), sAction.GetObjectActionRecord().ActionName())
              && !ArrayContains(addedQuickacksNames,actionRecord.ActionName()))
          {
            actionMatchDeck = true;

            //Add the quickhack to the list of already added quickacks
            //Avoids having duplicate quickhacks 
            ArrayPush(addedQuickacksNames,actionRecord.ActionName());
            if actionRecord.Priority() >= sAction.GetObjectActionRecord().Priority()
            {
              sAction.SetObjectActionID(playerQHacksList[i].actionRecord.GetID());
            }
            else
            {
              actionRecord = sAction.GetObjectActionRecord();
            };
            newCommand.m_uploadTime = sAction.GetActivationTime();
            if IsDefined(gameObject as Device)
            {
              newCommand.m_duration = scriptableComponentPS.GetDistractionDuration(sAction);
            }
            else
            {
              newCommand.m_duration = sAction.GetDurationValue();
            };
            break;
          };
          i1 += 1;
        };
        newCommand.m_itemID = playerQHacksList[i].itemID;
        newCommand.m_actionOwnerName = actionOwnerName;
        newCommand.m_title = LocKeyToString(actionRecord.ObjectActionUI().Caption());
        newCommand.m_description = LocKeyToString(actionRecord.ObjectActionUI().Description());
        newCommand.m_icon = actionRecord.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
        newCommand.m_iconCategory = actionRecord.GameplayCategory().IconName();
        newCommand.m_type = actionRecord.ObjectActionType().Type();
        newCommand.m_actionOwner = gameObject.GetEntityID();
        newCommand.m_isInstant = false;
        newCommand.m_ICELevel = iceLVL;
        newCommand.m_ICELevelVisible = false;
        newCommand.m_vulnerabilities = scriptableComponentPS.GetActiveQuickHackVulnerabilities();
        newCommand.m_actionState = EActionInactivityReson.Locked;
        newCommand.m_quality = playerQHacksList[i].quality;
        newCommand.m_costRaw = BaseScriptableAction.GetBaseCostStatic(playerRef, actionRecord);
        newCommand.m_category = actionRecord.HackCategory();
        ArrayClear(actionCompletionEffects);
        actionRecord.CompletionEffects(actionCompletionEffects);
        newCommand.m_actionCompletionEffects = actionCompletionEffects;
        actionRecord.StartEffects(actionStartEffects);
        i1 = 0;
        while i1 < ArraySize(actionStartEffects)
        {
          if Equals(actionStartEffects[i1].StatusEffect().StatusEffectType().Type(), gamedataStatusEffectType.PlayerCooldown)
          {
            actionStartEffects[i1].StatusEffect().Duration().StatModifiers(statModifiers);
            newCommand.m_cooldown = RPGManager.CalculateStatModifiers(statModifiers, gameObject.GetGame(), playerRef, Cast<StatsObjectID>(playerRef.GetEntityID()), Cast<StatsObjectID>(playerRef.GetEntityID()));
            newCommand.m_cooldownTweak = actionStartEffects[i1].StatusEffect().GetID();
            ArrayClear(statModifiers);
          };
          if newCommand.m_cooldown != 0.00
          {
            break;
          };
          i1 += 1;
        };
        if actionMatchDeck
        {
          if !IsDefined(gameObject as GenericDevice)
          {
            choice = emptyChoice;
            choice = sAction.GetInteractionChoice();
            if TDBID.IsValid(choice.choiceMetaData.tweakDBID)
            {
              newCommand.m_titleAlternative = LocKeyToString(TweakDBInterface.GetInteractionBaseRecord(choice.choiceMetaData.tweakDBID).Caption());
            };
          };
          newCommand.m_cost = sAction.GetCost();
          newCommand.m_awarenessCost = sAction.GetAwarenessCost(gameObject.GetGame());
          newCommand.m_showRevealInfo = newCommand.m_awarenessCost > 0.00 && !playerRef.IsInCombat();
          newCommand.m_willReveal = !playerRef.IsBeingRevealed();
          if sAction.IsInactive()
          {
            newCommand.m_isLocked = true;
            newCommand.m_inactiveReason = sAction.GetInactiveReason();
            if gameObject.HasActiveQuickHackUpload()
            {
              newCommand.m_action = sAction;
            };
          }
          else
          {
            if StatusEffectSystem.ObjectHasStatusEffect(playerRef, newCommand.m_cooldownTweak)
            {
              newCommand.m_isLocked = true;
              newCommand.m_inactiveReason = "LocKey#7019";
            };
            if !sAction.CanPayCost(null, true)
            {
              newCommand.m_actionState = EActionInactivityReson.OutOfMemory;
              newCommand.m_isLocked = true;
              newCommand.m_inactiveReason = "LocKey#27398";
            };
            if GameInstance.GetStatPoolsSystem(gameObject.GetGame()).HasActiveStatPool(Cast<StatsObjectID>(gameObject.GetEntityID()), gamedataStatPoolType.QuickHackUpload)
            {
              isQueuePerkBought = PlayerDevelopmentSystem.GetData(playerRef).IsNewPerkBought(gamedataNewPerkType.Intelligence_Left_Milestone_2) == 2;
              if !isQueuePerkBought
              {
                newCommand.m_isLocked = true;
                newCommand.m_inactiveReason = "LocKey#27398";
              };
            };
            if !sAction.IsInactive() || gameObject.HasActiveQuickHackUpload()
            {
              newCommand.m_action = sAction;
            };
          };
        }
        else
        {
          newCommand.m_isLocked = true;
          newCommand.m_inactiveReason = "LocKey#10943";
        };
        newCommand.m_actionMatchesTarget = actionMatchDeck;
        if !newCommand.m_isLocked
        {
          newCommand.m_actionState = EActionInactivityReson.Ready;
        };
        ArrayPush(Deref(commands), newCommand);
        i += 1;
      };
    };
    i = 0;
    while i < ArraySize(Deref(commands))
    {
      if Deref(commands)[i].m_isLocked && IsDefined(Deref(commands)[i].m_action)
      {
        (Deref(commands)[i].m_action as ScriptableDeviceAction).SetInactiveWithReason(false, Deref(commands)[i].m_inactiveReason);
      };
      i += 1;
    };
    QuickhackModule.SortCommandPriority(commands, gameObject.GetGame());
  }
