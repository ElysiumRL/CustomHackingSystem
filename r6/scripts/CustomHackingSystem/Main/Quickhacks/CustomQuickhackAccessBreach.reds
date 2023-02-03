import HackingExtensions.*

//Scriptable Action to use when you want to use the system using quickhacks

public class CustomAccessBreach extends PuppetAction
{

	public let m_attempt: Int32;

	public let m_networkName: String;

	public let m_npcCount: Int32;

	public let m_isRemote: Bool;

	public let m_isSuicide: Bool;

	public let m_minigameDefinition: TweakDBID;

	public let m_targetHack: ref<IScriptable>;

	public final func SetProperties(networkName: String, npcCount: Int32, attemptsCount: Int32, isRemote: Bool, isSuicide: Bool,minigameDefinition: TweakDBID,targetHack: ref<IScriptable>) -> Void
	{
		this.m_networkName = networkName;
		this.m_npcCount = npcCount;
		this.m_attempt = attemptsCount;
		this.m_isRemote = isRemote;
		this.m_isSuicide = isSuicide;
		this.m_minigameDefinition = minigameDefinition;
		this.m_targetHack = targetHack;
	}

	public final func SetAttemptCount(amount: Int32) -> Void
	{
		this.m_attempt = amount;
	}

	private func StartUpload(gameInstance: GameInstance) -> Void
	{
		let breachListener: ref<AccessBreachListener>;
		let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
		let statMod: ref<gameStatModifierData> = RPGManager.CreateStatModifier(gamedataStatType.QuickHackUpload, gameStatModifierType.Additive, 1.00);
		GameInstance.GetStatsSystem(gameInstance).RemoveAllModifiers(Cast<StatsObjectID>(this.m_requesterID), gamedataStatType.QuickHackUpload);
		GameInstance.GetStatsSystem(gameInstance).AddModifier(Cast<StatsObjectID>(this.m_requesterID), statMod);
		breachListener = new AccessBreachListener();
		breachListener.m_action = this;
		breachListener.m_gameInstance = gameInstance;
		statPoolSys.RequestRegisteringListener(Cast<StatsObjectID>(this.m_requesterID), gamedataStatPoolType.QuickHackUpload, breachListener);
		statPoolSys.RequestAddingStatPool(Cast<StatsObjectID>(this.m_requesterID), t"BaseStatPools.BaseQuickHackUpload");
	}

	private func CompleteAction(gameInstance: GameInstance) -> Void
	{
		super.CompleteAction(gameInstance);

		let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
		let customHackSystem:ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;

		customHackSystem.StartNewQuickhackInstance(this.m_networkName, this, this.m_minigameDefinition, this.m_targetHack);
		this.GetNetworkBlackboard(gameInstance).SetInt(this.GetNetworkBlackboardDef().DevicesCount, this.m_npcCount);
		this.GetNetworkBlackboard(gameInstance).SetBool(this.GetNetworkBlackboardDef().OfficerBreach, false);
		this.GetNetworkBlackboard(gameInstance).SetBool(this.GetNetworkBlackboardDef().RemoteBreach, true);
		this.GetNetworkBlackboard(gameInstance).SetBool(this.GetNetworkBlackboardDef().SuicideBreach, false);
		this.GetNetworkBlackboard(gameInstance).SetVariant(this.GetNetworkBlackboardDef().MinigameDef, ToVariant(this.m_minigameDefinition),true);
		this.GetNetworkBlackboard(gameInstance).SetString(this.GetNetworkBlackboardDef().NetworkName, this.m_networkName,true);
		this.GetNetworkBlackboard(gameInstance).SetEntityID(this.GetNetworkBlackboardDef().DeviceID, GetPlayer(gameInstance).GetEntityID(),true);
		this.GetNetworkBlackboard(gameInstance).SetInt(this.GetNetworkBlackboardDef().Attempt, this.m_attempt);
		this.SendNanoWireBreachEventToPSM(n"NanoWireRemoteBreach", true, gameInstance);
	}

	private final func GetNetworkBlackboard(gameInstance: GameInstance) -> ref<IBlackboard>
	{
		return GameInstance.GetBlackboardSystem(gameInstance).Get(this.GetNetworkBlackboardDef());
	}

	private final func GetNetworkBlackboardDef() -> ref<NetworkBlackboardDef>
	{
		return GetAllBlackboardDefs().NetworkBlackboard;
	}

	private final func SendNanoWireBreachEventToPSM(id: CName, isActive: Bool, gameInstance: GameInstance) -> Void
	{
		let psmEvent: ref<PSMPostponedParameterBool> = new PSMPostponedParameterBool();
		psmEvent.id = id;
		psmEvent.value = isActive;
		GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject().QueueEvent(psmEvent);
	}
}
