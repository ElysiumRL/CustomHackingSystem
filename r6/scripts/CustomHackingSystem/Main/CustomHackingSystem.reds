module HackingExtensions
import HackingExtensions.Programs.*
import CustomHackingSystem.Tools.*

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool 
{
	let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
	let hackSystem:ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
	hackSystem.Initialize(this.GetGame());

	wrappedMethod();
}

//Event request used to fix an issue with quickhacks
public class QuickhackProgramResolver extends ScriptableSystemRequest
{
	public let activePrograms:Variant;
}

public class CustomHackingSystem extends ScriptableSystem
{

	//////////////////////////////////////////////////////////

	//The magical "button" to clear the console logs
	public let enableDebugLogs:Bool = false;
	
	//////////////////////////////////////////////////////////

	//Game Instance, it should be the GetGame from PlayerPuppet (See Initialize function)
	let gameInstance:GameInstance;

	//Custom Settings for the Custom Hack
	let settings: ref<CustomHackingProperties>;

	//Current Custom Hack Minigame State
	let currentMinigameState:HackingMinigameState;

	//True if the Player is in a Custom Hack
	let isPlayerCurrentlyHacking:Bool;

	//Hashmap containing all program actions. super omega ultra important when you want script execution after hack
	let programsHashMap:ref<inkHashMap>;

	//Callback for the current hacking state in the blackboard
	let hackingStateListener:ref<CallbackHandle>;

	//Callback for the active (succeeded) programs in the blackboard
	let activeProgramsListener:ref<CallbackHandle>;
	
	let canRunProgramActions:Bool;

	public let customDeviceActions: ref<StringHashMap>;
	
	public let lastActivePrograms:Variant;

	//DelayID used for the quickhack resolver
	let quickhackResolverDelayID: DelayID;
	
	//Is the module correctly initialized ?
	let isModuleInitialized:Bool = false;

	public func Initialize(gameInstance:GameInstance) -> Void
	{
		if !this.isModuleInitialized
		{
			if(GameInstance.IsValid(gameInstance))
			{
				this.gameInstance = gameInstance;
				if this.GenerateBBListeners()
				{
					this.settings = CustomHackingProperties.Default();
					this.currentMinigameState = HackingMinigameState.Unknown;
					this.isPlayerCurrentlyHacking = false;
					this.programsHashMap = new inkHashMap();
					this.customDeviceActions = new StringHashMap();
					this.GenerateDefaultPrograms();
					this.isModuleInitialized = true;
					this.Log("[CustomHackingSystem] Module Initialized");
				}
				else
				{
					this.Log("[CustomHackingSystem] Initialization failed : Listeners not generated properly");
				}

			}
			else
			{
				this.Log("[CustomHackingSystem] Initialization failed : Game Instance not valid");
			}
		}

	}



	//Generates all default program actions
	//If you want to add your own program action, use AddProgramAction in your own scripts
	protected func GenerateDefaultPrograms()
	{
		//Dummy Example, use AddProgramAction instead
		//this.programsHashMap.Insert(TDBID.ToNumber(t"MinigameAction.NetworkDataMineLootAllMaster"),new NetworkLootMasterRewardProgramAction());

		this.AddProgramAction(t"MinigameAction.GainAccessProgram", new GainAccessRewardProgramAction());
		this.AddProgramAction(t"MinigameAction.NetworkDataMineLootAll", new NetworkLootBasicRewardProgramAction());
		this.AddProgramAction(t"MinigameAction.NetworkDataMineLootAllAdvanced", new NetworkLootAdvancedRewardProgramAction());
		this.AddProgramAction(t"MinigameAction.NetworkDataMineLootAllMaster", new NetworkLootMasterRewardProgramAction());
	}

	//Adds a Program Action in the Program Action hash map. This is super important if you want the system to trigger gameplay
	public final func AddProgramAction(MinigameAction_TDBID:TweakDBID,programToAdd:ref<HackProgramAction>) -> Void
	{
		if(!IsDefined(this.programsHashMap))
		{
			this.programsHashMap = new inkHashMap();
		}
		programToAdd.gameInstance = this.gameInstance;
		this.programsHashMap.Insert(TDBID.ToNumber(MinigameAction_TDBID),programToAdd);
	}

