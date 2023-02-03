// -----------------------------------------------------------------------------
// Codeware.UI.inkCustomController
// -----------------------------------------------------------------------------
//
// public abstract class inkCustomController extends inkLogicController {
//   public func GetRootWidget() -> wref<inkWidget>
//   public func GetRootCompoundWidget() -> wref<inkCompoundWidget>
//   public func GetContainerWidget() -> wref<inkCompoundWidget>
//   public func GetGameController() -> wref<inkGameController>
//   public func GetPlayer() -> ref<PlayerPuppet>
//   public func GetGame() -> GameInstance
//   public func CallCustomCallback(eventName: CName) -> Void
//   public func RegisterToCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
//   public func UnregisterFromCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
//   public func RegisterToGlobalInputCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
//   public func UnregisterFromGlobalInputCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
//   public func PlaySound(widgetName: CName, eventName: CName, opt actionKey: CName) -> Void
//   public func Reparent(newParent: wref<inkCompoundWidget>) -> Void
//   public func Reparent(newParent: wref<inkCompoundWidget>, index: Int32) -> Void
//   public func Reparent(newParent: wref<inkCompoundWidget>, gameController: ref<inkGameController>) -> Void
//   public func Reparent(newParent: wref<inkCustomController>) -> Void
//   public func Reparent(newParent: wref<inkCustomController>, index: Int32) -> Void
//   public func Mount(rootWidget: ref<inkCompoundWidget>, opt gameController: wref<inkGameController>) -> Void
//   public func Mount(rootController: ref<inkLogicController>, opt gameController: ref<inkGameController>) -> Void
//   public func Mount(rootController: ref<inkGameController>) -> Void
//   protected cb func OnCreate() -> Void
//   protected cb func OnInitialize() -> Void
//   protected cb func OnUninitialize() ->  Void
//   protected cb func OnReparent(parent: ref<inkCompoundWidget>) ->  Void
//   protected func SetRootWidget(rootWidget: ref<inkWidget>) -> Void
//   protected func SetContainerWidget(containerWidget: ref<inkCompoundWidget>) -> Void
//   protected func SetGameController(gameController: ref<inkGameController>) -> Void
//   protected func SetGameController(parentController: ref<inkCustomController>) -> Void
// }
//

module Codeware.UI
import Codeware.Scheduling.*

public abstract class inkCustomController extends inkLogicController
{
	
	public const func ShouldRegisterForTickEvent() -> Bool
	{
		return false;
	}

	public const func AllowDrag() -> Bool
	{
		return false;
	}

	//Called Every frame
	public func TickUpdate(deltaTime: Float) -> Void

	private let m_isRegisteredForTickEvent:Bool;
	
	private let m_isCreated: Bool;

	private let m_isInitialized: Bool;

	private let m_detachedWidget: ref<inkWidget>;

	private let m_gameController: wref<inkGameController>;

	protected let m_rootWidget: wref<inkWidget>;

	protected let m_containerWidget: wref<inkCompoundWidget>;


	////////////////////////////////////////////////////////////
	
	//Drag

	protected let m_isDragged: Bool;

	protected let m_dragStartMargin: inkMargin;

	protected let m_dragStartCursor: Vector2;

	////////////////////////////////////////////////////////////

	protected func IsInitialized() -> Bool
	{
		return this.m_isInitialized;
	}

	protected func IsTicking() -> Bool
	{
		return this.m_isRegisteredForTickEvent;
	}

	protected func SetRootWidget(rootWidget: ref<inkWidget>) -> Void {
		this.m_rootWidget = rootWidget;

		if IsDefined(this.m_rootWidget)
		{
			if !IsDefined(this.m_rootWidget.GetController())
			{
				this.m_rootWidget.SetController(this);
			}
			else
			{
				if NotEquals(this, this.m_rootWidget.GetControllerByType(this.GetClassName()))
				{
					this.m_rootWidget.AddSecondaryController(this);
				}
			}
			if !inkWidgetHelper.InWindowTree(this.m_rootWidget)
			{
				this.m_detachedWidget = this.m_rootWidget;
			}
		}
		else
		{
			this.m_detachedWidget = null;
		}
	}

	protected func SetContainerWidget(containerWidget: ref<inkCompoundWidget>) -> Void
	{
		this.m_containerWidget = containerWidget;
	}

	protected func SetGameController(gameController: ref<inkGameController>) -> Void
	{
		this.m_gameController = gameController;
	}

	protected func SetGameController(parentController: ref<inkCustomController>) -> Void
	{
		this.m_gameController = parentController.GetGameController();
	}

	protected func CreateInstance() -> Void
	{
		if !this.m_isCreated
		{
			this.OnCreate();
			this.CallCustomCallback(n"OnCreate");

			if IsDefined(this.m_rootWidget)
			{
				this.m_isCreated = true;
			}
		}
	}



