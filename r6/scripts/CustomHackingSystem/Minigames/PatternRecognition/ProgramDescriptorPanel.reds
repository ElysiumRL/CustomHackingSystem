module CustomHackingSystem.Hacks.PatternRecognition

import Codeware.UI.*
import Codeware.UI.InkAtlas.*

enum EHackProgramPanelState
{
	Idle = 0,
	InProgress = 1,
	Success = 2,
	Failure = 3
}

public class HackProgramPanel extends inkCustomController
{
	public let panelState : EHackProgramPanelState;

	protected let m_isFlipped: Bool;
	
	protected let m_root: wref<inkCompoundWidget>;

	protected let background: wref<inkImage>;

	protected let m_fill: wref<inkImage>;

	protected let m_frame: wref<inkImage>;
	
	protected let m_imageBorder: wref<InkImageWidget>;

	protected let programDescription : ref<InkTextWidget>;

	protected let programName : ref<InkTextWidget>;

	protected let programIcon: ref<inkImage>;

	public let programData:TweakDBID;

	public let startFluffProgressBar:Bool = false;
	
	public let progressBarStatusText:ref<InkTextWidget>;

	public let progressBarFluffCurrentTime: Float = 0.0;
	
	public let progressBarFluffMaxTime: Float = 10.0;

	protected let progressBarFluff: ref<ScannerProgressBar>;

	public let progressBarFluffCompleted:Bool = false;

    public const func ShouldRegisterForTickEvent() -> Bool
	{
		return true;
	}

