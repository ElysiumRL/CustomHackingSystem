module HackingExtensions.CustomMinigame
import Codeware.UI.*

public class CustomMinigameHackPopup extends InGamePopup
{
    protected let m_content: ref<InGamePopupContent>;

    protected let baseWidget: ref<BaseWidget>;
    
    protected let canLeavePopup: Bool = true;

    public func UseCursor() -> Bool
    {
        return true;
    }

    protected cb func OnCreate() -> Void
    {
        //super.OnCreate();

        this.canLeavePopup = false;

        this.m_content = InGamePopupContent.Create();
        this.m_content.Reparent(this);
        //this.m_content.m_content.SetAnchorPoint(0.5, 0.5);
        this.m_content.m_content.SetMargin(0, 0, 0, 0);
        this.m_content.m_content.AlignToFill();
        this.m_content.m_content.SetSize(new Vector2(1920,1080));
        
        this.baseWidget = BaseWidget.Create();
        this.baseWidget.SetSize(this.m_content.GetSize());
        //this.baseWidget.m_container.SetFitToContent(true);
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
