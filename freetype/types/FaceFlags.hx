package freetype.types;

enum abstract FaceFlags(Int) to Int {
	final Scalable = 0x1;
	final FixedSizes = 0x2;
	final FixedWidth = 0x4;
	final Sfnt = 0x8;
	final Horizontal = 0x10;
	final Vertical = 0x20;
	final Kerning = 0x40;
	final FastGlyphs = 0x80;
	final MultipleMasters = 0x100;
	final GlyphNames = 0x200;
	final ExternalStream = 0x400;
	final Hinter = 0x800;
	final CIDKeyed = 0x1000;
	final Tricky = 0x2000;
	final Color = 0x4000;

	@:op(a | b) static function or(a:FaceFlags, b:FaceFlags):FaceFlags;

	@:op(a & b) static function and(a:FaceFlags, b:FaceFlags):FaceFlags;

	function new(value:Int) {
		this = value;
	}

	public inline function has(flag:FaceFlags):Bool {
		return this & flag != 0;
	}
}
