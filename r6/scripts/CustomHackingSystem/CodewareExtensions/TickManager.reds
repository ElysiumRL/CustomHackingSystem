// -----------------------------------------------------------------------------
// TickManager
// -----------------------------------------------------------------------------
//
// - Allows Tick (frame) update for any CompoundWidget registered
//
// -----------------------------------------------------------------------------


module Elysium.Utilities.InkObjects
import Elysium.UI.*
import Elysium.Utilities.ScriptableSystems.*

//System used to register custom controllers to allow Tick Events on them (so that you can send events every frame)
public class InkObjectTickManager extends TickableScriptableSystem
{
    public let allowObjectRegistrations: Bool = false;

    public let objectsRegistered: array<wref<CompoundWidget>>;

    //Registers the object to the list of controllers to update
    //Make sure you implemented HackingMinigameCustomController::ShouldRegisterForTickEvent 
    //and set the return value as true in order to register the target to the tick manager
    public func RegisterWidget(target: wref<CompoundWidget>) -> Bool
    {
        if (!this.allowObjectRegistrations)
        {
            //LogChannel(n"DEBUG","[InkObjectTickManager::RegisterObject] target can't be registered. Object Registrations is not yet available");
            return false;
        }
        if (!target.ShouldRegisterForTickEvent())
        {
            //LogChannel(n"DEBUG","[InkObjectTickManager::RegisterObject] target can't be registered. Make sure you implemented inkCustomController::ShouldRegisterForTickEvent and set the return value as true in order to register the target to the tick manager");
            return false;
        }
        ArrayPush(this.objectsRegistered,target);
        return true;
    }

    //Unregisters the object from the list of controllers to update
    public func UnregisterWidget(target: wref<CompoundWidget>) -> Bool
    {
        if (!this.allowObjectRegistrations && !ArrayContains(this.objectsRegistered,target))
        {
            return false;
        }
        ArrayRemove(this.objectsRegistered,target);
        return true;
    }
    //Called by the game when the scriptable system is created
    public func OnAttach() -> Void
    {
        TickableScriptableSystemManager.Get().RegisterNewScriptableSystem(this);
        //ArrayClear(this.objectsRegistered);
        //this.allowObjectRegistrations = true;
    }

    //Called by the game when the scriptable system is removed
    public func OnDetach() -> Void
    {
        TickableScriptableSystemManager.Get().UnregisterScriptableSystem(this);
        //ArrayClear(this.objectsRegistered);
        //this.allowObjectRegistrations = false;
    }

    public func OnTick(InDeltaTime: Float)
    {
        for inkObject in this.objectsRegistered
        {
            inkObject.Update(InDeltaTime);
        }
    }

    public static func Get() -> ref<InkObjectTickManager>
    {
        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(GetGameInstance());
        let inkObjectTickManager = container.Get(n"Elysium.UI.InkObjectTickManager") as InkObjectTickManager;

        return inkObjectTickManager;

    }

}