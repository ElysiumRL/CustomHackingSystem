import CustomHackingSystem.Hacks.PatternRecognition.*

//left for debug purposes only
@wrapMethod(gameuiInGameMenuGameController)
private final func RegisterInputListenersForPlayer(playerPuppet: ref<GameObject>) -> Void
{
	wrappedMethod(playerPuppet);
	
	playerPuppet.RegisterInputListener(this, n"Choice2_Hold");
}

//left for debug purposes only
@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool
{
	wrappedMethod(action, consumer);

	let actionName: CName = ListenerAction.GetName(action);
	let actionType: gameinputActionType = ListenerAction.GetType(action);

	if Equals(actionName, n"Choice2_Hold") && Equals(actionType, gameinputActionType.BUTTON_HOLD_COMPLETE)
	{
		let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
		let blackboard: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
		let state: gamePSMVehicle = IntEnum(blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vehicle));

		if Equals(state, gamePSMVehicle.Default)
		{
			let minigameSettings:ref<PatternRecognitionHackSettings> = new PatternRecognitionHackSettings();
			minigameSettings.letterType = EPatternRecognitionHackLetterType.Alphabetical;
			PatternRecognitionHack.StartMinigame(minigameSettings, this.GetPlayerControlledObject().GetGame());
			ListenerActionConsumer.DontSendReleaseEvent(consumer);
		}
	}
}

@wrapMethod(gameuiInGameMenuGameController)
private final func RegisterGlobalBlackboards() -> Void
{
	wrappedMethod();
	let hackingMinigameBlackboard:ref<IBlackboard> = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().HackingMinigame);

	if(IsDefined(hackingMinigameBlackboard))
	{
		let inGameMenuController:Variant = ToVariant(this);

		hackingMinigameBlackboard.SetVariant(GetAllBlackboardDefs().HackingMinigame.InGameMenuController, inGameMenuController);
	}
}

//Entirely Replaces AccessPoint hacks
@replaceMethod(Device)
private final func DisplayConnectionWindowOnPlayerHUD(shouldDisplay: Bool, attempt: Int32) -> Void
{
	let minigameSettings:ref<PatternRecognitionHackSettings> = new PatternRecognitionHackSettings();

	PatternRecognitionHack.StartMinigame(minigameSettings, this.GetGame());


//	let hackingMinigameBlackboard:ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().HackingMinigame);
//
//	if (IsDefined(hackingMinigameBlackboard))
//	{
//		let inGameMenuControllerVariant:Variant = hackingMinigameBlackboard.GetVariant(GetAllBlackboardDefs().HackingMinigame.InGameMenuController);
//		let inGameMenuController:ref<gameuiInGameMenuGameController> = FromVariant<ref<gameuiInGameMenuGameController>>(inGameMenuControllerVariant);
//    	
//		//TODO: replace by CustomHackingSystem.StartMinigame()
//		PatternRecognitionHackPopup.Show(inGameMenuController);
//
//	}
	this.TogglePersonalLink(false, this.GetPlayerMainObject());
	this.TurnOffDevice();
	this.DeactivateDevice();
}