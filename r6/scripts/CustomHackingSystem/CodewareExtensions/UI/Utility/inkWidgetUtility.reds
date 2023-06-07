// -----------------------------------------------------------------------------
// Codeware.UI.Utility
// -----------------------------------------------------------------------------
//
// - Utility Functions for most ink widgets
// - Mostly Basic Widget utilities
//
// -----------------------------------------------------------------------------

module Codeware.UI


@addMethod(inkWidget)
public func AlignToCenter() -> Void
{
    this.SetAnchorPoint(new Vector2(0.5, 0.5));
    this.SetAnchor(inkEAnchor.Centered);
    this.SetHAlign(inkEHorizontalAlign.Center);
    this.SetVAlign(inkEVerticalAlign.Center);
}

@addMethod(inkWidget)
public func AlignToFill() -> Void
{
    this.SetAnchor(inkEAnchor.Fill);
    this.SetHAlign(inkEHorizontalAlign.Fill);
    this.SetVAlign(inkEVerticalAlign.Fill);
}