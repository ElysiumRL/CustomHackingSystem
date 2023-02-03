module CustomHackingSystem.Hacks.PatternRecognition
import Codeware.UI.*
import Codeware.Scheduling.*
import Codeware.UI.InkAtlas.*
import HackingExtensions.CustomMinigame.*


// Pattern Recognition Hack (by Elysium)
// Repo link : https://github.com/ElysiumRL/cp77-PatternRecognitionHack



//TODO: try to see how UTF-8/16 characters are handled
//TODO: (2) test with enum types different from HackingMinigame
//TODO: (3) There's a lot of things to optimize (especially array accesses)

enum EPatternRecognitionHackLetterType
{
    //from CDPR's base Hacking Minigame
    HackingMinigame = 0,
    //Numbers ([0-9])
    Numerical = 1,
    //Regular Alphabet ([A-Z])
    Alphabetical = 2,
    //Regular Alphabet ([A-Z]) + Numbers ([0-9])
    Alphanumerical = 3,
    //Greek Alphabet (only some of those appear on screen)
    Greek = 4,
    //Some weird runes (None of those appear on screen)
    Runic = 5,
    //Count (Don't use it)
    Count = 6
}


public class PatternRecognitionHackSettings
{
    //TweakDBID of the programs to acquire
	public let programs: array<TweakDBID>;
    
    //Size of the playing grid
    public let gridSize: Uint32 = 6u;

    //Amount of attempts/guesses per program (Default : 1)
    public let attemptsPerProgram: Uint32 = 1u;
    
    //Maximum time per attempt (Default : 20.0)
    public let maximumTime: Float = 20.0;

    //How many times the box has to change content per second (Default : 1.0 update per second)
    public let boxMovingSpeedPerSec: Float = 1.0;

    //Box Length of the answer  
    public let answerLength: Uint32 = 3u;

    //Type of the box content (Not Implemented Yet)
    public let letterType: EPatternRecognitionHackLetterType = EPatternRecognitionHackLetterType.HackingMinigame;

    //Advanced Settings
    public let advancedSettings: ref<PatternRecognitionHackAdvancedSettings>;

    public static func Default() -> ref<PatternRecognitionHackSettings>
    {
        let settings:ref<PatternRecognitionHackSettings> = new PatternRecognitionHackSettings();
        let advancedSettings:ref<PatternRecognitionHackAdvancedSettings> = new PatternRecognitionHackAdvancedSettings();
        settings.advancedSettings = advancedSettings;
        return settings;
    }

}

public class PatternRecognitionHackAdvancedSettings
{
    //True to allow an answer to possibly appear many times in the grid
    let allowMultipleSameAnswers: Bool = false;

    //Amount of letters/symbols per box
	let symbolAmountPerBox : Uint32 = 2u;
    
    //True to remove the answer from screen after a certain time
    let shouldHideAnswerAfterTime: Bool = false;
    
    //Percentage of time remaining before hiding answer (default : 0.5 -> answer will be hidden when 50% of the remaining time has passed)
    let remainingUnitTimeBeforeHiding: Float = 0.5;
}

public class BoxContent
{
    let text:String;

    let indexInGrid:Int32;
}

public abstract class PatternRecognitionHackCallback extends DelayCallback
{
    public let controller: ref<PatternRecognitionHack>;
}

public class PatternRecognitionHack extends CustomMinigame
{
    public static func StartMinigame(settings: ref<PatternRecognitionHackSettings>, gameInstance: GameInstance) -> Void
    {
        if(!GameInstance.IsValid(gameInstance))
        {
            LogChannel(n"DEBUG","[PatternRecognitionHack::StartMinigame] Game Instance provided not valid : Aborting Minigame initialization");
        }

	    let hackingMinigameBlackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance).Get(GetAllBlackboardDefs().HackingMinigame);

	    if (IsDefined(hackingMinigameBlackboard))
	    {
	    	let inGameMenuControllerVariant:Variant = hackingMinigameBlackboard.GetVariant(GetAllBlackboardDefs().HackingMinigame.InGameMenuController);
	    	let inGameMenuController:ref<gameuiInGameMenuGameController> = FromVariant<ref<gameuiInGameMenuGameController>>(inGameMenuControllerVariant);

            if(IsDefined(inGameMenuController))
            {
	    	    PatternRecognitionHackPopup.Show(inGameMenuController,settings);
            }
            else
            {
                LogChannel(n"DEBUG","[PatternRecognitionHack::StartMinigame] InGameMenu Game Controller not set in the HackingMinigame Blackboard Definition");
            }
	    }
        else
        {
            LogChannel(n"DEBUG","[PatternRecognitionHack::StartMinigame] HackingMinigame Blackboard Definition Not found");
        }

