module Elysium.UI

import Codeware.UI.*

// A Special implementaion of CustomPopup removing fade delays and added extensions for modularity
public abstract class CustomPopupEx extends CustomPopup
{
    public let m_transitionAnimProxy: ref<inkAnimProxy>;

    public let m_rootContent: ref<InGamePopupContent>;
    
    public func GetUISystem() -> ref<UISystem>
    {
        return GameInstance.GetUISystem(this.GetGame());
    }

    protected func IsTopPopup() -> Bool
    {
        let popupData = this.m_notificationData as CustomPopupNotificationData;
        return !IsDefined(popupData) || popupData.manager.IsOnTop(this);
    }

    protected cb func OnInitialize()
    {
        super.OnInitialize();
    }

    protected cb func OnAttach()
    {
        this.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalReleaseInput");
        this.CallCustomCallback(n"OnShow");
        this.OnShow();
    }

    protected cb func OnDetach()
    {
        this.GetGameController().RequestSetFocus(null);
        this.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalReleaseInput");
        this.CallCustomCallback(n"OnClose");
        this.CallCustomCallback(n"OnHide");
        this.OnHide();
    }

    protected cb func OnShow()
    {
        this.OnShowAnimations();
        this.SetModalPopupUIContext();
    }

    protected cb func OnShowFinish(animProxy: ref<inkAnimProxy>) -> Bool
    {
        this.m_transitionAnimProxy = null;
        this.OnShown();
        this.CallCustomCallback(n"OnShown");
    }

    protected cb func OnShown()
    {
    }

    protected cb func OnHide()
    {
        this.ResetModalPopupUIContext();
        this.OnHideAnimations();
    }

    protected func OnShowAnimations() -> Void
    {
        let alphaAnim: ref<inkAnimTransparency> = new inkAnimTransparency();
        alphaAnim.SetStartTransparency(0.0);
        alphaAnim.SetEndTransparency(1.0);
        alphaAnim.SetType(inkanimInterpolationType.Linear);
        alphaAnim.SetMode(inkanimInterpolationMode.EasyIn);
        alphaAnim.SetDuration(0.5);
        let animDef: ref<inkAnimDef> = new inkAnimDef();
        animDef.AddInterpolator(alphaAnim);
        this.m_transitionAnimProxy = this.GetRootWidget().PlayAnimation(animDef);
        this.m_transitionAnimProxy.RegisterToCallback(inkanimEventType.OnFinish, this, n"OnShowFinish");
    }

    protected func OnHideAnimations() -> Void
    {
        let alphaAnim: ref<inkAnimTransparency> = new inkAnimTransparency();
        alphaAnim.SetStartTransparency(1.0);
        alphaAnim.SetEndTransparency(0.0);
        alphaAnim.SetType(inkanimInterpolationType.Linear);
        alphaAnim.SetMode(inkanimInterpolationMode.EasyIn);
        alphaAnim.SetDuration(0.25);
        let animDef: ref<inkAnimDef> = new inkAnimDef();
        animDef.AddInterpolator(alphaAnim);
        this.m_transitionAnimProxy = this.GetRootWidget().PlayAnimation(animDef);
        this.m_transitionAnimProxy.RegisterToCallback(inkanimEventType.OnFinish, this, n"OnHideFinish");
    }

    protected cb func OnHideFinish(animProxy: ref<inkAnimProxy>) -> Bool
    {
        this.m_transitionAnimProxy = null;
        this.CallCustomCallback(n"OnHidden");
        this.OnHidden();
    }

    protected cb func OnHidden()
    {
        this.ResetNotificationData();
        this.SetGameController(null);
        this.SetRootWidget(null);
    }

    protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool
    {
        if this.CanUserCloseFromAction() && evt.IsAction(this.GetUserCloseAction()) && !evt.IsHandled() && this.IsTopPopup()
        {
            this.Close();
            evt.Handle();
            return true;
        }

        if this.UseCursor() && evt.IsAction(n"mouse_left")
        {
            if !IsDefined(evt.GetTarget()) || !evt.GetTarget().CanSupportFocus()
            {
                this.GetGameController().RequestSetFocus(null);
            }
        }

        return false;
    }

    public func GetName() -> CName
    {
        return this.GetClassName();
    }

    public func GetQueueName() -> CName
    {
        return n"modal_popup";
    }

    public func IsBlocking() -> Bool
    {
        return true;
    }

    public func CanUserCloseFromAction() -> Bool
    {
        return false;
    }

    public func GetUserCloseAction() -> CName
    {
        return n"cancel";
    }

    public func Open(requester: wref<inkGameController>)
    {
        let uiSystem: ref<UISystem> = GameInstance.GetUISystem(requester.GetPlayerControlledObject().GetGame());
        let showEvent: ref<ShowCustomPopupEvent> = ShowCustomPopupEvent.Create(this);
        uiSystem.QueueEvent(showEvent);
    }

    public func Close()
    {
        let uiSystem: ref<UISystem> = GameInstance.GetUISystem(this.GetGame());
        let hideEvent: ref<HideCustomPopupEvent> = HideCustomPopupEvent.Create(this);
        uiSystem.QueueEvent(hideEvent);
    }

    public func Attach(rootWidget: ref<inkCanvas>, gameController: wref<inkGameController>, notificationData: ref<inkGameNotificationData>)
    {
        if !this.IsInitialized()
        {
            this.SetRootWidget(rootWidget);
            this.SetGameController(gameController);
            this.SetNotificationData(notificationData);
            this.CreateInstance();
            this.InitializeInstance();
            this.OnAttach();
            this.CallCustomCallback(n"OnAttach");
        }
    }
    
    public func Detach()
    {
        if this.IsInitialized()
        {
            this.OnDetach();
            this.CallCustomCallback(n"OnDetach");
        }
    }

    protected func SetModalPopupUIContext()
    {
        let uiSystem: ref<UISystem> = this.GetUISystem();
        uiSystem.PushGameContext(UIGameContext.ModalPopup);
        uiSystem.RequestNewVisualState(n"inkModalPopupState");
    }

    protected func ResetModalPopupUIContext()
    {
        let uiSystem: ref<UISystem> = this.GetUISystem();
        uiSystem.PopGameContext(UIGameContext.ModalPopup);
        uiSystem.RestorePreviousVisualState(n"inkModalPopupState");
    }

    public func UseCursor() -> Bool
    {
        return true;
    }

    protected cb func OnCreate() -> Void
    {
        this.CreateDefaultRootContent();
        this.CreateWidgetContents(this.m_rootContent);
    }

    protected func CreateDefaultRootContent() -> Void
    {
        this.m_rootContent = InGamePopupContent.Create();
        this.m_rootContent.Reparent(this);
        this.m_rootContent.m_content.SetMargin(0, 0, 0, 0);
        this.m_rootContent.m_content.AlignToFill();
        this.m_rootContent.m_content.SetOpacity(0.0);
        this.m_rootContent.m_content.SetSize(Vector2(1920,1080));
    }

    protected func CreateWidgetContents(inRootContent: ref<InGamePopupContent>) -> Void
    {

    }
}
