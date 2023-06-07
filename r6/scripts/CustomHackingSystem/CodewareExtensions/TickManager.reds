// -----------------------------------------------------------------------------
// TickManager
// -----------------------------------------------------------------------------
//
// - Probably in the top 10 of the worst things I had to do in this game
// - Allows Tick (frame) update for any inkCustomController registered
// - (yes I know about the game internal tick registrator but this was faster to make than learning how to use it)
//
// -----------------------------------------------------------------------------


module Codeware.Scheduling
import Codeware.UI.*

public class TickUpdateEvent extends Event
{
	public let gameInstance : GameInstance;

	public let previousEngineTime : EngineTime;
	public let currentEngineTime : EngineTime;

	public func SetGameInstance(newGameInstance: GameInstance) -> Void
	{
		if (GameInstance.IsValid(newGameInstance))
		{
			this.gameInstance = newGameInstance;
            this.currentEngineTime = GameInstance.GetEngineTime(this.gameInstance);
            this.previousEngineTime = this.currentEngineTime;
		}
		else
		{
			LogChannel(n"DEBUG","[TickUpdateEvent::SetGameInstance] Game Instance passed is not valid");
		}
	}

    //Swaps previous engine time by current engine time
    //This is used to then get the delta time between previous frame and current frame
    //!!!! THIS HAS TO BE CALLED ONLY ONCE PER FRAME (and you shouldn't use it)
    private func SwapEngineTime() -> Void
    {
        if (GameInstance.IsValid(this.gameInstance))
		{
            this.previousEngineTime = this.currentEngineTime;
            this.currentEngineTime = GameInstance.GetEngineTime(this.gameInstance);
		}
    }

	//Returns the time between last frame and this frame
	public func GetDeltaTime() -> Float
	{
		let deltaTime: Float = 0.0;
		if(GameInstance.IsValid(this.gameInstance))
		{
			deltaTime = EngineTime.ToFloat(this.currentEngineTime) - EngineTime.ToFloat(this.previousEngineTime);
		}
		//LogChannel(n"DEBUG","Delta Time :" + ToString(deltaTime));
		return deltaTime;
	}
}

//System used to register custom controllers to allow Tick Events on them (so that you can send events every frame)
public class InkObjectTickManager extends ScriptableSystem
{
    public let allowObjectRegistrations: Bool = false;

    public let objectsRegistered: array<wref<HackingMinigameCustomController>>;

    //Registers the object to the list of controllers to update
    //Make sure you implemented HackingMinigameCustomController::ShouldRegisterForTickEvent 
    //and set the return value as true in order to register the target to the tick manager
    public func RegisterObject(target: wref<HackingMinigameCustomController>) -> Bool
    {
        if(!this.allowObjectRegistrations)
        {
            LogChannel(n"DEBUG","[InkObjectTickManager::RegisterObject] target can't be registered. Object Registrations is not yet available");
            return false;
        }
        if(!target.ShouldRegisterForTickEvent())
        {
            LogChannel(n"DEBUG","[InkObjectTickManager::RegisterObject] target can't be registered. Make sure you implemented inkCustomController::ShouldRegisterForTickEvent and set the return value as true in order to register the target to the tick manager");
            return false;
        }
        ArrayPush(this.objectsRegistered,target);
        return true;
    }

    //Unregisters the object from the list of controllers to update
    public func UnregisterObject(target: wref<HackingMinigameCustomController>) -> Bool
    {
        if(!this.allowObjectRegistrations && !ArrayContains(this.objectsRegistered,target))
        {
            return false;
        }
        ArrayRemove(this.objectsRegistered,target);
        return true;
    }
    //Called by the game when the scriptable system is created
    private func OnAttach() -> Void
    {
        //ArrayClear(this.objectsRegistered);
        //this.allowObjectRegistrations = true;
    }

    //Called by the game when the scriptable system is removed
    private func OnDetach() -> Void
    {
        //ArrayClear(this.objectsRegistered);
        //this.allowObjectRegistrations = false;
    }
}

//Player Puppet overrides
@addField(PlayerPuppet)
protected let inkObjectTickManager: ref<InkObjectTickManager>;

//Called when the player is spawned to the game
//Usually the place where you register/create references into the player/the game in general
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool 
{
    wrappedMethod();

    if (!this.IsReplacer())
    {	
        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
        this.inkObjectTickManager = container.Get(n"Codeware.Scheduling.InkObjectTickManager") as InkObjectTickManager;
        this.inkObjectTickManager.allowObjectRegistrations = true;

        //Begin tick update
        let tickEvent: ref<TickUpdateEvent> = new TickUpdateEvent();

        tickEvent.SetGameInstance(this.GetGame());

        GameInstance.GetDelaySystem(this.GetGame()).DelayEventNextFrame(this, tickEvent);
    }
}

//Called when the player is usually despawned from the game
//Usually the place where you unregister/destroy what you registered in the OnAttach
@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool 
{
    wrappedMethod();
    this.inkObjectTickManager = null;
}

//This function is called every tick (or "frame" if you prefer)
@addMethod(PlayerPuppet)
protected cb func OnTickUpdateEvent(evt: ref<TickUpdateEvent>) -> Void 
{
    //Execute the update
    evt.SwapEngineTime();

    let deltaTime:Float = evt.GetDeltaTime();

    for object in this.inkObjectTickManager.objectsRegistered
    {
        object.TickUpdate(deltaTime);
    }
    
   
    //Then queue it for next tick
    //this way this function is called every tick on to the player
    //if there is a better way (or simply a native "tick/update" function it would be a bit more optimized than doing this)
    GameInstance.GetDelaySystem(this.GetGame()).DelayEventNextFrame(this, evt);
}