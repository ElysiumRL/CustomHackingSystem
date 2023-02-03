module HackingExtensions.CustomMinigame
import Codeware.UI.*
import HackingExtensions.*
import HackingExtensions.Programs.*


//Default Custom Minigame Template : All your new minigames should extend this class
public abstract class CustomMinigame extends inkCustomController
{

    //Widget Root
    protected let root: wref<inkCompoundWidget>;

    //Widget Parent
    protected let popupParent: ref<CustomMinigameHackPopup>;

    //Minigame State
    protected let minigameState: HackingMinigameState = HackingMinigameState.Unknown;
    
    //Minigame Instance State. This is useful when you want to replay multiple times the same small minigame but for different programs
    protected let minigameInstanceState: HackingMinigameState = HackingMinigameState.Unknown;

    //List of all the programs in the minigame
    protected let allProgramsTDBID: array<TweakDBID>;

    //List of resolved programs
    protected let resolvedPrograms: array<TweakDBID>;

    //Current program being tested (generally use this if the minigame is separated into instances)
    protected let currentProgramIndex: Int32;

    //Here should be the place where all the minigame default values are set
    public func SetMinigameDefaults() -> Void
    {

    }

    //Here should be the place where all the minigame instance default values are set
    public func SetMinigameInstanceDefaults() -> Void
    {
        
    }

    //Sets new Minigame state and calls Success/Failure functions
    public func SetMinigameState(newState: HackingMinigameState) -> Void
    {
        this.minigameState = newState;

        switch(newState)
        {
        case HackingMinigameState.Unknown:
            break;     
        case HackingMinigameState.InProgress:
            this.StartGameInstance();
            break;
        case HackingMinigameState.Succeeded:
            this.OnMinigameSuccess();
            break;
        case HackingMinigameState.Failed:
            this.OnMinigameFailure();
            break;
        }
    }

    //Sets new GameInstance state and calls Success/Failure functions
    public func SetMinigameInstanceState(newState: HackingMinigameState) -> Void
    {
        this.minigameInstanceState = newState;
        switch(newState)
        {
        case HackingMinigameState.Unknown:
            break;     
        case HackingMinigameState.InProgress:
            this.StartGameInstance();
            break;
        case HackingMinigameState.Succeeded:
            this.OnGameInstanceSuccess();
            break;
        case HackingMinigameState.Failed:
            this.OnGameInstanceFailure();
            break;
        }
    }

    //Called when the minigame is considered succeeded
    public func OnMinigameSuccess() -> Void
    {

    }

    //Called when the minigame is considered failed
    public func OnMinigameFailure() -> Void
    {

    }

    //Starts a new Game Instance
    public func StartGameInstance() -> Void
    {

    }

    //Called when the game instance is succeeded
    public func OnGameInstanceSuccess() -> Void
    {
        this.OnEndGameInstance();
    }
    //Called when the game instance is failed
    public func OnGameInstanceFailure() -> Void
    {
        this.OnEndGameInstance();
    }

    //Called after Game instance Success/Failure function
    public func OnEndGameInstance() -> Void
    {

    }

    //Updated every tick
	public func TickUpdate(deltaTime: Float) -> Void
	{
        super.TickUpdate(deltaTime);
    }

    //Override this as "true" to register the object for tick updates
    public const func ShouldRegisterForTickEvent() -> Bool
	{
		return true;
	}

    //This is a copy/paste from CustomHackingSystem but with some minor tweaks
    //This version doesn't have to handle all the weird things that happen with the base HackingMinigame
    protected func HandleResolvedPrograms() -> Void
    {
        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
	    let hackSystem:ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;

		hackSystem.CheckForPerks(ArraySize(this.resolvedPrograms));
		for program in this.allProgramsTDBID
		{
            let programAction = TweakDBInterface.GetProgramRecord(program).Program().GetID();

			let currentProgram:ref<HackProgramAction> = hackSystem.programsHashMap.Get(TDBID.ToNumber(programAction)) as HackProgramAction;
			if(IsDefined(currentProgram))
			{
				currentProgram.gameInstance = this.GetGame();
				currentProgram.hackInstanceSettings = hackSystem.settings;
				if(ArrayContains(this.resolvedPrograms,program))
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
					RPGManager.GiveReward(this.GetGame(), reward.GetID(), Cast<StatsObjectID>(this.GetPlayer().GetEntityID()));
				}
			}
			else
			{
				LogChannel(n"DEBUG","Current Program " + TDBID.ToStringDEBUG(program) + " not found");
			}
		}
    }
}