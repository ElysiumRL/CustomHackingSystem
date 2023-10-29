// -----------------------------------------------------------------------------
// Codeware.UI.Video
// -----------------------------------------------------------------------------
//
// - Simple wrapper & helper tool for InkVideo (.bk2 extension format)
//
// -----------------------------------------------------------------------------

module Codeware.UI

public class BufferVideoEvent extends DelayCallback
{
    let controller: wref<InkVideoWidget>;
    
    let callbackToDelay:ref<DelayCallback>;

    let timeOffset:Float;

    let useTimeOffset:Bool;
    
    public func Call() -> Void
    {

        //Video Reference : r"base\\movies\\fullscreen\\reboot-skin.bk2"
        let videoSummary: VideoWidgetSummary = this.controller.video.GetVideoWidgetSummary();
        let delay:Float = 0.0;
        if (this.useTimeOffset)
        {
            delay = this.timeOffset - (Cast<Float>(videoSummary.currentTimeMs) / 1000.0);
        }
        else
        {
            delay = (Cast<Float>(videoSummary.totalTimeMs) - Cast<Float>(videoSummary.currentTimeMs)) / 1000.0;
            this.timeOffset = ClampF(this.timeOffset, 0, delay);
            delay -= this.timeOffset;
        }
        //Debug
        //Log("CurrentFrame : " + ToString(videoSummary.currentFrame));
        //Log("Framerate : " + ToString(videoSummary.frameRate));
        //Log("TotalFrames : " + ToString(videoSummary.totalFrames));
        //Log("TotalTimeMs : " + ToString(videoSummary.totalTimeMs));
        //Log("Width : " + ToString(videoSummary.width));
        //Log("Height : " + ToString(videoSummary.height));

        GameInstance.GetDelaySystem(this.controller.GetGame()).DelayCallback(this.callbackToDelay,delay, false);
    }
}

public class InkVideoWidget extends HackingMinigameCustomController
{

    protected let root: wref<inkCompoundWidget>;
    
    protected let video: ref<inkVideo>;
   
    protected let position: Vector2;
   
    protected let size: Vector2;
    
    protected let opacity: Float;
    
    protected let isBackground: Bool;
    
    protected let videoPath: ResRef;

////////////////////////////////
    public const func AllowDrag() -> Bool
	{
		return false;
	}

	protected cb func OnPress(evt: ref<inkPointerEvent>) -> Bool
    {
        if(this.isBackground)
        {
            return false;
        }
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
        if(this.isBackground)
        {
            this.CreateBackgroundVideo();
        }
        else
        {
            this.CreateNormalVideo();
        }
    }

    protected func CreateNormalVideo() -> Void
    {
        let root: ref<inkCanvas> = new inkCanvas();
        root.SetName(n"video");
        root.AlignToCenter();
        root.SetSize(this.size);
        root.SetMargin(this.position.X,this.position.Y,0.0,0.0);

        root.SetInteractive(false);

        let video: ref<inkVideo> = new inkVideo();
        if(ResRef.IsValid(this.videoPath))
        {
            video.SetVideoPath(this.videoPath);
        }
        video.AlignToFill();
        video.SetOpacity(this.opacity);
        video.SetVisible(true);
        video.Reparent(root);

        this.video = video;
        this.root = root;
        this.SetRootWidget(this.root);
    }