	//Registers the device action in order to create a custom interaction for quickhacks
	public func RegisterDeviceAction(action:ref<ScriptableDeviceAction>) -> Void
	{
		if(!IsDefined(this.customDeviceActions))
		{
			this.customDeviceActions = new StringHashMap();
		}
		this.customDeviceActions.Insert(NameToString(action.actionName), action);
	}

	//Returns the Player Puppet class
	public const func GetPlayer() -> wref<PlayerPuppet>
	{
		return GetPlayer(this.gameInstance);
	}
	
	//Returns the Player Puppet Persistent State class
	public const func GetPlayerPS() -> ref<PlayerPuppetPS>
	{
		return GetPlayer(this.gameInstance).GetPS();
	}

	//Returns the Player Entity ID
	public const func GetPlayerID() -> EntityID
	{
		return this.GetPlayer().GetEntityID();
	}

	//Returns the Network Blackbard
	private const func GetNetworkBB() -> ref<IBlackboard>
	{
		return GameInstance.GetBlackboardSystem(this.gameInstance).Get(this.GetNetworkBBDef());
	}
	
	//Returns the Network Blackboard Definition
	private const func GetNetworkBBDef() -> ref<NetworkBlackboardDef>
	{
		return GetAllBlackboardDefs().NetworkBlackboard;
	}

	//Returns the Hacking Minigame Blackboard
	private const func GetHackingMinigameBB() -> ref<IBlackboard>
	{
		return GameInstance.GetBlackboardSystem(this.gameInstance).Get(GetAllBlackboardDefs().HackingMinigame);
	}

	//Returns the Hacking Minigame Blackboard Definition
	private const func GetHackingMinigameBBDef() -> ref<HackingMinigameDef>
	{
		return GetAllBlackboardDefs().HackingMinigame;
	}

	//Sets up the minigame settings & opens up the Hacking Minigame interface
	private func DisplayConnectionWindowOnPlayerHUD() -> Void
	{
		this.GetNetworkBB().SetInt(this.GetNetworkBBDef().DevicesCount, this.settings.connectionCount);
		this.GetNetworkBB().SetBool(this.GetNetworkBBDef().OfficerBreach, false);
		this.GetNetworkBB().SetBool(this.GetNetworkBBDef().RemoteBreach, true,true);
		this.GetNetworkBB().SetString(this.GetNetworkBBDef().NetworkName, this.settings.networkName, true);
		this.GetNetworkBB().SetVariant(this.GetNetworkBBDef().MinigameDef, ToVariant(this.GetCurrentMinigameDefinition()));
		this.GetNetworkBB().SetInt(this.GetNetworkBBDef().Attempt, this.settings.hackAttempts);
		this.GetNetworkBB().SetEntityID(this.GetNetworkBBDef().DeviceID, this.GetPlayerID());
	}

	//Terminates the Hacking Minigame Interface
	//TODO possibly remove it as it might be useless
	private func TerminateConnectionWindowOnPlayerHUD() -> Void
	{
		let invalidID: EntityID;
		this.GetNetworkBB().SetString(this.GetNetworkBBDef().NetworkName, "");
	  	this.GetNetworkBB().SetEntityID(this.GetNetworkBBDef().DeviceID, invalidID);
	}

	//Returns the Current Miniagme Definition from the Settings
	public const func GetCurrentMinigameDefinition() -> TweakDBID
	{
		return this.settings.minigameDef_TDBID;
	}


	//Sets a new Minigame Definition into the Settings
	public func SetCurrentMinigameDefinition(paramTest:TweakDBID) -> Void
	{
		this.settings.minigameDef_TDBID = paramTest;
	}

	//Sets the event to trigger if you succeed on the minigame
	public func SetCustomHackSucceededEvent(onSucceed : ref<OnCustomHackingSucceeded>)
	{
		this.settings.onSucceed = onSucceed;
	}