	protected func InitializeInstance() -> Void
	{
		if this.m_isCreated && !this.m_isInitialized
		{
			if inkWidgetHelper.InWindowTree(this.m_rootWidget)
			{
				this.InitializeChildren(this.GetRootCompoundWidget());

				this.OnInitialize();
				this.CallCustomCallback(n"OnInitialize");

				this.m_isInitialized = true;
				this.m_detachedWidget = null;
				if (this.AllowDrag())
				{
					this.SetupObjectDrag();
				}
			}
		}
	}

	protected func SetupObjectDrag() -> Void
	{
		this.RegisterToCallback(n"OnPress", this, n"OnPress");
		//this.m_rootWidget.SetInteractive(true);
	}

	protected cb func OnPress(evt: ref<inkPointerEvent>) -> Bool
	{
		if (evt.IsAction(n"mouse_left") && this.AllowDrag())
		{
			this.m_isDragged = true;

			this.m_dragStartMargin = this.m_rootWidget.GetMargin();
			this.m_dragStartCursor = evt.GetScreenSpacePosition();

			this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
			this.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
		}
	}

	protected cb func OnGlobalMove(evt: ref<inkPointerEvent>) -> Void
	{
		if (this.AllowDrag())
		{
			let cursor: Vector2 = evt.GetScreenSpacePosition();
			let margin: inkMargin = this.m_dragStartMargin;
			//let size: Vector2 = this.m_rootWidget.GetSize();
			if(!evt.IsLeftShiftDown())
			{
				margin.left += (cursor.X - this.m_dragStartCursor.X) * 2.0;
			}
			//margin.left = MaxF(margin.left, 0);
			//margin.left = MinF(margin.left, size.X);
			if(!evt.IsControlDown())
			{
				margin.top += (cursor.Y - this.m_dragStartCursor.Y) * 2.0;
			}
			//margin.top = MaxF(margin.top, 0);
			//margin.top = MinF(margin.top, size.Y);

			this.m_rootWidget.SetMargin(margin);
		}
	}

	protected cb func OnGlobalRelease(evt: ref<inkPointerEvent>) -> Bool
	{
		if (evt.IsAction(n"mouse_left") && this.AllowDrag())
		{
			//Cursor Alignment
			
			//let cursor: Vector2 = evt.GetScreenSpacePosition();
			//switch(this.m_rootWidget.GetHAlign())
			//{
			//case inkEHorizontalAlign.Fill:
			//	break;
			//case inkEHorizontalAlign.Left:
			////cursor.X -= 1920.0;
			//	break;
			//case inkEHorizontalAlign.Center:
			//cursor.X -= 1920.0 / 2.0;
			////cursor.Y -= 1080.0 / 2.0;
			//	break;
			//case inkEHorizontalAlign.Right:
			//cursor.X -= 1920.0;
			////cursor.Y -= 1080.0 / 2.0;			
			//	break;				
			//}
			//switch(this.m_rootWidget.GetVAlign())
			//{
			//case inkEVerticalAlign.Fill:
			//	break;
			//case inkEVerticalAlign.Top:
			//	break;
			//case inkEVerticalAlign.Center:
			//cursor.Y -= 1920.0 / 2.0;
			//	break;
			//case inkEVerticalAlign.Bottom:
			//cursor.Y -= 1920.0;
			//	break;				
			//}
			let margin = this.m_rootWidget.GetMargin();
			
			let newPosition:String = NameToString(this.m_rootWidget.GetName()) + " : new Vector2(" + FloatToStringPrec(margin.left,2) + "," + FloatToStringPrec(margin.top,2) + ")";
			LogChannel(n"DEBUG",newPosition);

			this.m_isDragged = false;

			this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
			this.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
		}
	}






	protected func InitializeChildren(rootWidget: wref<inkCompoundWidget>) -> Void {
		if IsDefined(rootWidget)
		{
			let index: Int32 = 0;
			let numChildren: Int32 = rootWidget.GetNumChildren();
			let childWidget: wref<inkWidget>;
			let childControllers: array<wref<inkLogicController>>;
			let customController: wref<inkCustomController>;

			while index < numChildren
			{
				childWidget = rootWidget.GetWidgetByIndex(index);
				childControllers = childWidget.GetControllers();

				for childController in childControllers
				{
					customController = childController as inkCustomController;

					if IsDefined(customController)
					{
						customController.SetGameController(this);
						customController.InitializeInstance();
					}
				}

				if childWidget.IsA(n"inkCompoundWidget") && !IsDefined(childWidget.GetController() as inkCustomController)
				{
					this.InitializeChildren(childWidget as inkCompoundWidget);
				}

				index += 1;
			}
		}
	}

	protected cb func OnCreate() -> Void

	protected cb func OnInitialize() -> Void
	{
		if (this.ShouldRegisterForTickEvent())
		{
			let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
        	let inkObjectTickManager = container.Get(n"Codeware.Scheduling.InkObjectTickManager") as InkObjectTickManager;

			this.m_isRegisteredForTickEvent = inkObjectTickManager.RegisterObject(this);
			if(!this.m_isRegisteredForTickEvent)
			{
				LogChannel(n"DEBUG","[inkCustomController::OnInitialize()] Object failed to register to Tick Event");
			}
		}
	}

