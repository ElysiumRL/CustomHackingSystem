// -----------------------------------------------------------------------------
// Codeware.UI.Utility
// -----------------------------------------------------------------------------
//
// - Utility Functions for most ink widgets
// - Mostly Animations utilities
//
// -----------------------------------------------------------------------------

module Codeware.UI


//Struct used to store default params from presets in case you want the animations to be played later

public class InkAnimationParams extends IScriptable
{
    public let animDef: ref<inkAnimDef>;
    public let options : inkAnimOptions;
}

@addMethod(inkWidget)
public func EaseInOpacity(start: Float, end: Float, duration: Float, opt playAnim: Bool, opt playReversed: Bool) -> Void
{
    let opacityAnimationParams: ref<inkAnimTransparency> = new inkAnimTransparency();
    opacityAnimationParams.SetStartTransparency(start);
    opacityAnimationParams.SetEndTransparency(end);
    opacityAnimationParams.SetDuration(duration);
    
    opacityAnimationParams.SetMode(inkanimInterpolationMode.EasyIn);
    opacityAnimationParams.SetType(inkanimInterpolationType.Linear);

    let animDefinition = new inkAnimDef();
    animDefinition.AddInterpolator(opacityAnimationParams);
    
    let reverseAnimOpts: inkAnimOptions; 
    reverseAnimOpts.playReversed = playReversed;

    if (playAnim)
    {
        this.PlayAnimationWithOptions(animDefinition, reverseAnimOpts);
    }
    //let params : InkAnimationParams;
    //params.animDef = animDefinition;
    //params.options = reverseAnimOpts;
    //return params;
}

@addMethod(inkWidget)
public func EaseOutOpacity(start: Float, end: Float, duration: Float, opt playAnim: Bool, opt playReversed: Bool) -> Void
{
    let opacityAnimationParams: ref<inkAnimTransparency> = new inkAnimTransparency();
    opacityAnimationParams.SetStartTransparency(start);
    opacityAnimationParams.SetEndTransparency(end);
    opacityAnimationParams.SetDuration(duration);
    
    opacityAnimationParams.SetMode(inkanimInterpolationMode.EasyOut);
    opacityAnimationParams.SetType(inkanimInterpolationType.Linear);

    let animDefinition = new inkAnimDef();
    animDefinition.AddInterpolator(opacityAnimationParams);
    
    let reverseAnimOpts: inkAnimOptions; 
    reverseAnimOpts.playReversed = playReversed;

    if (playAnim)
    {
        this.PlayAnimationWithOptions(animDefinition, reverseAnimOpts);
    }
    //let params : InkAnimationParams;
    //params.animDef = animDefinition;
    //params.options = reverseAnimOpts;
    //return params;
}

@addMethod(inkWidget)
public func TintShift(start: HDRColor, end: HDRColor, duration: Float, opt playAnim: Bool, opt playReversed: Bool) -> ref<inkAnimProxy>
{
    let colorAnimationParams: ref<inkAnimColor> = new inkAnimColor();
    colorAnimationParams.SetStartColor(start);
    colorAnimationParams.SetEndColor(end);
    colorAnimationParams.SetDuration(duration); 
    
    let animDefinition = new inkAnimDef();
    animDefinition.AddInterpolator(colorAnimationParams);
    
    let reverseAnimOpts: inkAnimOptions; 
    reverseAnimOpts.playReversed = playReversed;

    //if (true)
    //{
        let animProxy: ref<inkAnimProxy> = this.PlayAnimationWithOptions(animDefinition, reverseAnimOpts);
    //}
    //let params : InkAnimationParams;
    //params.animDef = animDefinition;
    //params.options = reverseAnimOpts;
    //return params;
    return animProxy;
}

@addMethod(inkWidget)
public func GlitchIn(
    glitchAmount: Uint32,
    uniformGlitchTime: Bool,
    opt uniformTimePerGlitch: Float,
    opt randomGlitchTimeDistribution: Vector2, 
    opt playAnim: Bool, opt playReversed: Bool,opt extraExecutionDelay: Float) -> Void
{
	let animDefinition: ref<inkAnimDef> = new inkAnimDef();
    
    let totalGlitchAdded: Uint32 = 0u;
    let totalTime: Float = 0.0;
    if(glitchAmount % 2u == 0u)
    {
        glitchAmount += 1u;
    }
    while(totalGlitchAdded < glitchAmount * 2u)
    {
        let toggleVisibility :ref<inkAnimToggleVisibilityEvent> = new inkAnimToggleVisibilityEvent();
        let startTime:Float = uniformTimePerGlitch;
        if(!uniformGlitchTime)
        {
            startTime = RandRangeF(randomGlitchTimeDistribution.X,randomGlitchTimeDistribution.Y);
        }
        totalTime += startTime;
        toggleVisibility.SetStartTime(totalTime);
        animDefinition.AddEvent(toggleVisibility);

        totalGlitchAdded += 1u;
    }

    let reverseAnimOpts: inkAnimOptions; 
    reverseAnimOpts.playReversed = playReversed;
    reverseAnimOpts.executionDelay = extraExecutionDelay;
    
    if (playAnim)
    {
	    this.PlayAnimationWithOptions(animDefinition, reverseAnimOpts);
    }
    //let params : InkAnimationParams;
    //params.animDef = animDefinition;
    //params.options = reverseAnimOpts;
    
    //return params;
}
//Taken from codeware : Journal.reds
@addMethod(inkWidget)
public func FadeInEntry(opt playAnim: Bool,opt playReversed: Bool, opt useWidgetOriginalLocation:Bool, opt executionDelay: Float) -> Void
{
	let marginAnim: ref<inkAnimMargin> = new inkAnimMargin();
    if(useWidgetOriginalLocation)
    {
        let originalMargin:inkMargin = this.GetMargin();
        let endPositionMargin:inkMargin = this.GetMargin();
        endPositionMargin.left += 40.0;
        marginAnim.SetStartMargin(endPositionMargin);
	    marginAnim.SetEndMargin(originalMargin);
    }
    else
    {
        marginAnim.SetStartMargin(new inkMargin(40.0, 0.0, 0.0, 0.0));
	    marginAnim.SetEndMargin(new inkMargin(0.0, 0.0, 0.0, 0.0));
    }
	marginAnim.SetMode(inkanimInterpolationMode.EasyOut);
	marginAnim.SetDuration(0.25);

	let alphaAnim: ref<inkAnimTransparency> = new inkAnimTransparency();
	alphaAnim.SetStartTransparency(0.0);
	alphaAnim.SetEndTransparency(1.0);
	alphaAnim.SetMode(inkanimInterpolationMode.EasyIn);
	alphaAnim.SetDuration(0.5);

	let animDefinition: ref<inkAnimDef> = new inkAnimDef();
	animDefinition.AddInterpolator(marginAnim);
	animDefinition.AddInterpolator(alphaAnim);
    
    let animOpts: inkAnimOptions; 
    animOpts.playReversed = playReversed;
    animOpts.executionDelay = executionDelay;
    if (playAnim)
    {
	    this.PlayAnimationWithOptions(animDefinition, animOpts);
    }
    //let params : InkAnimationParams;
    //params.animDef = animDefinition;
    //params.options = reverseAnimOpts;
    
    //return params;
}