	//Sets the event to trigger if you fail on the minigame
	public func SetCustomHackSucceededEvent(onFailed : ref<OnCustomHackingFailed>)
	{
		this.settings.onFailed = onFailed;
	}

	//Executes custom functions for succeeded programs
	public func ResolveHackingActivePrograms(evt: Variant) -> Void
	{
		this.Log("Quickhack Active Programs Checked");
		if(this.canRunProgramActions && this.isPlayerCurrentlyHacking)
		{
			this.Log("	Quickhack Active Programs Runned");
			this.lastActivePrograms = evt;

			let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(evt);

			let allProgramsRecord:array<wref<Program_Record>>;

			let minigameRecord:ref<Minigame_Def_Record> = TweakDBInterface.GetMinigame_DefRecord(this.GetCurrentMinigameDefinition());

			let allPrograms:array<TweakDBID>;
			if(IsDefined(minigameRecord))
			{
				minigameRecord.OverrideProgramsList(allProgramsRecord);
			}

			for programRecord in allProgramsRecord
			{
				ArrayPush(allPrograms,programRecord.Program().GetID());
			}

			this.CheckForPerks(ArraySize(activePrograms));

			for program in allPrograms
			{
				let currentProgram:ref<HackProgramAction> = this.programsHashMap.Get(TDBID.ToNumber(program)) as HackProgramAction;
				if(IsDefined(currentProgram))
				{
					currentProgram.gameInstance = this.gameInstance;
					currentProgram.hackInstanceSettings = this.settings;

					if(ArrayContains(activePrograms,program))
					{
						currentProgram.ExecuteProgramSuccess();
					}
					else
					{
						currentProgram.ExecuteProgramFailure();
					}
					let programTDBID:wref<MinigameAction_Record> = TweakDBInterface.GetMinigameActionRecord(program);
					let rewards:array<wref<RewardBase_Record>>;
					programTDBID.Rewards(rewards);
					for reward in rewards
					{
						RPGManager.GiveReward(this.gameInstance, reward.GetID(), Cast<StatsObjectID>(this.GetPlayer().GetEntityID()));
					}
				}
				else
				{
					this.Log("Current Program " + TDBID.ToStringDEBUG(program) + " not found");
				}
			}
			this.isPlayerCurrentlyHacking = false;
			this.canRunProgramActions = false;
			this.SetIsQuichack(false);
		}
	}