        //let minigame:ref<PatternRecognitionHack> = new PatternRecognitionHack();
        //minigame.SetMinigameDefaults();
        //minigame.SetMinigameInstanceDefaults();
        //return minigame;
    }





    public static func Create() -> ref<PatternRecognitionHack>
    {
        let minigame:ref<PatternRecognitionHack> = new PatternRecognitionHack();
        minigame.SetMinigameDefaults();
        minigame.SetMinigameInstanceDefaults();
        return minigame;
    }

    private let videoBackground: ref<InkVideoWidget>;

    private let allButtons: array<wref<HackingMinigameButton>>;
    
    private let instanceBoxContent : array<ref<BoxContent>>;

    //Answers for the current instance
    public let answers : Int32;

    protected let uniformGridPanel: wref<inkCompoundWidget>;

    public let totalBoxes: Int32;

    //time left
    protected let instanceProgressBar: wref<CustomProgressBar>;
    
    protected let swapBoxTimerProgressBar: wref<CustomProgressBar>;

    private let currentTime: Float = 0.0;
    
    private let canStartGame: Bool = false;
    
    private let isInGame: Bool = false;

    private let shouldUpdateGameTimers: Bool = false;
    
    private let startButton: ref<SimpleButton>;
    
    private let endButton: ref<SimpleButton>;

    private let answerText: ref<inkText>;

    public let currentAttempts:Int32;

    public let settings: ref<PatternRecognitionHackSettings>;

    private let programsVerticalPanel: ref<inkVerticalPanel>;

    private let allPrograms: array<ref<HackProgramPanel>>;

    public let moveBoxContentTimer: Float = 0.0;

    public let introVideo:ref<InkVideoWidget>;

    public let allFluffs:array<ref<InkVideoWidget>>;

    public let remainingTimeText: ref<InkTextWidget>;

    public let creditFluffText : ref<InkTextWidget>;

    public let allImageFluffs:array<ref<InkImageWidget>>;

    public let endScreenText:ref<InkTextWidget>;

    protected func CreateWidgets() -> Void
    {
        let root: ref<inkCanvas> = new inkCanvas();
        root.SetName(this.GetClassName());
        root.SetAnchor(inkEAnchor.Fill);
        
        this.settings.gridSize = Cast<Uint32>(RandRange(4, 6));
        this.totalBoxes = Cast<Int32>(this.settings.gridSize * this.settings.gridSize);

        let uniformGridPanel : ref<inkUniformGrid> = new inkUniformGrid();
        uniformGridPanel.AlignToCenter();
        uniformGridPanel.SetChildMargin(new inkMargin(20.0, 20.0, 20.0, 20.0));
        uniformGridPanel.SetWrappingWidgetCount(this.settings.gridSize);
        uniformGridPanel.SetFitToContent(true);
        uniformGridPanel.Reparent(root);

        let x:Int32 = 0;
        let y:Int32 = 0;
        ArrayClear(this.allButtons);
        while (y < Cast<Int32>(this.settings.gridSize))
        {
            while (x < Cast<Int32>(this.settings.gridSize))
            {
                let newButton:ref<HackingMinigameButton> = HackingMinigameButton.Create("--");
                
                newButton.ToggleAnimations(false);
                newButton.ToggleSounds(false);
                newButton.m_root.SetInteractive(false);
                newButton.Reparent(uniformGridPanel);
                newButton.m_root.SetOpacity(0.0);
                newButton.minigameOwner = this;
                ArrayPush(this.allButtons, newButton);
                x += 1;
            }
            x = 0;
            y += 1;
        }
        x = 0;
        y = 0;

		this.startButton = SimpleButton.Create();
		this.startButton.SetName(n"StartButton");
		this.startButton.SetText("Start");
        this.startButton.m_root.AlignToCenter();
        this.startButton.SetPosition(-210.0, 746.0);
		this.startButton.SetFlipped(true);
		this.startButton.ToggleAnimations(true);
		this.startButton.ToggleSounds(true);    
		this.startButton.Reparent(root);
		
        this.endButton = SimpleButton.Create();
		this.endButton.SetName(n"EndButton");
		this.endButton.SetText("Quit");
        this.endButton.m_root.AlignToCenter();
        this.endButton.SetPosition(210.0, 746.0);
		this.endButton.SetFlipped(false);
		this.endButton.ToggleAnimations(true);
		this.endButton.ToggleSounds(true);
        this.endButton.m_root.SetVisible(false);
        this.endButton.m_root.SetOpacity(0.0);
        this.endButton.m_root.SetInteractive(false);
		this.endButton.Reparent(root);

        this.endScreenText = InkTextWidget.Create(root, new Vector2(0.0,0.0), new Vector2(500.0,500.0),"", 1.0);
        this.endScreenText.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\arame\\arame.inkfontfamily", n"Regular");
        this.endScreenText.textWidget.SetFontSize(48);   
        this.endScreenText.textWidget.AlignToCenter();
        this.endScreenText.textWidget.SetHorizontalAlignment(textHorizontalAlignment.Center);
        this.endScreenText.textWidget.SetVerticalAlignment(textVerticalAlignment.Center);
        this.endScreenText.root.SetInteractive(false); 
        this.endScreenText.root.SetVisible(true);


		this.instanceProgressBar = RectangleProgressBar.Create(new Vector2(800,22), new Vector2(0.0,-500.0), 0.0);
        this.instanceProgressBar.m_root.SetOpacity(0.0);
        this.instanceProgressBar.Reparent(root);
		
        this.swapBoxTimerProgressBar = ScannerProgressBar.Create(new Vector2(300,22), new Vector2(250.0,-600.0), 0.0);
        this.swapBoxTimerProgressBar.m_root.SetOpacity(0.0);
		this.swapBoxTimerProgressBar.Reparent(root);


		let label: ref<inkText> = new inkText();
		label.SetName(n"label");
		label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
		label.SetFontStyle(n"Medium");
		label.SetFontSize(50);
		label.SetLetterCase(textLetterCase.UpperCase);
        label.SetMargin(0.0,-800.0,0.0,0.0);
		label.SetTintColor(MainColors.Red());
		label.SetAnchor(inkEAnchor.Fill);
		label.SetHorizontalAlignment(textHorizontalAlignment.Center);
		label.SetVerticalAlignment(textVerticalAlignment.Center);
		label.SetText("-- -- -- -- --");
		label.Reparent(root);
        
		this.programsVerticalPanel = new inkVerticalPanel();
		this.programsVerticalPanel.SetName(n"programsVerticalPanel");
		this.programsVerticalPanel.SetFitToContent(true);
		this.programsVerticalPanel.SetAnchor(inkEAnchor.Centered);
		this.programsVerticalPanel.SetAnchorPoint(new Vector2(0.5, 0.5));
        this.programsVerticalPanel.SetMargin(1250.0, 0.0, 0.0, 0.0);
		this.programsVerticalPanel.SetChildMargin(new inkMargin(0.0, 75.0, 0.0, 0.0));
		this.programsVerticalPanel.Reparent(root);

        ArrayPush(this.settings.programs, t"MinigameProgram.DatamineV1");
        ArrayPush(this.settings.programs, t"MinigameProgram.DatamineV2");
        ArrayPush(this.settings.programs, t"MinigameProgram.DatamineV3");

        this.allProgramsTDBID = this.settings.programs;
        
        for program in this.settings.programs
        {
            let newProgramPanel:ref<HackProgramPanel> = HackProgramPanel.Create(program);
            newProgramPanel.Reparent(this.programsVerticalPanel);
            newProgramPanel.m_root.SetOpacity(0.0);
            ArrayPush(this.allPrograms,newProgramPanel); 
        }

        this.creditFluffText = InkTextWidget.Create(root,new Vector2(1676.0,-891.0),new Vector2(200.0,20.0), "Pattern Hack v0.1 - Elysium",1.0);
        this.creditFluffText.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\industry\\industry.inkfontfamily", n"Demi");
        this.creditFluffText.textWidget.SetTintColor(MainColors.PanelRed());
        this.creditFluffText.textWidget.SetFontSize(14);

        this.remainingTimeText = InkTextWidget.Create(root, new Vector2(698.0,-490.0), new Vector2(500.0,75.0), "STATUS : OFF", 1.0);
        this.remainingTimeText.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\arame\\arame.inkfontfamily", n"Regular");
        this.remainingTimeText.textWidget.SetTintColor(MainColors.PanelRed());
        this.remainingTimeText.textWidget.SetFontSize(54);
        this.remainingTimeText.root.SetOpacity(0.0);
        
        //this.videoBackground = InkVideoWidget.CreateBackground(root, 1.0);
        this.introVideo = InkVideoWidget.CreateBackground(root, 1.0,r"base\\movies\\fullscreen\\reboot-skin.bk2");

        this.answerText = label;
        this.root = root;

        this.uniformGridPanel = uniformGridPanel;
        this.CreateAllFluffs();

        this.SetRootWidget(root);

    }

    protected func CreateAllFluffs() -> Void
    {
        ArrayPush(this.allFluffs, InkVideoWidget.CreateWithColor(this.root, new Vector2(-1704.0,-786.0), new Vector2(400.0,400.0), 0.05,r"base\\movies\\misc\\q003\\loop_1.bk2",MainColors.White()));
        ArrayPush(this.allFluffs, InkVideoWidget.CreateWithColor(this.root, new Vector2(1804.0,-766.0), new Vector2(100.0,100.0), 0.5,r"base\\movies\\misc\\logo\\nettech_globe.bk2",MainColors.ActiveRed()));

        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(1636.0,-844.0), new Vector2(150.0,35.0), WeaponManufacturers.AtlasResourcePathRef(), WeaponManufacturers.GetKangtaoPath(), 0.7, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(1806.0,-850.0), new Vector2(40.5,38.75), MenuGog.AtlasResourcePathRef(), MenuGog.GetGogDefaultRewardPath(), 0.7, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(-1822.0,946.0), new Vector2(130.0,38.0), GeneralFluff.AtlasResourcePathRef(), GeneralFluff.GetPatern01Path(), 0.4, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(-1822.0,904.0), new Vector2(130.0,38.0), GeneralFluff.AtlasResourcePathRef(), GeneralFluff.GetPatern02Path(), 0.4, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(-1822.0,860.0), new Vector2(130.0,38.0), GeneralFluff.AtlasResourcePathRef(), GeneralFluff.GetPatern03Path(), 0.4, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(1782.0,142.0), new Vector2(407.0,1720.0), GeneralFluff.AtlasResourcePathRef(), GeneralFluff.GetFluffWindow2t1Path(), 0.1, MainColors.PanelRed()));

        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(-1600.0,700.0), new Vector2(593.0,240.0), BootingSystems.AtlasResourcePathRef(), BootingSystems.GetFluff06Path(), 0.2, MainColors.PanelRed()));
        ArrayPush(this.allImageFluffs, InkImageWidget.CreateWithImage(this.root, new Vector2(-1464.0,920.0), new Vector2(593.0,79.0), BootingSystems.AtlasResourcePathRef(), BootingSystems.GetFluff08Path(), 0.2, MainColors.PanelRed()));

    }

    protected cb func OnCreate() -> Void
    {
        if(!IsDefined(this.settings))
        {
            this.settings = PatternRecognitionHackSettings.Default();
        }
        this.CreateWidgets();
    }

    protected cb func OnInitialize() -> Void 
    {
        super.OnInitialize();

        //this.videoBackground.PlayLooped(r"base\\movies\\fullscreen\\common\\finalboards\\rain_splash.bk2", n"None");
        this.videoBackground.video.SetOpacity(0.0);

        //Play Introduction Video
        this.introVideo.video.Play();
        
        //Play Fluff anims
        for fluff in this.allFluffs
        {
            fluff.PlayLooped();
        }

        //Reveal Programs after 3 seconds
        let revealProgramsCallback: ref<RevealPrograms> = RevealPrograms.Create(this);
        GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(revealProgramsCallback, 3.0, false);


        //Reveal Grid after 9 seconds (nearly before end)
        let revealPatternRecognitionHackCallback: ref<RevealPatternRecognitionHack> = RevealPatternRecognitionHack.Create(this);
        this.introVideo.QueueEventDuringVideo(revealPatternRecognitionHackCallback, 9.0);
        
        //Reveal Progress bars after 5 seconds (during the introduction video)
        let revealStatusCallback: ref<RevealStatus> = RevealStatus.Create(this);
        this.introVideo.QueueEventDuringVideo(revealStatusCallback, 5.0);

        let onEndVideo: ref<OnVideoIntroductionEnded> = OnVideoIntroductionEnded.Create(this);
        this.introVideo.QueueEventOnEnd(onEndVideo);

        this.RegisterListeners(this.uniformGridPanel);
    }

    protected func RegisterStartButtonListeners() -> Void
    {
        this.startButton.RegisterToCallback(n"OnBtnClick", this, n"StartGame");
        this.canStartGame = true;
    }

    protected func RegisterQuitButtonListeners() -> Void
    {
        this.endButton.RegisterToCallback(n"OnBtnClick", this, n"QuitGame");
    }

    public func SetMinigameState(newState: HackingMinigameState) -> Void
    {
        this.minigameState = newState;
        switch(newState)
        {
        case HackingMinigameState.Unknown:
            break;     
        case HackingMinigameState.InProgress:
            this.StartGameInstance();
            break;
        case HackingMinigameState.Succeeded:
            LogChannel(n"DEBUG","Success");
            let successCallback:ref<OnGameSuccess> = OnGameSuccess.Create(this);
            GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(successCallback, 1.0, false);
            break;
        case HackingMinigameState.Failed:
            let failureCallback:ref<OnGameFailure> = OnGameFailure.Create(this);
            GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(failureCallback, 1.0, false);
            LogChannel(n"DEBUG","Failure");
            break;
        }
    }

    public func SetMinigameInstanceState(newState: HackingMinigameState) -> Void
    {
        this.minigameState = newState;
        this.shouldUpdateGameTimers = false;
        switch(newState)
        {
        case HackingMinigameState.Unknown:
            break;     
        case HackingMinigameState.InProgress:
            this.StartGameInstance();
            break;
        case HackingMinigameState.Succeeded:
            this.OnGameInstanceSuccess();
            break;
        case HackingMinigameState.Failed:
            this.OnGameInstanceFailure();
            break;
        }
    }

    protected cb func QuitGame(widget: wref<inkWidget>) -> Bool
    {
        this.popupParent.canLeavePopup = true;
        this.HandleResolvedPrograms();
        this.popupParent.Close();
    }

    protected cb func StartGame(widget: wref<inkWidget>) -> Bool
    {
        this.startButton.m_root.SetInteractive(false);
        //this.startButton.m_root.TintShift(this.startButton.m_root.GetTintColor(), new HDRColor(1.0,1.0,1.0,0.0), 0.5, true, false);
        this.startButton.m_root.FadeInEntry(true, true, true);

        for program in this.allPrograms
        {
            program.progressBarStatusText.textWidget.SetText("Waiting...");
        }

        this.SetMinigameState(HackingMinigameState.InProgress);
    }

    public func StartGameInstance() -> Void
    {
        if (this.canStartGame)
        {
            this.shouldUpdateGameTimers = true;
            this.minigameState = HackingMinigameState.InProgress;
            this.isInGame = true;
            this.allPrograms[this.currentProgramIndex].SetPanelState(EHackProgramPanelState.InProgress);
            for button in this.allButtons
            {
                button.m_frame.TintShift(MainColors.White(), MainColors.ActiveBlue(), 0.5, true, false);
                button.m_label.SetTintColor(MainColors.Grey());
                button.SetHoveredState(false);
                button.m_root.SetInteractive(true);

            }
            this.SetInstanceDefaultValues();

            this.answerText.SetText(this.GetAnswerText(true));
        }
    }

    public func OnGameInstanceSuccess() -> Void
    {
        ArrayPush(this.resolvedPrograms,this.settings.programs[this.currentProgramIndex]);
        this.allPrograms[this.currentProgramIndex].SetPanelState(EHackProgramPanelState.Success);

        this.OnEndGameInstance();
    }

    public func OnGameInstanceFailure() -> Void
    {
        this.allPrograms[this.currentProgramIndex].SetPanelState(EHackProgramPanelState.Failure);
        this.OnEndGameInstance();
    }

    public func OnEndGameInstance() -> Void
    {
        this.currentProgramIndex += 1;
        
        //Highlight answer
        let answerAsBoxes = this.GetAnswerBoxUI();

        for box in this.allButtons
        {
            box.m_root.SetInteractive(false);
            box.m_frame.TintShift(MainColors.White(), MainColors.ActiveBlue(), 0.1, true, true);
        }
        for box in answerAsBoxes
        {
            let currentColor = box.m_label.GetTintColor();
            box.m_label.TintShift(currentColor, MainColors.Green(), 0.75, true, false);
        }

        if (this.currentProgramIndex == ArraySize(this.settings.programs))
        {
            let gameOverallState: HackingMinigameState = ArraySize(this.resolvedPrograms) != 0 ? HackingMinigameState.Succeeded : HackingMinigameState.Failed;
            this.SetMinigameState(gameOverallState);
        }
        else
        {
            let restartGameEvt: ref<RestartGameInstance> = RestartGameInstance.Create(this);
            GameInstance.GetDelaySystem(this.GetPlayer().GetGame()).DelayCallback(restartGameEvt, 2.0, false);
        }
    }

    protected func RegisterListeners(container: wref<inkCompoundWidget>) -> Void
    {
        let childIndex: Int32 = 0;
        
        let numChildren: Int32 = container.GetNumChildren();

        while childIndex < numChildren
        {
            let widget: ref<inkWidget> = container.GetWidgetByIndex(childIndex);
            let button: ref<HackingMinigameButton> = widget.GetController() as HackingMinigameButton;

            if (IsDefined(button))
            {
                button.RegisterToCallback(n"OnBtnClick", this, n"OnClick");
                button.RegisterToCallback(n"OnLeave", this, n"OnLeave");
            }

            childIndex += 1;
        }
    }

    public func OnHoverInAllSelections(index:Int32) -> Void
    {
        let i:Int32 = 0;
        let j:Int32 = 0;
        while (i < ArraySize(this.allButtons))
        {
            if(this.allButtons[i].indexInGrid == index)
            {
                while (j < Cast<Int32>(this.settings.answerLength))
                {
                    this.allButtons[this.GetBoxIndexWrapped(i + j, this.totalBoxes)].SetHoveredState(true);
                    j += 1;
                }
                return;
            }
            i += 1;
        }

    }

    public func OnHoverOutAllSelections(index:Int32) -> Void
    {
        let i:Int32 = 0;
        let j:Int32 = 0;
        while (i < ArraySize(this.allButtons))
        {
            if(this.allButtons[i].indexInGrid == index)
            {
                while (j < Cast<Int32>(this.settings.answerLength))
                {
                    this.allButtons[this.GetBoxIndexWrapped(i + j, this.totalBoxes)].SetHoveredState(false);
                    j += 1;
                }
                return;
            }
            i += 1;
        }
    }



    protected cb func OnClick(widget: wref<inkWidget>) -> Bool
    {
        let button: ref<HackingMinigameButton> = widget.GetController() as HackingMinigameButton;

        let buttonContent: Int32 = button.indexInGrid;
        if(this.answers == buttonContent)
        {
            this.SetMinigameInstanceState(HackingMinigameState.Succeeded);
        }
        else
        {
            this.currentAttempts -= 1;
            if(this.currentAttempts <= 0)
            {
                this.SetMinigameInstanceState(HackingMinigameState.Failed);
            }
        }
    }

    //Sets the default values/timers for an instance (attempt) of the minigame
    public func SetInstanceDefaultValues() -> Void
    {
        this.currentTime = this.settings.maximumTime;
        this.moveBoxContentTimer = 1.0 / this.settings.boxMovingSpeedPerSec;
        this.instanceBoxContent = this.GenerateAllBoxContents(); 
        this.answers = RandRange(0, this.totalBoxes);

        if (!this.settings.advancedSettings.allowMultipleSameAnswers)
        {
            while(this.HasDuplicateAnswers())
            {
                this.instanceBoxContent = this.GenerateAllBoxContents();
                this.answers = RandRange(0, this.totalBoxes);
            }
        }
        
        this.UpdateAllBoxesText();
    }

    public func HasDuplicateAnswers() -> Bool
    {
        let answerAsText:String = this.GetAnswerText();
        let boxIndex:Int32 = 0;
        while (boxIndex < ArraySize(this.instanceBoxContent))
        {
            let box: ref<BoxContent> = this.instanceBoxContent[boxIndex];
            if (box.indexInGrid != this.answers)
            {
                let i:Int32 = 0;
                let possibleDuplicate:String = "";
                while (i < Cast<Int32>(this.settings.answerLength))
                {
                    possibleDuplicate += this.instanceBoxContent[this.GetBoxIndexWrapped(boxIndex + i,this.totalBoxes)].text;
                    i += 1;
                }

                if (Equals(possibleDuplicate,answerAsText))
                {
                    return true;
                }
            }
            boxIndex += 1;
        }
        return false;
    }

    public func GetAnswerText(opt allowSpaces: Bool) -> String
    {
        let answerAsText:String = "";
        let i:Int32 = 0;
        while (i < Cast<Int32>(this.settings.answerLength))
        {
            answerAsText += this.instanceBoxContent[this.GetBoxIndexWrapped(this.answers + i, this.totalBoxes)].text;
            if(allowSpaces && i != Cast<Int32>(this.settings.answerLength) - 1)
            {
                answerAsText += " ";
            }
            i += 1;
        }
        return answerAsText;
    }

    public func GetAnswerBoxContent() -> array<ref<BoxContent>>
    {
        let boxes:array<ref<BoxContent>>;
        let i:Int32 = 0;
        while (i < Cast<Int32>(this.settings.answerLength))
        {
            ArrayPush(boxes,this.instanceBoxContent[this.GetBoxIndexWrapped(this.answers + i, this.totalBoxes)]);

            i += 1;
        }
        return boxes;    
    }

    public func GetAnswerBoxUI() -> array<ref<HackingMinigameButton>>
    {
        let buttons: array<ref<HackingMinigameButton>>;
        let i: Int32 = 0;
        let j: Int32 = 0;

        //this is SUPER NOT OPTIMIZED AT ALL
        //DONT DO THIS IRL
        while (i < ArraySize(this.allButtons))
        {
            if(this.allButtons[i].indexInGrid == this.answers)
            {
                while (j < Cast<Int32>(this.settings.answerLength))
                {
                    ArrayPush(buttons,this.allButtons[this.GetBoxIndexWrapped(i + j,this.totalBoxes)]);
                    j += 1;
                }
                return buttons;
            }
            i += 1;
        }
        return buttons;    
    }

    public func SwapBoxContents() -> Void
    {
        let contentCopy:array<ref<BoxContent>>;

        for content in this.instanceBoxContent
        {
            ArrayPush(contentCopy,content);
        }

        let i:Int32 = 0;
        while (i < ArraySize(contentCopy))
        {
            this.instanceBoxContent[i] = contentCopy[this.GetBoxIndexWrapped(i - 1,Cast<Int32>(this.settings.gridSize * this.settings.gridSize))];
            i += 1;
        }
        this.UpdateAllBoxesText();

    }

    public func GetBoxesFromIndexInGrid(indexInGrid:Int32,length:Int32) -> array<ref<BoxContent>>
    {
        let retVal:array<ref<BoxContent>>;
        for box in this.instanceBoxContent
        {
            if(box.indexInGrid == indexInGrid)
            {
                let i:Int32 = 0;
                while(i < length)
                {
                    ArrayPush(retVal,box);
                    i += 1;
                }
                return retVal;
            }
        }

        return retVal;
    }

    public func UpdateAllBoxesText() -> Void
    {
        let i:Int32 = 0;
        for box in this.allButtons
        {
            box.SetText(this.instanceBoxContent[i].text);
            box.indexInGrid = this.instanceBoxContent[i].indexInGrid;
            i += 1;
        }
    }

    public func GetBoxIndexWrapped(integer:Int32, maximum: Int32) -> Int32
    {
        return integer >= 0 ? integer % maximum : (integer % maximum + maximum) % maximum;
    }

    public func GenerateAllBoxContents() -> array<ref<BoxContent>>
    {
        let allContents: array<ref<BoxContent>>;
        let letterPattern:array<String> = this.GetBoxText();

        let x: Int32 = 0;
        let y: Int32 = 0;
        let total: Int32 = 0;
        while (y < Cast<Int32>(this.settings.gridSize))
        {
            while (x < Cast<Int32>(this.settings.gridSize))
            {
                let content:ref<BoxContent> = new BoxContent();
                content.text = letterPattern[RandRange(0, ArraySize(letterPattern))];
                content.indexInGrid = total;
                ArrayPush(allContents,content);
                x += 1;
                total += 1;
            }
            x = 0;
            y += 1;
        }
        x = 0;
        y = 0;

        return allContents;
    }

	//Called Every frame
	public func TickUpdate(deltaTime: Float) -> Void
	{
        super.TickUpdate(deltaTime);
        if (this.shouldUpdateGameTimers)
        {
            this.UpdateTimers(deltaTime);
            while(this.moveBoxContentTimer <= 0.0)
            {
                this.moveBoxContentTimer += 1.0 / this.settings.boxMovingSpeedPerSec;
                this.SwapBoxContents();
            }
            this.swapBoxTimerProgressBar.SetProgress(this.moveBoxContentTimer / 1.0 / this.settings.boxMovingSpeedPerSec);
            let remainingUintTime:Float = this.currentTime / this.settings.maximumTime;
            remainingUintTime = MaxF(remainingUintTime,0.0);

            this.instanceProgressBar.SetProgress(remainingUintTime);
            
            this.remainingTimeText.textWidget.SetText(FloatToStringPrec(this.currentTime,3));
            if(remainingUintTime <= 0.3)
            {
                this.remainingTimeText.textWidget.SetTintColor(MainColors.CombatRed());
            }
            else
            {
                this.remainingTimeText.textWidget.SetTintColor(MainColors.ActiveBlue());
            }

            if(this.currentTime <= 0.0)
            {
                this.SetMinigameInstanceState(HackingMinigameState.Failed);
            }
        }
	}

    protected func UpdateTimers(deltaTime: Float)
    {
        this.currentTime -= deltaTime;
        this.currentTime = MaxF(this.currentTime,0.0);
        this.moveBoxContentTimer -= deltaTime;
    }

    public func GetBoxText() -> array<String>
    {
        switch (this.settings.letterType)
        {
        case EPatternRecognitionHackLetterType.HackingMinigame:
            return ["1C","55","BD","E9","7A","FF"];
        case EPatternRecognitionHackLetterType.Numerical:
            return ["0","1","2","3","4","5","6","7","8","9"];
        case EPatternRecognitionHackLetterType.Alphabetical:
            return ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
        case EPatternRecognitionHackLetterType.Alphanumerical:
            return ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9"];
        //Only a few most used greek letters do appear
        case EPatternRecognitionHackLetterType.Greek:
            return ["Α","Β","Γ","Δ","Ε","Ζ","Η","Θ","Ι","Κ","Λ","Μ","Ν","Ξ","Ο","Π","Ρ","Σ","Τ","Υ","Φ","Χ","Ψ","Ω"];
        //None of those appear on screen
        case EPatternRecognitionHackLetterType.Runic:
            return ["ᚠ","ᚥ","ᚧ","ᚨ","ᚩ","ᚬ","ᚭ","ᚻ","ᛐ","ᛑ","ᛒ","ᛓ","ᛔ","ᛕ","ᛖ","ᛗ","ᛘ","ᛙ","ᛚ","ᛛ","ᛜ","ᛝ","ᛞ","ᛟ","ᛤ"];
        }
    }
}