	protected func CreateWidgets() -> Void {
		let root: ref<inkCanvas> = new inkCanvas();
		root.SetName(n"button");
		root.SetSize(600.0, 200.0);
		root.SetAnchorPoint(new Vector2(0.5, 0.5));
		root.SetInteractive(false);
		root.SetVisible(true);



		let programRecord:wref<Program_Record> = TweakDBInterface.GetProgramRecord(this.programData);

		let bg: ref<inkImage> = new inkImage();
		bg.SetName(n"bg");
		bg.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");

		bg.SetTintColor(MainColors.Black());

		bg.SetOpacity(0.0);
		bg.SetAnchor(inkEAnchor.Fill);
		bg.SetNineSliceScale(true);
		bg.SetNineSliceGrid(new inkMargin(0.0, 0.0, 10.0, 0.0));
		bg.Reparent(root);

		let fill: ref<inkImage> = new inkImage();
		fill.SetName(n"fill");
		fill.SetAtlasResource(AtlasInventory.AtlasResourcePathRef());
		fill.SetTexturePart(AtlasInventory.GetTexture2slotIconicPath());
		fill.SetOpacity(0.0);
		fill.SetAnchor(inkEAnchor.Fill);
		fill.SetNineSliceScale(true);
		fill.SetNineSliceGrid(new inkMargin(0.0, 0.0, 10.0, 0.0));
		//Bright Red
		fill.SetTintColor(new HDRColor(2.0,0.0,0.0,1.0));
		//Bright Green
		fill.SetTintColor(new HDRColor(0.0,2.0,0.0,1.0));
		//Bright absolute clean-stylish State-of-the-Art™ transparent
		fill.SetTintColor(new HDRColor(0.0,0.0,0.0,0.0));

		fill.Reparent(root);


		this.programIcon = new inkImage();
		this.programIcon.SetName(n"programIcon");
		this.programIcon.SetAtlasResource(programRecord.Program().ObjectActionUI().CaptionIcon().TexturePartID().AtlasResourcePath());
		this.programIcon.SetTexturePart(programRecord.Program().ObjectActionUI().CaptionIcon().TexturePartID().AtlasPartName());
		this.programIcon.SetOpacity(1.0);
		this.programIcon.SetAnchor(inkEAnchor.CenterLeft);
		this.programIcon.SetAnchorPoint(new Vector2(0,0.5));
		this.programIcon.SetMargin(20,0,0,0);
		this.programIcon.SetSize(new Vector2(148,148));
		this.programIcon.SetVisible(true);
		this.programIcon.Reparent(root);

		let frame: ref<inkImage> = new inkImage();
		frame.SetName(n"frame");
		frame.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
		frame.SetOpacity(1.0);
		frame.SetAnchor(inkEAnchor.Fill);
		frame.SetNineSliceScale(true);
		frame.SetTintColor(MainColors.PanelRed() * 0.95);
		frame.SetNineSliceGrid(new inkMargin(0.0, 0.0, 10.0, 0.0));
		frame.Reparent(root);

		let programNameString:String = GetLocalizedText(LocKeyToString(programRecord.Program().ObjectActionUI().Caption()));
		
		this.programName = 
		InkTextWidget.Create(
			root,
			new Vector2(83.0,-80.0),
			new Vector2(400.0,40.0),
			programNameString,
			1.0);
		this.programName.textWidget.SetHAlign(inkEHorizontalAlign.Right);
		this.programName.textWidget.SetHorizontalAlignment(textHorizontalAlignment.Right);
		this.programName.textWidget.EnableAutoScroll(true);
		this.programName.textWidget.SetScrollTextSpeed(0.95);
        this.programName.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily", n"Medium");
        this.programName.textWidget.SetTintColor(MainColors.PanelWhite());
        this.programName.textWidget.SetFontSize(35);
		

		let programDescriptionString:String = GetLocalizedText(LocKeyToString(programRecord.Program().ObjectActionUI().Description()));
		
		this.programDescription = 
		InkTextWidget.Create(
			root,
			new Vector2(85.0,-46.0),
			new Vector2(400.0,30.0),
			programDescriptionString,
			1.0);
		this.programDescription.textWidget.SetHAlign(inkEHorizontalAlign.Right);
		this.programDescription.textWidget.SetHorizontalAlignment(textHorizontalAlignment.Right);
		this.programDescription.textWidget.SetOverflowPolicy(textOverflowPolicy.PingPongScroll);
		this.programDescription.textWidget.EnableAutoScroll(true);
		this.programDescription.textWidget.SetScrollTextSpeed(1.10);
        this.programDescription.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily", n"Medium");
        this.programDescription.textWidget.SetTintColor(MainColors.PanelWhite() * 0.95);
        this.programDescription.textWidget.SetFontSize(24);

        this.m_imageBorder = InkImageWidget.CreateWithImage(root, new Vector2(-122.0,0.0), new Vector2(5.0,200.0), AtlasShapesSync.AtlasResourcePathRef(), AtlasShapesSync.GetTooltipSideGapFlipPath(), 1.0, MainColors.PanelRed());
		
		this.progressBarFluff = ScannerProgressBar.Create(new Vector2(580.0,15.0), new Vector2(-10.0,90.0), 0.0);
		this.progressBarFluff.Reparent(root);

		this.progressBarStatusText = 
		InkTextWidget.Create(
			root,
			new Vector2(-86.0,56.0),
			new Vector2(400.0,40.0),
			"Loading ...",
			1.0);
		this.progressBarStatusText.textWidget.SetHAlign(inkEHorizontalAlign.Left);
		this.progressBarStatusText.textWidget.SetHorizontalAlignment(textHorizontalAlignment.Left);
        this.progressBarStatusText.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily", n"Medium");
        this.progressBarStatusText.textWidget.SetTintColor(MainColors.ActiveRed());
        this.progressBarStatusText.textWidget.SetFontSize(35);



		this.m_root = root;
		this.background = bg;
		this.m_fill = fill;
		this.m_frame = frame;


		this.SetRootWidget(root);
		this.ApplyFlippedState();
	}

	public func SetPanelState(newState: EHackProgramPanelState)
	{
        this.panelState = newState;
        switch(newState)
        {
        case EHackProgramPanelState.Idle:
			this.SetInProgressAnimations();
            break;     
        case EHackProgramPanelState.InProgress:
 			this.SetInProgressAnimations();
            break;
        case EHackProgramPanelState.Success:
  			this.SetSuccessAnimations();
            break;
        case EHackProgramPanelState.Failure:
			this.SetFailureAnimations();
            break;
        }
	}


	protected cb func OnInitialize() -> Void 
    {
        super.OnInitialize();

	}

	public func TickUpdate(deltaTime: Float) -> Void
	{
        super.TickUpdate(deltaTime);
		if (this.startFluffProgressBar)
		{
			this.progressBarFluffCurrentTime += deltaTime;
			this.progressBarFluff.SetProgress(this.progressBarFluffCurrentTime / this.progressBarFluffMaxTime);
			//TODO: refactor to remove useless tick update
			//It works but it takes extra resources for nothing
			if(this.progressBarFluff.GetProgress() >= 1.0 && !this.progressBarFluffCompleted)
			{
				this.progressBarStatusText.textWidget.SetText("Ready");
				this.progressBarStatusText.textWidget.SetTintColor(MainColors.ActiveBlue());
				this.progressBarStatusText.textWidget.GlitchIn(3u, true,0.4, new Vector2(0.0,0.0), true, false, 0.0);
				this.progressBarFluffCompleted = true;
			}
		}
	}