	//Checks for hacking-related perks completion
	//It's a game function, I copied it
	public func CheckForPerks(opt completedPrograms:Int32) -> Void
	{
		if completedPrograms >= 3
		{
			if GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayerID()), gamedataStatType.ThreeOrMoreProgramsMemoryRegPerk) == 1.00
			{
				StatusEffectHelper.ApplyStatusEffect(this.GetPlayer(), t"BaseStatusEffect.ThreeOrMoreProgramsMemoryRegPerk1", this.GetPlayerID());
			}
			if GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayerID()), gamedataStatType.ThreeOrMoreProgramsMemoryRegPerk) == 2.00
			{
				StatusEffectHelper.ApplyStatusEffect(this.GetPlayer(), t"BaseStatusEffect.ThreeOrMoreProgramsMemoryRegPerk2",this.GetPlayerID());
			}
			if Cast<Bool>(GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayerID()), gamedataStatType.ThreeOrMoreProgramsCooldownRedPerk))
			{
				StatusEffectHelper.ApplyStatusEffect(this.GetPlayer(), t"BaseStatusEffect.ThreeOrMoreProgramsCooldownRedPerk", this.GetPlayerID());
			}
			if Cast<Bool>(GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayerID()), gamedataStatType.MinigameNextInstanceBufferExtensionPerk))
			{
		  		this.GetPlayer().SetBufferModifier(3);
			}
		}
	}

	//Function triggered when the Hacking Minigame changes a State
	public func ResolveHackingState(evt:Int32) -> Void
	{
		if(this.isPlayerCurrentlyHacking)
		{
			let isFailed:Bool = false;
			this.currentMinigameState = IntEnum(evt);

			switch(this.currentMinigameState)
			{
				case HackingMinigameState.Unknown:
					this.Log("Hacking Minigame State : Unknown");
					return;
				case HackingMinigameState.InProgress:
					this.Log("Hacking Minigame State : In Progress");
					return;
				case HackingMinigameState.Succeeded:
					this.Log("Hacking Minigame State : Succeeded");

					if IsDefined(this.settings.onSucceed)
					{
						this.settings.onSucceed.gameInstance = this.gameInstance;
						this.settings.onSucceed.hackInstanceSettings = this.settings;
						this.settings.onSucceed.Execute();
					}
					break;
				case HackingMinigameState.Failed:
					this.Log("Hacking Minigame State : Failed");

					isFailed = true;
					if !this.settings.isQuickhack
					{
						this.canRunProgramActions = true;
						let invalidDB:array<TweakDBID>;
						this.Log("Force Active Programs Resolver");
						this.ResolveHackingActivePrograms(ToVariant(invalidDB));
					}
					if IsDefined(this.settings.onFailed)
					{
						this.settings.onFailed.gameInstance = this.gameInstance;
						this.settings.onFailed.hackInstanceSettings = this.settings;
						this.settings.onFailed.Execute();
					}
					break;
			}
			//Forces a fix to ActivePrograms blackboard value not updating (and not firing event) if you have completed the same program twice in a row
			//This problem also happened with normal hacks but for some reasons it persists if hack is started through quickhacks
			//I hate this game  
			if this.settings.isQuickhack
			{
				let resolver:ref<QuickhackProgramResolver> = new QuickhackProgramResolver();
				//Used to clear active programs if the minigame is failed
				//Fixes an issue where failing a minigame would trigger the active programs of last minigame
				//Seriously why would the game not always fire a callback even if there is no modifications to the minigame active programs
				//Look at the size of the spaghetti code just because of that simple mistake
				if isFailed
				{
					resolver.activePrograms = null;
				}
				else
				{
					resolver.activePrograms = this.lastActivePrograms;
				}
				this.Log("Quickhack Resolver Request Created");
				GameInstance.GetDelaySystem(this.gameInstance).DelayScriptableSystemRequestNextFrame(this.GetClassName(), resolver);
			}

			this.TerminateConnectionWindowOnPlayerHUD();
			this.canRunProgramActions = true;
		}
	}

	//Resets active programs
	//This fixes an issue where blackboard would not trigger callbacks if nothing changed (i.e : succeeding on same hack pattern twice)
	//However this doesn't fix the exact same issue but if you were using quickhacks ....
	private final func ResetActivePrograms() -> Void
	{
		let invalidDB:array<TweakDBID> = [];
		this.canRunProgramActions = false;
		this.Log("Reseting Active Programs");
		this.GetHackingMinigameBB().SetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms, ToVariant(invalidDB), true);
	}

	//Starts the hack instance to the player
	public func StartNewHackInstance(
	instanceName:String,
	opt customMinigame:TweakDBID,
	opt hackedTarget:ref<IScriptable>,
	opt additionalData:array<Variant>,
	opt onSucceed:ref<OnCustomHackingSucceeded>,
	opt onFailed:ref<OnCustomHackingFailed>
	) -> Bool
	{
		this.Log("------------------------------------------");
		this.Log("Initiating Classic Hack");
		this.Log("------------------------------------------");

		let canPerformHack:Bool = this.GenerateBBListeners();

		if(this.settings.maximumHackAttempts == -1 
		|| this.settings.hackAttempts < this.settings.maximumHackAttempts) 
		&& !this.isPlayerCurrentlyHacking 
		&& canPerformHack
		{
			this.settings.additionalData = additionalData;
			this.settings.hackedTarget = hackedTarget;
			this.settings.onSucceed = onSucceed;
			this.settings.onFailed = onFailed;
			this.SetIsQuichack(false);

			if this.IsMinigameDefValid(customMinigame)
			{
				this.SetCurrentMinigameDefinition(customMinigame);
			}
			else
			{
				this.Log("[CustomHackingSystem] Minigame Definition TweakDBID not valid");
			}

			this.ResetActivePrograms();
			if Equals(this.settings.networkName,instanceName)
			{
				this.settings.hackAttempts = this.settings.hackAttempts + 1;
			}
			else
			{
				this.settings.hackAttempts = 1;
			}
			this.settings.networkName = instanceName;
			this.isPlayerCurrentlyHacking = true;
			this.DisplayConnectionWindowOnPlayerHUD();
			return true;
		}
		return false;
	}


	public func StartNewQuickhackInstance(
	instanceName:String,
	action:ref<ScriptableDeviceAction>,
	opt customMinigame:TweakDBID,
	opt hackedTarget:ref<IScriptable>,
	opt additionalData:array<Variant>,
	opt onSucceed:ref<OnCustomHackingSucceeded>,
	opt onFailed:ref<OnCustomHackingFailed>
	) -> Bool
	{
		this.Log("------------------------------------------");
		this.Log("Initiating Quickhack");
		this.Log("------------------------------------------");

		let canPerformHack:Bool = this.GenerateBBListeners();
		if(!this.isPlayerCurrentlyHacking && canPerformHack)
		{
			if this.IsMinigameDefValid(customMinigame)
			{
				this.SetCurrentMinigameDefinition(customMinigame);
			}
			else
			{
				this.Log("[CustomHackingSystem] Minigame Definition TweakDBID not valid");
			}
			this.settings.additionalData = additionalData;
			this.settings.hackedTarget = hackedTarget;
			this.settings.onSucceed = onSucceed;
			this.settings.onFailed = onFailed;

			this.ResetActivePrograms();
			if Equals(this.settings.networkName,instanceName)
			{
				this.settings.hackAttempts = this.settings.hackAttempts + 1;
			}
			else
			{
				this.settings.hackAttempts = 1;
			}
			this.SetIsQuichack(true);
			this.settings.networkName = instanceName;
			this.isPlayerCurrentlyHacking = true;
			return true;
		}
		return false;
	}

	//Generates callbacks for active programs & current minigame state
	public final func GenerateBBListeners() -> Bool
	{
		if(IsDefined(this.activeProgramsListener) && IsDefined(this.hackingStateListener))
		{
			this.Log("Listeners already found");
			return true;
		}

		if (!IsDefined(this.hackingStateListener))
		{
			this.hackingStateListener = this.GetHackingMinigameBB().RegisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this, n"ResolveHackingState",true);
			
			if (!IsDefined(this.hackingStateListener))
			{
				this.Log("[CustomHackingSystem] Hacking State Listener not found in Blackboard. Hack Request will be cancelled");
				return false;
			}
		}
		if (!IsDefined(this.activeProgramsListener))
		{
			this.activeProgramsListener = this.GetHackingMinigameBB().RegisterListenerVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms, this, n"ResolveHackingActivePrograms",true);
			if (!IsDefined(this.activeProgramsListener))
			{
				this.Log("[CustomHackingSystem] Active Programs Listener not found in Blackboard. Hack Request will be cancelled");
				return false;
			}
		}		
		return true;
	}

	//Sets the hack settings
	public final func SetProperties(newSettings: ref<CustomHackingProperties>) -> Void
	{
		this.settings = newSettings;
	}

	//On System Attach
	private func OnAttach() -> Void
	{
		this.Log("[CustomHackingSystem] Scriptable System Attached");
	}

	//On System Detach
	private func OnDetach() -> Void
	{
		this.Log("[CustomHackingSystem] Scriptable System Detached");

		if IsDefined(this.activeProgramsListener)
		{
			this.GetHackingMinigameBB().UnregisterListenerVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms, this.activeProgramsListener);
		}

		if IsDefined(this.hackingStateListener)
		{
			this.GetHackingMinigameBB().UnregisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this.hackingStateListener);		
		}
		this.isModuleInitialized = false;
	}

	//Quickhack Resolver callback
	private final func OnQuickhackResolver(request: ref<QuickhackProgramResolver>) -> Void
	{
		//Basically, we want to check active programs once
		//isQuickhack is reset once the active programs are set
		//and since the event is sent on the next frame, if the isQuickhack value is reset, that means we don't need to use the resolver
		//again, huge spaghetti just because a callback was not set properly ...
		if(this.settings.isQuickhack)
		{
			this.Log("	Quickhack Resolver Request");
			this.ResolveHackingActivePrograms(request.activePrograms);
		}
		else
		{
			this.Log("	Quickhack Resolver Request Failed");
		}
	}

	//Sets if this is a Quickhack
	public final func SetIsQuichack(value:Bool) -> Void
	{
		this.settings.isQuickhack = value;
	}

	//Returns true if minigame definition is valid
	public final func IsMinigameDefValid(minigameDef: TweakDBID) -> Bool
	{
		return TDBID.IsValid(minigameDef) && IsDefined(TweakDBInterface.GetMinigame_DefRecord(minigameDef));
	}

	//Logs everything into the CET Console (only if you pressed on the magical button tho)
	public final func Log(str:String) -> Void
	{
		if this.enableDebugLogs
		{
			LogChannel(n"DEBUG",str);

		}
	}
}

