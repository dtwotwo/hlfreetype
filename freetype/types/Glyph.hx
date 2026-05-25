package freetype.types;

@:keep
class Glyph {
	public var glyphIndex:Int = 0;
	public var bitmapLeft:Int = 0;
	public var bitmapTop:Int = 0;
	public var advanceX:Int = 0;
	public var advanceY:Int = 0;
	public final metrics:GlyphMetrics;
	public final bitmap:Bitmap;

	public function new() {
		metrics = new GlyphMetrics();
		bitmap = new Bitmap();
	}
}
