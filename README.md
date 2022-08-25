# CustomHackingSystem
A Cyberpunk 2077 mod/tool that allows you to run hacking minigame instances with custom programs

## Getting Started

### Requirements
 - Cyberpunk 2077 (Latest PC Version)
 - [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107)
 - [Redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511)

### Installing the mod
 1. Make sure all the Requirements above are installed
 2. Download this mod here or on nexus page
 3. Extract the zip archive into the game's directory
 
## Features
  - Running custom minigame instances (Quickhacks included)
  - Custom Program scripting with Succeed and Fail state handling
  - Custom minigame Succeed & Fail events 

# Creating mods
## Regular Hacks
### Lua
Lua is primarly used here in order to make TweakDB extensions (aka, your own minigame instance as well as the base for your programs).

You can check out {lua}

### Redscript
Redscript is the core of the tool. You will generally use redscript in order to :
  - Register your program actions to the system
  - Create the scripts for your programs
  - Run custom minigame instances
  
#### 1. Scriptable Program Actions
If you followed the Lua section, you should now have a TweakDBID that can be used in the system. Before using the TweakDBID, you will have to create a class that will be used as the base for future scripting.

Here is an example :

```swift
public class MyRedscriptProgramAction extends HackProgramAction
{
    //Called if you succeed the program
    protected func ExecuteProgramSuccess() -> Void
    {
        LogChannel(n"DEBUG","Success !");
    }
  
    //Called if you fail the program
    protected func ExecuteProgramFailure() -> Void
    {
        LogChannel(n"DEBUG","Failure !");
    }
}
```

The class have to extend `HackProgramAction` and contain at least those functions.
Once you finish the minigame, the system will automatically create and call the functions (succeed/failure) for each program in the minigame

Now that you have both the TweakDBID and the class containing the scripts, you can register the program into the system :

```swift
module MyModule.Template

import HackingExtensions.*
import HackingExtensions.Programs.*

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool 
{
    //Call the base method BEFORE adding your program, the system is initialized on PlayerPuppet too, doing this ensures that your program registration is done after the system's initialization
    wrappedMethod();
    
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
    let hackingSystem: ref<CustomHackingSystem> = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
    
    //Register the Program Action into the system
    //+ Register the class to call for the Program Action
    hackingSystem.AddProgramAction(t"MinigameProgramAction.MyProgramAction", new MyRedscriptProgramAction());
}
```
#### 2. Minigame Completion Events

The system also supports events when the minigame is completed (regardless of the program completions).

There are 2 type of events :
  - On Success
  > At least 1 program have been successfully completed
  
  - On Failure 
  > No programs have been completed or the minigame have been cancelled
  
In a somewhat similar way to the Scriptable Program Actions, you can create your own scripts :

```swift
module MyModule.Template

import HackingExtensions.*

public class OnMyCustomHackSucceeded extends OnCustomHackingSucceeded
{
    //Called when the minigame have been succeeded
    public func Execute() -> Void
    {
        LogChannel(n"DEBUG","Minigame succeeded");
    }
}

public class OnMyCustomHackFailed extends OnCustomHackingFailed
{
    //Called when the minigame have been failed
    public func Execute() -> Void
    {
        LogChannel(n"DEBUG","Minigame failed");
    }
}
```
However, the registration of those events are done at the same time you want to run a minigame instance

#### 3. Running Instances
You can run a minigame instance using this function :
```swift
//instanceName : Name of the Instance
//customMinigame : Minigame TweakBD path
//hackedTarget : Targeted object (Any IScriptable but generally any Persistent State or Devices) (optional)
//additionalData :Variant array if you want to pass on some extra variables to your programs (optional)
//onSucceed : Class called if the minigame is succeeded (optional)
//onFailed : Class called if the minigame is failed (optional)
//Return Value : Returns true if the minigame is launched successfully
public func StartNewHackInstance(
  instanceName:String,
  opt customMinigame:TweakDBID,
  opt hackedTarget:ref<IScriptable>,
  opt additionalData:array<Variant>,
  opt onSucceed:ref<OnCustomHackingSucceeded>,
  opt onFailed:ref<OnCustomHackingFailed>
) -> Bool
```

the simplest way to use this function is the following :
```swift
//this.gameInstance refers to a valid Game Instance (generally this.GetGame() from PlayerPuppet)
//this.hackedTarget refers to any IScriptable and is useful when you want to get the hacked target in your programs

let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.gameInstance);
this.customSystem = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;

this.customSystem.StartNewHackInstance("New Hack Instance",t"CustomHackingSystemMinigame.MyMinigame",this.hackedTarget);
```

