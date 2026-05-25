package freetype.types;

@:keep
class FaceMetrics {
	public var xPpem:hl.UI16 = 0;
	public var yPpem:hl.UI16 = 0;
	public var xScale:Int = 0;
	public var yScale:Int = 0;
	public var ascender:Int = 0;
	public var descender:Int = 0;
	public var height:Int = 0;
	public var maxAdvance:Int = 0;

	public function new() {}
}
