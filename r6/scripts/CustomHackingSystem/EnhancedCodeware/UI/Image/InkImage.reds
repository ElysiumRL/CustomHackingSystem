// -----------------------------------------------------------------------------
// Codeware.UI.Image
// -----------------------------------------------------------------------------
//
// - Simple wrapper & helper tool for InkImage
// - This helps for placing images & setting up most of the decorative parts (fluffs)
//
// -----------------------------------------------------------------------------

module Codeware.UI

public class InkImageWidget extends inkCustomController
{

    protected let root: wref<inkCompoundWidget>;

    protected let image: ref<inkImage>;

    protected let position: Vector2;

    protected let size: Vector2;

    protected let opacity: Float;

    protected let isBackground: Bool;

    protected let atlasResource: ResRef;

    protected let texturePart: CName;
   
    public const func ShouldRegisterForTickEvent() -> Bool
	{
		return false;
	}

////////////////////////////////
    public const func AllowDrag() -> Bool
	{
		return true;
	}

	protected cb func OnPress(evt: ref<inkPointerEvent>) -> Bool
    {
		super.OnPress(evt);
    }
////////////////////////////////
    protected cb func OnCreate() -> Void
    {
        super.OnCreate();
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
        root.SetName(n"image");
        root.AlignToCenter();
        root.SetSize(this.size);
        root.SetMargin(this.position.X,this.position.Y,0.0,0.0);

        root.SetInteractive(false);

        let image: ref<inkImage> = new inkImage();
        image.AlignToFill();
        image.SetOpacity(this.opacity);
        image.SetVisible(true);
        image.Reparent(root);

        this.image = image;
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

    public func SetTexture(atlasResource: ResRef,texturePart: CName) -> Void
    {
        if(ResRef.IsValid(atlasResource) && IsNameValid(texturePart))
        {
            this.atlasResource = atlasResource;
            this.texturePart = texturePart;
            this.image.SetAtlasResource(atlasResource);
            this.image.SetTexturePart(texturePart);
        }
        else
        {
            LogChannel(n"DEBUG","Texture provided is not valid");
        }
    }

    public static func CreateNoImage(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2, opt opacity : Float, opt color: HDRColor) -> ref<InkImageWidget>
    {
        let image: ref<InkImageWidget> = new InkImageWidget();
        image.opacity = opacity;
        image.size = size;
        image.position = position;
        image.CreateInstance();
        image.SetPosition(position);
        image.SetSize(size);
        image.image.SetTintColor(color);
        image.root.Reparent(root);
        return image;
    }

    public static func CreateWithImage(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2, atlasResource: ResRef, texturePart: CName, opt opacity : Float, opt color: HDRColor) -> ref<InkImageWidget>
    {
        let image: ref<InkImageWidget> = new InkImageWidget();
        image.opacity = opacity;
        image.size = size;
        image.position = position;
        image.CreateInstance();
        image.SetPosition(position);
        image.SetSize(size);
        image.SetTexture(atlasResource, texturePart);
        image.image.SetTintColor(color);
        image.root.Reparent(root);
        return image;
    }

}