//Properties of the current hack instance
public class CustomHackingProperties extends IScriptable
{
	public let networkName:String;
	public let connectionCount:Int32;
	public let isQuickhack:Bool;

	public let hackAttempts:Int32;
	public let maximumHackAttempts:Int32;
	public let minigameDef_TDBID: TweakDBID;

	public let hackedTarget:ref<IScriptable>;
	public let additionalData:array<Variant>;

	public let onSucceed: ref<OnCustomHackingSucceeded>;
	public let onFailed: ref<OnCustomHackingFailed>;

	public static func Create(networkName:String,
	connectionCount:Int32,
	isQuickhack:Bool,
	hackAttempts:Int32,
	maximumHackAttempts:Int32,
	minigameDef_TDBID:TweakDBID,
	hackedTarget:ref<IScriptable>,
	additionalData:array<Variant>,
	onSucceed: ref<OnCustomHackingSucceeded>,
	onFailed: ref<OnCustomHackingFailed>) -> ref<CustomHackingProperties>
	{
		let instance:ref<CustomHackingProperties> = new CustomHackingProperties();

		instance.networkName = networkName;
		instance.connectionCount = connectionCount;
		instance.isQuickhack = isQuickhack;
		instance.maximumHackAttempts = maximumHackAttempts;
		instance.minigameDef_TDBID = minigameDef_TDBID;
		instance.hackedTarget = hackedTarget;
		instance.additionalData = additionalData;
		instance.onSucceed = onSucceed;
		instance.onFailed = onFailed;

		

		return instance;
	}

	public static func Default() -> ref<CustomHackingProperties>
	{
		let onSucceed : ref<OnCustomHackingSucceeded> = new OnCustomHackingSucceeded();
		let onFailed : ref<OnCustomHackingFailed> = new OnCustomHackingFailed();

		return CustomHackingProperties.Create(
		"Default Local Network",
		1,
		false,
		0,
		-1,
		t"minigame_v2.DefaultItemMinigame",
		null,
		[],
		onSucceed,
		onFailed);
	}
	
	public static func DefaultQuickhack() -> ref<CustomHackingProperties>
	{
		let onSucceed : ref<OnCustomHackingSucceeded> = new OnCustomHackingSucceeded();
		let onFailed : ref<OnCustomHackingFailed> = new OnCustomHackingFailed();

		return CustomHackingProperties.Create(
		"Default Local Network",
		1,
		true,
		0,
		-1,
		t"minigame_v2.DefaultItemMinigame",
		null,
		[],
		onSucceed,
		onFailed);
	}

}