    protected func CreateBackgroundVideo() -> Void
    {
        let root: ref<inkCanvas> = new inkCanvas();
        root.SetName(n"video");
        root.AlignToFill();
        //root.SetFitToContent(true);
        //root.SetMargin(this.position.X,this.position.Y,0.0,0.0);

        let video: ref<inkVideo> = new inkVideo();
        video.AlignToFill();
        video.SetOpacity(this.opacity);
        video.SetVisible(true);
        video.Reparent(root, 0);
        if(ResRef.IsValid(this.videoPath))
        {
            video.SetVideoPath(this.videoPath);
        }
        this.video = video;
        this.root = root;
        this.SetRootWidget(root);
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

    public static func Create(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2, opt opacity : Float,opt videoPath:ResRef) -> ref<InkVideoWidget>
    {
        let video: ref<InkVideoWidget> = new InkVideoWidget();
        video.opacity = opacity;
        video.size = size;
        video.position = position;
        video.videoPath = videoPath;
        video.CreateInstance();
        video.SetPosition(position);
        video.SetSize(size);
        video.root.Reparent(root, 0);
        return video;
    }

    public static func CreateWithColor(root: wref<inkCompoundWidget>, position:Vector2, size:Vector2, opt opacity : Float,opt videoPath:ResRef,opt color:HDRColor) -> ref<InkVideoWidget>
    {
        let video: ref<InkVideoWidget> = new InkVideoWidget();
        video.opacity = opacity;
        video.size = size;
        video.position = position;
        video.videoPath = videoPath;
        video.CreateInstance();
        video.SetPosition(position);
        video.SetSize(size);
        video.video.SetTintColor(color);
        video.root.Reparent(root, 0);
        return video;
    }

    public static func CreateBackground(root: wref<inkCompoundWidget>, opt opacity : Float,opt videoPath:ResRef) -> ref<InkVideoWidget>
    {
        let backgroundVideo: ref<InkVideoWidget> = new InkVideoWidget();
        backgroundVideo.isBackground = true;
        backgroundVideo.opacity = opacity;
        backgroundVideo.videoPath = videoPath; 
        backgroundVideo.CreateInstance();
        backgroundVideo.root.Reparent(root, 0);
        return backgroundVideo;
    }

    public func PlayOnce() -> Void
    {
        this.video.SetLoop(false);
        this.video.Play();
    }

    public func PlayOnce(videoPath: ResRef, opt audioEvent: CName) -> Void
    {
        if (ResRef.IsValid(videoPath))
        {
            this.video.SetVideoPath(videoPath);
            this.video.SetLoop(false);
            if IsNameValid(audioEvent) 
            {
                this.video.SetAudioEvent(audioEvent);
            }
            if(this.video.IsPlayingVideo())
            {
                this.video.Stop();
            }
            this.video.Play();
        }
        else
        {
            //LogChannel(n"DEBUG","[InkVideoWidget::PlayOnce] : videoPath provided is not valid");
        }

    }
    //Taken from ArcadeMachineInkGameController.reds
    public func PlayLooped() -> Void
    {
        this.PlayLooped(this.videoPath, n"None");
    }

    //Taken from ArcadeMachineInkGameController.reds
    public func PlayLooped(videoPath: ResRef, opt audioEvent: CName) -> Void
    {
        if (ResRef.IsValid(videoPath))
        {
            this.video.SetVideoPath(videoPath);
            this.video.SetLoop(true);
            if IsNameValid(audioEvent) 
            {
                this.video.SetAudioEvent(audioEvent);
            }
            if(this.video.IsPlayingVideo())
            {
                this.video.Stop();
            }
            this.video.Play();
        }
        else
        {
            //LogChannel(n"DEBUG","[InkVideoWidget::PlayLooped] : videoPath provided is not valid");
        }
    }

    //Taken from ArcadeMachineInkGameController.reds
    public func PlayVideoWithParams(videoPath: ResRef, looped: Bool, audioEvent: CName) -> Void
    {
        if (ResRef.IsValid(videoPath))
        {
            this.video.SetVideoPath(videoPath);
            this.video.SetLoop(looped);
            if IsNameValid(audioEvent) 
            {
                this.video.SetAudioEvent(audioEvent);
            }
            this.video.Play();
            return;
        }
        //LogChannel(n"DEBUG","[InkVideoWidget::PlayVideoWithParams] : videoPath provided is not valid");
    }

    //DO NOT CHANGE VIDEO FRAMERATE WHEN USING THIS FUNCTION (as this could mess with the delay)
    //Plays an event when reaching video end
    public func QueueEventOnEnd(callbackToDelay: ref<DelayCallback>) -> Void
    {
        //You can't access the VideoWidgetSummary within the first frames where you set.play the video. so you need to run it at least some time after
        //Sometimes you wonder why in the world these kind of things exist ... you know it does not make sense, but it's there only for you to discover it
        let buffer: ref<BufferVideoEvent> = new BufferVideoEvent();
        buffer.controller = this;
        buffer.callbackToDelay = callbackToDelay;
        buffer.timeOffset = 0.0;
        GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(buffer, 0.1, false);
    }
    public func QueueEventDuringVideo(callbackToDelay: ref<DelayCallback>,delay:Float) -> Void
    {
        //You can't access the VideoWidgetSummary within the first frames where you set.play the video. so you need to run it at least some time after
        //Sometimes you wonder why in the world these kind of things exist ... you know it does not make sense, but it's there only for you to discover it
        let buffer: ref<BufferVideoEvent> = new BufferVideoEvent();
        buffer.controller = this;
        buffer.callbackToDelay = callbackToDelay;
        buffer.timeOffset = delay;
        buffer.useTimeOffset = true;
        GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(buffer, 0.1, false);
    }
}