	protected cb func OnUninitialize() ->  Void {
		//this.m_isCreated = false;
		//this.m_isInitialized = false;
		if(this.m_isRegisteredForTickEvent)
		{
			let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
        	let inkObjectTickManager = container.Get(n"Codeware.Scheduling.InkObjectTickManager") as InkObjectTickManager;

			this.m_isRegisteredForTickEvent = inkObjectTickManager.UnregisterObject(this);
		}
		this.m_detachedWidget = null;
	}

	protected cb func OnReparent(parent: ref<inkCompoundWidget>) ->  Void

	public func GetRootWidget() -> wref<inkWidget>
	{
		return this.m_rootWidget;
	}

	public func GetRootCompoundWidget() -> wref<inkCompoundWidget>
	{
		return this.m_rootWidget as inkCompoundWidget;
	}

	public func GetContainerWidget() -> wref<inkCompoundWidget>
	{
		if IsDefined(this.m_containerWidget)
		{
			return this.m_containerWidget;
		}

		return this.m_rootWidget as inkCompoundWidget;
	}

	public func GetGameController() -> wref<inkGameController>
	{
		return this.m_gameController;
	}

	public func GetPlayer() -> ref<PlayerPuppet>
	{
		return this.m_gameController.GetPlayerControlledObject() as PlayerPuppet;
	}

	public func GetGame() -> GameInstance
	{
		return this.m_gameController.GetPlayerControlledObject().GetGame();
	}

	public func CallCustomCallback(eventName: CName) -> Void
	{
		if IsDefined(this.m_rootWidget)
		{
			this.m_rootWidget.CallCustomCallback(eventName);
		}
	}

	public func RegisterToCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
	{
		if IsDefined(this.m_rootWidget)
		{
			this.m_rootWidget.RegisterToCallback(eventName, object, functionName);
		}
	}

	public func UnregisterFromCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
	{
		if IsDefined(this.m_rootWidget)
		{
			this.m_rootWidget.UnregisterFromCallback(eventName, object, functionName);
		}
	}

	public func RegisterToGlobalInputCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
	{
		if IsDefined(this.m_gameController)
		{
			this.m_gameController.RegisterToGlobalInputCallback(eventName, object, functionName);
		}
	}

	public func UnregisterFromGlobalInputCallback(eventName: CName, object: ref<IScriptable>, functionName: CName) -> Void
	{
		if IsDefined(this.m_gameController)
		{
			this.m_gameController.UnregisterFromGlobalInputCallback(eventName, object, functionName);
		}
	}

	public func PlaySound(widgetName: CName, eventName: CName, opt actionKey: CName) -> Void
	{
		if IsDefined(this.m_gameController)
		{
			this.m_gameController.PlaySound(widgetName, eventName, actionKey);
		}
	}

	public func Reparent(newParent: wref<inkCompoundWidget>) -> Void
	{
		this.Reparent(newParent, -1);
	}

	public func Reparent(newParent: wref<inkCompoundWidget>, index: Int32) -> Void
	{
		this.CreateInstance();

		if IsDefined(this.m_rootWidget) && IsDefined(newParent)
		{
			this.m_rootWidget.Reparent(newParent, index);

			this.OnReparent(newParent);
			this.CallCustomCallback(n"OnReparent");

			this.InitializeInstance();
		}
	}

	public func Reparent(newParent: wref<inkCompoundWidget>, gameController: ref<inkGameController>) -> Void
	{
		if IsDefined(gameController)
		{
			this.SetGameController(gameController);
		}

		this.Reparent(newParent, -1);
	}

	public func Reparent(newParent: wref<inkCustomController>) -> Void
	{
		this.Reparent(newParent, -1);
	}

	public func Reparent(newParent: wref<inkCustomController>, index: Int32) -> Void
	{
		if IsDefined(newParent.GetGameController())
		{
			this.SetGameController(newParent.GetGameController());
		}

		this.Reparent(newParent.GetContainerWidget(), index);
	}

	public func Mount(rootWidget: ref<inkCompoundWidget>, opt gameController: wref<inkGameController>) -> Void
	{
		if !this.m_isInitialized && IsDefined(rootWidget)
		{
			this.SetRootWidget(rootWidget);
			this.SetGameController(gameController);

			this.CreateInstance();
			this.InitializeInstance();
		}
	}

	public func Mount(rootController: ref<inkLogicController>, opt gameController: ref<inkGameController>) -> Void
	{
		this.Mount(rootController.GetRootCompoundWidget(), gameController);
	}

	public func Mount(rootController: ref<inkGameController>) -> Void
	{
		this.Mount(rootController.GetRootCompoundWidget(), rootController);
	}
}