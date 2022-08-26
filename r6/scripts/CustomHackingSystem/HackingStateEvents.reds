//It's not events, but it acts like events

module HackingExtensions

public class CustomHackingStateEvent extends IScriptable
{
	//Game Instance
	public let gameInstance:GameInstance;

	//Settings from main CustomHackingSystem class. Useful when you want to get additional data
	public let hackInstanceSettings:ref<CustomHackingProperties>;

	public func Execute() -> Void
	{
		//LogChannel(n"DEBUG","Custom state changed");
	}

}

public class OnCustomHackingSucceeded extends CustomHackingStateEvent
{
	public func Execute() -> Void
	{
		//LogChannel(n"DEBUG","Hack succeeded");
	}
}

public class OnCustomHackingFailed extends CustomHackingStateEvent
{
	public func Execute() -> Void
	{
		//LogChannel(n"DEBUG","Hack failed");
	}
}