public class OnGameInstanceSuccess extends PatternRecognitionHackCallback
{
    public func Call() -> Void
    {

    }
    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<OnGameInstanceSuccess>
    {
        let callback:ref<OnGameInstanceSuccess> = new OnGameInstanceSuccess();
        callback.controller = controller;
        return callback;
    }
}

public class OnGameInstanceFailure extends PatternRecognitionHackCallback
{
    public func Call() -> Void
    {

    }

    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<OnGameInstanceFailure>
    {
        let callback:ref<OnGameInstanceFailure> = new OnGameInstanceFailure();
        callback.controller = controller;
        return callback;
    }


}

public class OnGameSuccess extends PatternRecognitionHackCallback
{
    public func Call() -> Void
    {
        LogChannel(n"DEBUG","OnGameSuccess");
        this.controller.endScreenText.root.FadeInEntry(true, false, true, 0.0);
        this.controller.endScreenText.textWidget.SetTintColor(MainColors.ActiveGreen());
        this.controller.endScreenText.textWidget.SetText("Success");

        for button in this.controller.allButtons
        {
            button.m_root.EaseOutOpacity(1.0,0.0, 9.0, true, false);
        }
        this.controller.endButton.m_root.FadeInEntry(true, false, true, 0.5);
        this.controller.endButton.m_root.SetInteractive(true);
        this.controller.endButton.m_root.SetVisible(true);
    }

    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<OnGameSuccess>
    {
        let callback:ref<OnGameSuccess> = new OnGameSuccess();
        callback.controller = controller;
        return callback;
    }
}

