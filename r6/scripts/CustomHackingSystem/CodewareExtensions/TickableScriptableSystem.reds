module Elysium.Utilities.ScriptableSystems

public abstract class TickableScriptableSystem extends ScriptableSystem
{
    public func OnTick(InDeltaTime: Float) -> Void;
}

public class TickableScriptableSystemManager extends ScriptableSystem
{
    protected let RegisteredSystems : array<ref<TickableScriptableSystem>>;

    public func RegisterNewScriptableSystem(InNewScriptableSystem: ref<TickableScriptableSystem>)
    {
        ArrayPush(this.RegisteredSystems, InNewScriptableSystem);
    }

    public func UnregisterScriptableSystem(InScriptableSystem: ref<TickableScriptableSystem>)
    {
        if (ArrayContains(this.RegisteredSystems, InScriptableSystem))
        {
            ArrayRemove(this.RegisteredSystems, InScriptableSystem);
        }
    }

    public func OnTick(InDeltaTime: Float) -> Void
    {
        for RegisteredSystem in this.RegisteredSystems
        {
            RegisteredSystem.OnTick(InDeltaTime);
        }
    }

    public static func Get() -> ref<TickableScriptableSystemManager>
    {
        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(GetGameInstance());
        let tickManager = container.Get(n"Elysium.Utilities.ScriptableSystems.TickableScriptableSystemManager") as TickableScriptableSystemManager;
        return tickManager;
    }

}