module Elysium.UI

// A Collection of utility methods that can be used for compound widgets
public class CompoundWidgetUtilities
{
    public static func DragMoveToCursor(widget : ref<CompoundWidget>, inPointerEvent: ref<inkPointerEvent>)
    {
        if (widget.AllowDrag())
    	{
    		let cursor: Vector2 = inPointerEvent.GetScreenSpacePosition();
    		let margin: inkMargin = widget.m_dragStartMargin;
    		//let size: Vector2 = this.m_rootWidget.GetSize();
    		if(!inPointerEvent.IsLeftShiftDown())
    		{
    			margin.left += (cursor.X - widget.m_dragStartCursor.X) * 2.0;
    		}
    		//margin.left = MaxF(margin.left, 0);
    		//margin.left = MinF(margin.left, size.X);
    		if(!inPointerEvent.IsControlDown())
    		{
    			margin.top += (cursor.Y - widget.m_dragStartCursor.Y) * 2.0;
    		}
    		//margin.top = MaxF(margin.top, 0);
    		//margin.top = MinF(margin.top, size.Y);
    		widget.m_rootWidget.SetMargin(margin);
    	}
    }

    public static func GetDraggedWidgetViewportPositionAsRedscriptString(widget : ref<CompoundWidget>, inPointerEvent: ref<inkPointerEvent>) -> String
    {
        //Cursor Alignment
    	let cursor: Vector2 = inPointerEvent.GetScreenSpacePosition();

    	switch (widget.m_rootWidget.GetHAlign())
    	{
    	    case inkEHorizontalAlign.Fill:
    	    	break;
    	    case inkEHorizontalAlign.Left:
    	        cursor.X -= 1920.0;
    	    	break;
    	    case inkEHorizontalAlign.Center:
    	        cursor.X -= 1920.0 / 2.0;
    	        cursor.Y -= 1080.0 / 2.0;
    	    	break;
    	    case inkEHorizontalAlign.Right:
    	        cursor.X -= 1920.0;
    	        cursor.Y -= 1080.0 / 2.0;			
    	    	break;				
    	}

    	switch (widget.m_rootWidget.GetVAlign())
    	{
    	    case inkEVerticalAlign.Fill:
    	    	break;
    	    case inkEVerticalAlign.Top:
    	    	break;
    	    case inkEVerticalAlign.Center:
    	        cursor.Y -= 1920.0 / 2.0;
    	    	break;
    	    case inkEVerticalAlign.Bottom:
    	        cursor.Y -= 1920.0;
    	    	break;				
    	}

    	let margin = widget.m_rootWidget.GetMargin();
    	let newPosition:String = NameToString(widget.m_rootWidget.GetName()) + " : new Vector2(" + FloatToStringPrec(margin.left,2) + "," + FloatToStringPrec(margin.top,2) + ")";
    	//LogChannel(n"DEBUG",newPosition);
    
        return newPosition;
    }

}