public class OnGameFailure extends PatternRecognitionHackCallback
{
    public func Call() -> Void
    {
        this.controller.endScreenText.root.FadeInEntry(true, false, true, 0.0);
        this.controller.endScreenText.textWidget.SetTintColor(MainColors.ActiveRed());
        this.controller.endScreenText.textWidget.SetText("Failure");
        for button in this.controller.allButtons
        {
            button.m_root.EaseOutOpacity(1.0,0.0, 9.0, true, false);
        }
        this.controller.endButton.m_root.FadeInEntry(true, false, true, 0.5);
        this.controller.endButton.m_root.SetInteractive(true);
        this.controller.endButton.m_root.SetVisible(true);

    }

    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<OnGameFailure>
    {
        let callback:ref<OnGameFailure> = new OnGameFailure();
        callback.controller = controller;
        return callback;
    }
}

public class RestartGameInstance extends PatternRecognitionHackCallback
{
    public func Call() -> Void
    {
        if(IsDefined(this.controller))
        {
            this.controller.StartGameInstance();
        }
    }

    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<RestartGameInstance>
    {
        let callback:ref<RestartGameInstance> = new RestartGameInstance();
        callback.controller = controller;
        return callback;
    }
}

public class RevealPrograms extends PatternRecognitionHackCallback
{
    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<RevealPrograms>
    {
        let callback:ref<RevealPrograms> = new RevealPrograms();
        callback.controller = controller;
        return callback;
    }

