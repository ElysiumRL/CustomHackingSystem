module Elysium.UI

import Codeware.UI.*
import Elysium.Utilities.InkObjects.*
import Elysium.Utilities.Message.*

/**
 * Compound Widget : A simple wrapper of inkCustomController implementing basic features for UI-related operations
 * Current features : Ticking, Drag & Drop
 */
public abstract class CompoundWidget extends inkCustomController
{
    private let m_isRegisteredForTickEvent:Bool;

    private let m_isInitialized: Bool;

    public let m_isDragged: Bool;

    public let m_dragStartMargin: inkMargin;

    public let m_dragStartCursor: Vector2;
	
    public func ShouldRegisterForTickEvent() -> Bool
	{
		return false;
	}

	public func AllowDrag() -> Bool
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

    // Called every tick by CET's onUpdate event
	// You can override this method to allow tick update to the controller
    // (requires ShouldRegisterForTickEvent to return true)
    public func Update(deltaTime: Float) -> Void
    {

    }

	protected cb func OnInitialize() -> Void
	{
		if (this.ShouldRegisterForTickEvent())
		{
        	let inkObjectTickManager = InkObjectTickManager.Get();

			this.m_isRegisteredForTickEvent = inkObjectTickManager.RegisterWidget(this);
			if(!this.m_isRegisteredForTickEvent)
			{
				//LogChannel(n"DEBUG","[inkCustomController::OnInitialize()] Object failed to register to Tick Event");
			}
		}
	}

	protected cb func OnUninitialize() -> Void
	{
		if (this.m_isRegisteredForTickEvent)
		{
        	let inkObjectTickManager = InkObjectTickManager.Get();

			this.m_isRegisteredForTickEvent = inkObjectTickManager.UnregisterWidget(this);
		}
		this.m_detachedWidget = null;
	}

    protected func InitializeInstance() -> Void
    {
    	if (this.m_isCreated && !this.m_isInitialized)
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

	protected func InitializeChildren(rootWidget: wref<inkCompoundWidget>) -> Void
    {
		if (IsDefined(rootWidget))
		{
			let index: Int32 = 0;
			let numChildren: Int32 = rootWidget.GetNumChildren();
			let childWidget: wref<inkWidget>;
			let childControllers: array<wref<inkLogicController>>;
			let customController: wref<inkCustomController>;

			while (index < numChildren)
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
    	if (this.AllowDrag() && evt.IsAction(n"mouse_left"))
    	{
    		this.m_isDragged = true;
    		this.m_dragStartMargin = this.m_rootWidget.GetMargin();
    		this.m_dragStartCursor = evt.GetScreenSpacePosition();
    		this.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
    		this.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
            MessageUtilities.DisplaySideNotificationMessage("Grabbed");
    	}
    }

    protected cb func OnGlobalMove(evt: ref<inkPointerEvent>) -> Void
    {
        //LogChannel(n"DEBUG",CompoundWidgetUtilities.GetDraggedWidgetViewportPositionAsRedscriptString(this, evt));
    }

    protected cb func OnGlobalRelease(evt: ref<inkPointerEvent>) -> Bool
    {
    	if (this.AllowDrag() && evt.IsAction(n"mouse_left"))
    	{
    		this.m_isDragged = false;
    		this.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"OnGlobalMove");
    		this.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalRelease");
            MessageUtilities.DisplaySideNotificationMessage("Released");
    	}
    }

}