module HackingExtensions.CustomMinigame
import Codeware.UI.*

public class CustomMinigameHackPopup extends InGamePopup
{
	protected let m_content: ref<InGamePopupContent>;

	protected let baseWidget: ref<BaseWidget>;
	
	public func UseCursor() -> Bool
	{
		return true;
	}

	protected cb func OnCreate() -> Void
	{
		super.OnCreate();

		this.canLeavePopup = false;

		this.m_content = InGamePopupContent.Create();
		this.m_content.Reparent(this);

		this.baseWidget = BaseWidget.Create();
		this.baseWidget.SetSize(this.m_content.GetSize());
		this.baseWidget.Reparent(this.m_content);

	}

	protected cb func OnInitialize() -> Void
	{
		super.OnInitialize();
	}

    public func OnWindowClosed() -> Void
    {

    }
}