Here is an example of running a minigame instance when you press the primary button
```swift
module MyModule.Template

import HackingExtensions.*
import HackingExtensions.Programs.*

@addField(PlayerPuppet)
protected let m_CustomInputListener: ref<GlobalInputListener>;

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool 
{
    wrappedMethod();

    this.m_CustomInputListener = new GlobalInputListener();
    this.m_CustomInputListener.gameInstance = this.GetGame();
    this.m_CustomInputListener.hackedTarget = this;

    this.RegisterInputListener(this.m_CustomInputListener);
}

public class GlobalInputListener
{
    private let gameInstance: GameInstance;	
    private let hackingSystem:ref<CustomHackingSystem>;
    private let hackedTarget:ref<IScriptable>;
    
    protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool 
    {
      if (Equals(ListenerAction.GetName(action), n"Choice1") && ListenerAction.IsButtonJustReleased(action))
      {
          let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.gameInstance);
          this.hackingSystem = container.Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
          
          this.hackingSystem.StartNewHackInstance("New Hack Instance",t"CustomHackingSystemMinigame.MyMinigame",this.hackedTarget);
      }
    }
}
```
#### 4. Instance Settings

The parameters sent as inputs in the `StartNewHackInstance` function are stored in a `CustomHackingProperties` variable. You can access it in the Scriptable Program Actions using `this.hackInstanceSettings`. On top of the arguments passed in the `StartNewHackInstance` You will also find :
 - hackAttempts (Int32)
 > the number of attempts (in a row) for a given hack. This number will be reset if the NetworkName changes. If you want to store the real amount of hack attempts (without resets) you should add a field to the targeted object's persistent state.
 - maximumHackAttempts (Int32)
 > Maximum amount of attempts (in a row) for a given hack. if the hackAttempts is equal or superior to this value, the hack won't start.

## Quickhacks

### Lua
#### 1. Basics
In order to get all of the available functions of the module in lua simply copy this line :
```lua
local Quickhack = GetMod("CustomHackingSystem")
 ```
Every functions are in (according to the line above) : `Quickhack.API`
#### 2. Custom Quickhack TweakDBID
In order to make the TweakDBID of the quickhack, you will (principally) need 4 things :
 - A Name
 - Quickhack Gameplay Category
 - Interaction (UI)
 - Cost
 - (Optional) Cooldown before usage
 - (Optional) Upload Time

Here is an example to create a quickhack
```lua
--UIIcon (returns "CustomUIIcon.*quickhackName*")
local templateIcon = Quickhack.API.CreateUIIcon("CommunicationCallOut","base\\gameplay\\gui\\common\\icons\\quickhacks_icons.inkatlas")
--Gameplay Category (returns "ActionCategories.*quickhackName*")
local templateCategory = Quickhack.API.CreateQuickhackGameplayCategory("QuickhackTemplate",forceBrakesIcon,LocKey(1234),LocKey(5555))
--Quickhack Base Cost (returns "DeviceAction.*quickhackName*_*BaseCost*")
local templateCost = Quickhack.API.CreateQuickhackMemoryStatModifier("QuickhackTemplate","BaseCost","Additive",4.00)
--UI Interaction (returns "CustomInteractions.*quickhackName*")
local templateInteraction = Quickhack.API.CreateInteractionUI("QuickhackTemplate",LocKey(1234),LocKey(5555),templateIcon)
--Quickhack (returns "DeviceAction.*quickhackName*")
local templateQuickhack = Quickhack.API.CreateQuickhack("QuickhackTemplate",templateCategory,templateInteraction,templateCost,11.00,0.75)
```
Note : the cost,cooldown & upload duration is reduced depending on the perks you obtained


### Redscript



## Miscellaneous
A lot of the code (and in-depth) work was cut off from this ("wiki") to make it as short and concise as possible. If you want to know more about the tool itself don't hesitate to check the out source code (small warning : it's a bit of a spaghetti code).
You can also check out the [VehicleSecurityRework](https://github.com/ElysiumRL/VehicleSecurityRework) mod to see an example of the tool in a medium sized project.

## Contributing
Found a Bug ? Have any ideas ? Want to contribute ? You can make a pull request here or contact me on Discord about it
