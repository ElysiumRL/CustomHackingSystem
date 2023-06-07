// -----------------------------------------------------------------------------
// HDRColor Extensions
// -----------------------------------------------------------------------------
//
// - Simple extensions for HDRColor manipulation
//
// -----------------------------------------------------------------------------

public static func OperatorMultiply(a: HDRColor, b: Float) -> HDRColor
{
	a.Red *= b;
	a.Green *= b;
	a.Blue *= b;
    //No Alpha
	return a;
}

public static func OperatorDivide(a: HDRColor, b: Float) -> HDRColor
{
	a.Red /= b;
	a.Green /= b;
	a.Blue /= b;
    //No Alpha
	return a;
}