    public func Call() -> Void
    {
        let totalCount:Int32 = 0;
        for program in this.controller.allPrograms
        {
            program.m_root.EaseOutOpacity(0.0, 1.0, 0.1 + 0.25 * Cast<Float>(totalCount), true, false);
            program.m_root.FadeInEntry(true, false, false, 0.1);
            program.startFluffProgressBar = true;
            program.progressBarFluffMaxTime = RandRangeF(2.0,5.0);

            totalCount += 1;
        }

        this.controller.remainingTimeText.root.FadeInEntry(true, false, true, 0.0);
        this.controller.remainingTimeText.root.GlitchIn(7u, false, 0.0, new Vector2(0.25,0.55), true, false, 0.0);

    }
}

public class OnVideoIntroductionEnded extends PatternRecognitionHackCallback
{
    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<OnVideoIntroductionEnded>
    {
        let callback:ref<OnVideoIntroductionEnded> = new OnVideoIntroductionEnded();
        callback.controller = controller;
        return callback;
    }

    public func Call() -> Void
    {
        this.controller.remainingTimeText.textWidget.SetText("STATUS : ON");
        this.controller.remainingTimeText.textWidget.SetTintColor(MainColors.ActiveBlue());
        this.controller.RegisterStartButtonListeners();
        this.controller.RegisterQuitButtonListeners();
    }
}