	public func SetInProgressAnimations()
	{
		//this.m_fill.SetTintColor(MainColors.Gold());
		//this.m_frame.SetTintColor(MainColors.Gold());
		//this.m_imageBorder.image.SetTintColor(MainColors.Gold());
		//this.progressBarFluff.progressBarFill.SetTintColor(MainColors.Gold());

		this.m_frame.TintShift(this.m_frame.GetTintColor(), MainColors.Gold(), 0.2, true, false);
		this.m_imageBorder.image.TintShift(this.m_imageBorder.image.GetTintColor(), MainColors.Gold(), 0.2, true, false);
		this.progressBarFluff.progressBarFill.TintShift(this.progressBarFluff.progressBarFill.GetTintColor(), MainColors.Gold(), 0.2, true, false);




		this.progressBarStatusText.textWidget.SetText("In Progress");
	}

	public func SetSuccessAnimations()
	{
		this.m_fill.GlitchIn(Cast<Uint32>(RandRange(3,6)), true, 0.05, new Vector2(0.0,0.0), true, false, RandRangeF(0.05,0.1));
		
		//this.m_fill.SetTintColor(new HDRColor(0.0,2.0,0.0,1.0));
		//this.m_frame.SetTintColor(new HDRColor(0.0,2.0,0.0,1.0));
		//this.m_imageBorder.image.SetTintColor(new HDRColor(0.0,2.0,0.0,1.0));
		//this.progressBarFluff.progressBarFill.SetTintColor(new HDRColor(0.0,2.0,0.0,1.0));

		this.m_frame.TintShift(this.m_frame.GetTintColor(), new HDRColor(0.0,2.0,0.0,1.0), 1.0, true, false);
		this.m_imageBorder.image.TintShift(this.m_imageBorder.image.GetTintColor(), new HDRColor(0.0,2.0,0.0,1.0), 1.0, true, false);
		this.progressBarFluff.progressBarFill.TintShift(this.progressBarFluff.progressBarFill.GetTintColor(), new HDRColor(0.0,2.0,0.0,1.0), 1.0, true, false);


		this.progressBarStatusText.textWidget.SetText("Success");

	}

	public func SetFailureAnimations()
	{
		this.m_fill.GlitchIn(Cast<Uint32>(RandRange(3,6)), true, 0.05, new Vector2(0.0,0.0), true, false, RandRangeF(0.05,0.1));


		//this.m_fill.SetTintColor(new HDRColor(0.5,0.0,0.0,1.0));
		//this.m_frame.SetTintColor(new HDRColor(0.5,0.0,0.0,1.0));
		
		this.m_frame.TintShift(this.m_frame.GetTintColor(), new HDRColor(0.5,0.0,0.0,1.0), 1.0, true, false);
		this.m_imageBorder.image.TintShift(this.m_imageBorder.image.GetTintColor(), new HDRColor(0.5,0.0,0.0,1.0), 1.0, true, false);
		this.progressBarFluff.progressBarFill.TintShift(this.progressBarFluff.progressBarFill.GetTintColor(), new HDRColor(0.5,0.0,0.0,1.0), 1.0, true, false);

		//this.m_imageBorder.image.SetTintColor(new HDRColor(0.5,0.0,0.0,1.0));
		//this.progressBarFluff.progressBarFill.SetTintColor(new HDRColor(0.5,0.0,0.0,1.0));
		this.progressBarStatusText.textWidget.SetTintColor(MainColors.ActiveRed());
		this.progressBarStatusText.textWidget.SetText("Failed");
	}


	protected func CreateAnimations() -> Void
	{

	}

	protected func ApplyFlippedState() -> Void {
		this.background.SetTexturePart(this.m_isFlipped ? n"cell_flip_bg" : n"cell_bg");
		//this.m_fill.SetTexturePart(this.m_isFlipped ? n"cell_flip_bg" : n"cell_bg");
		this.m_frame.SetTexturePart(this.m_isFlipped ? n"cell_flip_fg" : n"cell_fg");
	}

	public func SetFlipped(isFlipped: Bool) -> Void {
		this.m_isFlipped = isFlipped;

		this.ApplyFlippedState();
	}

	public static func Create(programData: TweakDBID) -> ref<HackProgramPanel>
	{
		let panel: ref<HackProgramPanel> = new HackProgramPanel();
		panel.programData = programData;
		panel.CreateInstance();
		panel.CreateWidgets();
		panel.m_root.SetVisible(true);

		return panel;
	}
}
