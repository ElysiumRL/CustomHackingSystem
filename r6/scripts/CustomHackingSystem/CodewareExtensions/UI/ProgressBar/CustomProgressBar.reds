// -----------------------------------------------------------------------------
// Codeware.UI.CustomProgressBar
// -----------------------------------------------------------------------------
//
// - Basic implementation of a Progress Bar
//
// -----------------------------------------------------------------------------

module Codeware.UI

import Elysium.UI.*

public abstract class CustomProgressBar extends CompoundWidget
{

    public func AllowDrag() -> Bool
	{
		return false;
	}

    public let m_root: wref<inkCompoundWidget>;
    
    public let size: Vector2;
    
    public let position: Vector2;

    public let currentValue: Float;
    
    public let previousValue: Float;
    
    public let progressBarFrame: ref<inkImage>;
    
    public let progressBarFill: ref<inkImage>;

	protected cb func OnCreate() -> Void
    {
		this.CreateWidgets();
	}

	protected cb func OnInitialize() -> Void
    {
        super.OnInitialize();

		this.RegisterListeners();
	}

	protected func CreateWidgets() -> Void
    {

    }

	protected func RegisterListeners() -> Void 
    {

	}
    
	protected cb func OnPress(evt: ref<inkPointerEvent>) -> Bool
    {
		super.OnPress(evt);
    }

	public func GetName() -> CName
    {
		return this.m_root.GetName();
	}

	public func SetName(name: CName) -> Void
    {
		this.m_root.SetName(name);
	}

	public func SetPosition(x: Float, y: Float) -> Void
    {
        this.SetPosition(Vector2(x, y));
	}

	public func SetPosition(newPosition: Vector2) -> Void {
		this.m_root.SetMargin(newPosition.X, newPosition.Y, 0, 0);
        this.position = newPosition;
	}

	public func SetWidth(width: Float) -> Void
    {
	    this.m_root.SetWidth(width);
        this.size.X = width;
	}

	public func SetHeight(height: Float) -> Void
    {
	    this.m_root.SetHeight(height);
        this.size.Y = height;
	}

    public final func GetFullSize() -> Vector2
    {
        return this.size;
    }

    private func SwapProgressValue(newValue: Float) -> Void
    {
        this.previousValue = this.currentValue;
        this.currentValue = newValue;
    }

    protected func RescaleProgressBar() -> Void
    {
        this.progressBarFill.SetSize(this.size.X * this.currentValue, this.size.Y);
    }

    public func SetProgress(newValue: Float) -> Void
    {
        newValue = ClampF(newValue, 0.0, 1.0);
        this.SwapProgressValue(newValue);
        this.RescaleProgressBar();
    }

    public func GetProgress() -> Float
    {
        return this.currentValue;
    }

}
