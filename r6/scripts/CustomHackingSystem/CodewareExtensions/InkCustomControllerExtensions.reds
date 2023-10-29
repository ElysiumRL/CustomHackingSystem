module Codeware.UI
import Codeware.Scheduling.*

public abstract class HackingMinigameCustomController extends inkCustomController
{
    private let m_isRegisteredForTickEvent:Bool;

    private let m_isInitialized: Bool;

    protected let m_isDragged: Bool;

    protected let m_dragStartMargin: inkMargin;

    protected let m_dragStartCursor: Vector2;
	
    public const func ShouldRegisterForTickEvent() -> Bool
	{
		return false;
	}

	public const func AllowDrag() -> Bool
	{
		return false;
	}

    protected func IsInitialized() -> Bool
    {
    	return this.m_isInitialized;
    }

    protected func IsTicking() -> Bool
    {
    	return this.m_isRegisteredForTickEvent;
    }

    //Called Every frame
	//You can override this method to allow tick update to the controller
    public func TickUpdate(deltaTime: Float) -> Void
    {

    }

	protected cb func OnInitialize() -> Void
	{
		if (this.ShouldRegisterForTickEvent())
		{
			let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
        	let inkObjectTickManager = container.Get(n"Codeware.Scheduling.InkObjectTickManager") as InkObjectTickManager;

			this.m_isRegisteredForTickEvent = inkObjectTickManager.RegisterObject(this);
			if(!this.m_isRegisteredForTickEvent)
			{
				//LogChannel(n"DEBUG","[inkCustomController::OnInitialize()] Object failed to register to Tick Event");
			}
		}
	}

	protected cb func OnUninitialize() -> Void
	{
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

    		//let margin = this.m_rootWidget.GetMargin();
    		//let newPosition:String = NameToString(this.m_rootWidget.GetName()) + " : new Vector2(" + FloatToStringPrec(margin.left,2) + "," + FloatToStringPrec(margin.top,2) + ")";
    		//LogChannel(n"DEBUG",newPosition);
			
    		this.m_isDragged = false;
    		this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
    		this.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
    	}
    }

}