public class RevealStatus extends PatternRecognitionHackCallback
{
    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<RevealStatus>
    {
        let callback:ref<RevealStatus> = new RevealStatus();
        callback.controller = controller;
        return callback;
    }

    public func Call() -> Void
    {
        this.controller.swapBoxTimerProgressBar.m_root.FadeInEntry(true, false, true, 0.0);
        this.controller.instanceProgressBar.m_root.FadeInEntry(true, false, true, 0.15);
    }
}


public class RevealPatternRecognitionHack extends PatternRecognitionHackCallback
{
    public static func Create(controller:ref<PatternRecognitionHack>) -> ref<RevealPatternRecognitionHack>
    {
        let callback:ref<RevealPatternRecognitionHack> = new RevealPatternRecognitionHack();
        callback.controller = controller;
        return callback;
    }

    public func Call() -> Void
    {
        let totalCount:Int32 = 0;

        for button in this.controller.allButtons
        {
            //Pop-in anim (from ColorPalette.reds)
            let scaleAnim: ref<inkAnimScale> = new inkAnimScale();
            scaleAnim.SetStartScale(new Vector2(0.6, 0.6));
            scaleAnim.SetEndScale(new Vector2(1.0, 1.0));
            scaleAnim.SetType(inkanimInterpolationType.Linear);
            scaleAnim.SetMode(inkanimInterpolationMode.EasyOut);
            scaleAnim.SetDuration(0.04);

            let alphaAnim: ref<inkAnimTransparency> = new inkAnimTransparency();
            alphaAnim.SetStartTransparency(0.0);
            alphaAnim.SetEndTransparency(1.0);
            alphaAnim.SetType(inkanimInterpolationType.Linear);
            alphaAnim.SetMode(inkanimInterpolationMode.EasyOut);
            alphaAnim.SetDuration(0.075);

            let animDef: ref<inkAnimDef> = new inkAnimDef();
            animDef.AddInterpolator(scaleAnim);
            animDef.AddInterpolator(alphaAnim);

            let animOpts: inkAnimOptions;
            animOpts.executionDelay = (0.025 * Cast<Float>(totalCount));
            
            button.m_label.PlayAnimationWithOptions(animDef, animOpts);

            //Non Random glitch amount
            //button.m_frame.GlitchIn(Cast<Uint32>(3u, true, 0.05, new Vector2(0.0,0.0), true, false,RandRangeF(0.05,0.1));
            
            button.m_root.FadeInEntry(true, false,false);
            button.m_root.GlitchIn(Cast<Uint32>(RandRange(2,9)), true, 0.05, new Vector2(0.0,0.0), true, false, RandRangeF(0.05,0.1));

            totalCount += 1;
        }
    }
}