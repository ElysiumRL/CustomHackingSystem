// -----------------------------------------------------------------------------
// Codeware.UI.ScannerProgressBar
// -----------------------------------------------------------------------------
//
// - The progress bar you see when scanning people or objects
//
// -----------------------------------------------------------------------------

module Codeware.UI
import Codeware.UI.InkAtlas.AtlasScanner2

public class ScannerProgressBar extends CustomProgressBar
{
    //Change the return type by true in order to allow this class to be registered
    //to the Tick Manager
    //(This doesn't mean it will be registered though, you still have to register your object manually)
    public const func ShouldRegisterForTickEvent() -> Bool
    {
        return false;
    }

    //Since there's no constructor in redscript, this is the way to make one
    public static func Create(size: Vector2, position : Vector2, opt defaultProgress: Float) -> ref<ScannerProgressBar> 
    {
        let newProgressBar: ref<ScannerProgressBar> = new ScannerProgressBar();
        newProgressBar.size = size;
        newProgressBar.currentValue = defaultProgress;
        newProgressBar.previousValue = defaultProgress;

        newProgressBar.CreateInstance();
        newProgressBar.SetPosition(position);

        return newProgressBar;
    }
    
    protected func CreateWidgets() -> Void
    {
        let root: ref<inkCanvas> = new inkCanvas();
        root.SetName(n"progressBar");
        root.SetSize(this.size);
        root.AlignToCenter();
        root.SetInteractive(false);

        this.progressBarFrame = inkImage.CreateFromAtlas(AtlasScanner2.AtlasResourcePathRef(), AtlasScanner2.GetProgressBarPath());
        this.progressBarFrame.SetFitToContent(true);
        this.progressBarFrame.AlignToFill();
        this.progressBarFrame.SetTintColor(MainColors.DarkRed());
        this.progressBarFrame.SetVisible(true);
        this.progressBarFrame.SetOpacity(1.0);

        this.progressBarFrame.Reparent(root);
        
        this.progressBarFill = inkImage.CreateFromAtlas(AtlasScanner2.AtlasResourcePathRef(), AtlasScanner2.GetProgressBarPath());
        this.progressBarFill.SetNineSliceScale(true);
        this.progressBarFill.SetSize(new Vector2(this.size.X * this.currentValue, this.size.Y));
        this.progressBarFill.SetAnchor(inkEAnchor.CenterLeft);
        this.progressBarFill.SetAnchorPoint(new Vector2(0.0,0.5));
        this.progressBarFill.SetHAlign(inkEHorizontalAlign.Fill);
        this.progressBarFill.SetVAlign(inkEVerticalAlign.Center);
        this.progressBarFill.SetTintColor(MainColors.CombatRed());
        this.progressBarFill.SetVisible(true);
        this.progressBarFill.SetOpacity(1.0);

        this.progressBarFill.Reparent(root);
        
        this.m_root = root;
        this.SetRootWidget(root);
    }

    protected func RegisterListeners() -> Void 
    {
        //Register events here !
    }

}
