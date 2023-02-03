// -----------------------------------------------------------------------------
// Codeware.UI.Text
// -----------------------------------------------------------------------------
//
// - Simple Text Wrapper (allows for widget drag & easy tick register)
//
// -----------------------------------------------------------------------------

module Codeware.UI

public class InkTextWidget extends inkCustomController
{

    protected let root: wref<inkCompoundWidget>;
    
    protected let textWidget: ref<inkText>;
   
    protected let position: Vector2;
   
    protected let size: Vector2;
    
    protected let opacity: Float;
    
    protected let text: String;



    public const func AllowDrag() -> Bool
	{
		return true;
	}

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
        let root: ref<inkCanvas> = new inkCanvas();
        root.SetName(n"text");
        root.AlignToCenter();
        root.SetSize(this.size);
        root.SetMargin(this.position.X, this.position.Y, 0.0, 0.0);

        root.SetInteractive(false);

        let text: ref<inkText> = new inkText();
        text.AlignToFill();
        text.SetOpacity(this.opacity);
        text.SetVisible(true);	  
        text.Reparent(root);
        text.SetText(this.text);

        this.textWidget = text;
        this.root = root;
        this.SetRootWidget(this.root);

    }

	protected func RegisterListeners() -> Void 
    {

	}


	public func GetName() -> CName
    {
		return this.root.GetName();
	}

	public func SetName(name: CName) -> Void
    {
		this.root.SetName(name);
	}

	public func SetPosition(x: Float, y: Float) -> Void
    {
        this.SetPosition(new Vector2(x, y));
	}

	public func SetPosition(newPosition: Vector2) -> Void
    {
		this.root.SetMargin(newPosition.X, newPosition.Y, 0, 0);
        this.position = newPosition;
	}

	public func SetWidth(width: Float) -> Void
    {
	    this.root.SetWidth(width);
        this.size.X = width;
	}

	public func SetHeight(height: Float) -> Void
    {
	    this.root.SetHeight(height);
        this.size.Y = height;
	}

    public func GetSize() -> Vector2
    {
        return this.size;
    }

    public func SetSize(newSize: Vector2) -> Void
    {
        this.size = newSize;
        this.root.SetSize(this.size.X, this.size.Y);
    }

    public static func Create(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2,text: String, opt opacity : Float) -> ref<InkTextWidget>
    {
        let textWidget: ref<InkTextWidget> = new InkTextWidget();
        
        textWidget.opacity = opacity;
        textWidget.size = size;
        textWidget.position = position;
        textWidget.text = text;
        
        textWidget.CreateInstance();
        
        textWidget.SetPosition(position);
        textWidget.SetSize(size);
        textWidget.Reparent(root);
        return textWidget;
    }

    public static func CreateButtonText(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2,text: String, opt opacity : Float) -> ref<InkTextWidget>
    {
        let textWidget: ref<InkTextWidget> = InkTextWidget.Create(root, position, size, text, opacity);
        
        textWidget.textWidget.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
		textWidget.textWidget.SetFontStyle(n"Medium");
		textWidget.textWidget.SetFontSize(50);
		textWidget.textWidget.SetLetterCase(textLetterCase.UpperCase);
        textWidget.textWidget.SetOpacity(1.0);
		textWidget.textWidget.SetVisible(true);

        return textWidget;
    }




}