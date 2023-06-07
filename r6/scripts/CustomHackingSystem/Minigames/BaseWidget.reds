module HackingExtensions.CustomMinigame
import Codeware.UI.*
//import Codeware.Localization.*

//Also named "Workbench" from InkPlayground
//This is the base widget for the popups
public class BaseWidget extends HackingMinigameCustomController
{
	protected let m_root: wref<inkFlex>;

	protected let m_container: wref<inkCanvas>;

	protected let m_areaSize: Vector2;

	protected cb func OnCreate() -> Void {
		let workbench: ref<inkFlex> = new inkFlex();
		workbench.SetName(n"BaseWidget");
		workbench.SetAnchor(inkEAnchor.Fill);

		let background: ref<inkRectangle> = new inkRectangle();
		background.SetAnchor(inkEAnchor.Fill);
		//background.SetMargin(new inkMargin(8.0, 8.0, 8.0, 8.0));
		background.SetTintColor(MainColors.Black());
		//background.SetOpacity(0.217);
		background.SetOpacity(0.75);

		background.Reparent(workbench);

		let pattern: ref<inkImage> = new inkImage();
		pattern.SetName(n"pattern");
		pattern.SetAtlasResource(r"base\\gameplay\\gui\\fullscreen\\inventory\\atlas_inventory.inkatlas");
		pattern.SetTexturePart(n"BLUEPRINT_3slot");
		pattern.SetBrushTileType(inkBrushTileType.Both);
		pattern.SetTileHAlign(inkEHorizontalAlign.Center);
		pattern.SetTileVAlign(inkEVerticalAlign.Center);
		pattern.SetAnchor(inkEAnchor.Fill);
		pattern.SetOpacity(0.1);
		pattern.SetTintColor(MainColors.Red());
		pattern.SetMargin(new inkMargin(8.0, 4.0, 8.0, 2.0));
		pattern.Reparent(workbench);

		let frame: ref<inkImage> = new inkImage();
		frame.SetName(n"frame");
		frame.SetAtlasResource(r"base\\gameplay\\gui\\fullscreen\\inventory\\inventory4_atlas.inkatlas");
		frame.SetTexturePart(n"itemGridFrame3Big");
		frame.SetNineSliceScale(true);
		frame.SetNineSliceGrid(new inkMargin(24, 24, 24, 24));
		frame.SetAnchor(inkEAnchor.Fill);
		frame.SetOpacity(0.5);
		frame.SetTintColor(MainColors.Red());
		frame.Reparent(workbench);

		let container: ref<inkCanvas> = new inkCanvas();
		container.SetName(n"container");
		container.SetAnchor(inkEAnchor.Fill);
		container.Reparent(workbench);
		this.m_root = workbench;
		this.m_container = container;

		this.SetRootWidget(workbench);
		this.SetContainerWidget(container);
	}

	public func GetContainer() -> wref<inkCanvas>
	{
		return this.m_container;
	}

	public func GetSize() -> Vector2
	{
		return this.m_areaSize;
	}

	public func SetSize(areaSize: Vector2) -> Void
	{
		this.m_areaSize = areaSize;
	}

	public static func Create() -> ref<BaseWidget>
	{
		let baseWidget: ref<BaseWidget> = new BaseWidget();
		baseWidget.CreateInstance();
		return baseWidget;
	}
}
