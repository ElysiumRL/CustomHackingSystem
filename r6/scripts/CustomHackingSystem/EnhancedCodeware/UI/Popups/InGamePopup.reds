// -----------------------------------------------------------------------------
// Codeware.UI.InGamePopup
// -----------------------------------------------------------------------------
//
// - Base class for in-game custom popups
// - Adds standard vignette as seen in original popups
// - Adds container widget centered on screen by default
// - Sets the appropriate UI context so that the game and other mods know
//   that the modal popup is currently active
// - Sets the time dilation as for original modal popups
// - Blurs the screen as for original modal popups
//

module Codeware.UI

public abstract class InGamePopup extends CustomPopup {
	protected let m_vignette: wref<inkImage>;

	protected let m_container: wref<inkCompoundWidget>;

	protected cb func OnCreate() -> Void {
		super.OnCreate();

		this.CreateVignette();
		this.CreateContainer();
	}

	protected func CreateVignette() -> Void {
		let vignette: ref<inkImage> = new inkImage();
		vignette.SetName(n"vignette");
		vignette.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\notifications\\vignette.inkatlas");
		vignette.SetTexturePart(n"vignette_1");
		vignette.SetNineSliceScale(true);
		vignette.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0));
		vignette.SetSize(32.0, 32.0);
		vignette.SetAnchor(inkEAnchor.CenterFillHorizontaly);
		vignette.SetAnchorPoint(new Vector2(0.5, 0.5));
		vignette.SetHAlign(inkEHorizontalAlign.Center);
		vignette.SetVAlign(inkEVerticalAlign.Center);
		vignette.SetFitToContent(true);
		vignette.Reparent(this.GetRootCompoundWidget());

		this.m_vignette = vignette;
	}

	protected func CreateBlackBackground() -> Void {
		let emptyBackground: ref<inkImage> = new inkImage();
		emptyBackground.SetName(n"background");
		emptyBackground.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\notifications\\vignette.inkatlas");
		emptyBackground.SetTexturePart(n"vignette_1");
		emptyBackground.SetNineSliceScale(true);
		emptyBackground.SetTintColor(new HDRColor(0.0, 0.0, 0.0, 1.0));
		emptyBackground.SetSize(32.0, 32.0);
		emptyBackground.SetAnchor(inkEAnchor.CenterFillHorizontaly);
		emptyBackground.SetAnchorPoint(new Vector2(0.5, 0.5));
		emptyBackground.SetHAlign(inkEHorizontalAlign.Center);
		emptyBackground.SetVAlign(inkEVerticalAlign.Center);
		emptyBackground.SetFitToContent(true);
		emptyBackground.SetVisible(true);
		emptyBackground.Reparent(this.GetRootCompoundWidget());

		this.m_vignette = emptyBackground;
	}

	protected func CreateContainer() -> Void {
		let container: ref<inkCanvas> = new inkCanvas();
		container.SetName(n"container");
		//container.SetMargin(new inkMargin(0.0, 0.0, 0.0, 200.0));
		container.SetAnchor(inkEAnchor.Centered);
		container.SetAnchorPoint(new Vector2(0.5, 0.5));
		//container.SetSize(new Vector2(1550.0, 840.0));
		
		container.SetMargin(new inkMargin(100.0, 100.0, 100.0, 100.0));
		container.SetSize(new Vector2(3840.0, 2160.0));
		container.SetHAlign(inkEHorizontalAlign.Center);
		container.SetVAlign(inkEVerticalAlign.Center);
		container.SetTintColor(MainColors.PanelBlack());
		container.Reparent(this.GetRootCompoundWidget());
		this.m_container = container;

		this.SetContainerWidget(container);
	}

	protected cb func OnShow() -> Void {
		super.OnShow();

		this.SetUIContext();
		this.SetTimeDilation();
		this.SetBackgroundBlur();
		this.PlayShowSound();
	}

	protected cb func OnHide() -> Void {
		super.OnHide();

		this.ResetUIContext();
		this.ResetTimeDilation();
		this.ResetBackgroundBlur();
		this.PlayHideSound();
	}

	protected func SetTimeDilation() -> Void {
		TimeDilationHelper.SetTimeDilationWithProfile(this.GetPlayer(), "radialMenu", true);
	}

	protected func ResetTimeDilation() -> Void {
		TimeDilationHelper.SetTimeDilationWithProfile(this.GetPlayer(), "radialMenu", false);
	}

	protected func SetBackgroundBlur() -> Void {
		PopupStateUtils.SetBackgroundBlur(this.m_gameController, true);
	}

	protected func ResetBackgroundBlur() -> Void {
		PopupStateUtils.SetBackgroundBlur(this.m_gameController, false);
	}

	protected func SetUIContext() -> Void {
		let uiSystem: ref<UISystem> = GameInstance.GetUISystem(this.GetGame());
		uiSystem.PushGameContext(UIGameContext.ModalPopup);
		uiSystem.RequestNewVisualState(n"inkModalPopupState");
	}

	protected func ResetUIContext() -> Void {
		let uiSystem: ref<UISystem> = GameInstance.GetUISystem(this.GetGame());
		uiSystem.PopGameContext(UIGameContext.ModalPopup);
		uiSystem.RestorePreviousVisualState(n"inkModalPopupState");
	}

	protected func PlayShowSound() -> Void {
		//this.PlaySound(n"RadialMenu", n"OnOpen");
	}

	protected func PlayHideSound() -> Void {
		//this.PlaySound(n"RadialMenu", n"OnClose");
	}
}
