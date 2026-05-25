package freetype.types;

import haxe.io.Bytes;

@:keep
class Bitmap {
	public var rows:Int = 0;
	public var width:Int = 0;
	public var pitch:Int = 0;
	public var buffer:hl.Bytes;
	public var numGrays:hl.UI16 = 0;

	var pixelModeValue:hl.UI8 = 0;

	public function new() {}

	public var pixelMode(get, never):PixelMode;

	inline function get_pixelMode():PixelMode {
		return @:privateAccess new PixelMode(pixelModeValue);
	}

	public var height(get, never):Int;

	inline function get_height():Int {
		return rows;
	}

	public var byteLength(get, never):Int;

	inline function get_byteLength():Int {
		return rows * (pitch < 0 ? -pitch : pitch);
	}

	public function toBytes():Bytes {
		final length = byteLength;
		if (buffer == null || length <= 0)
			return Bytes.alloc(0);
		return @:privateAccess new Bytes(buffer, length);
	}

	#if heaps
	public function writePixels(dest:hxd.Pixels, tx:Int = 0, ty:Int = 0):Void {
		switch ([pixelMode, dest.format]) {
			case [Gray, BGRA], [Gray, RGBA], [Gray, ARGB] if (numGrays == 256):
				for (y in 0...rows)
					for (x in 0...width)
						dest.setPixel(tx + x, ty + y, buffer.getUI8(y * pitch + x) << 24 | 0xFFFFFF);
			default:
				throw "Unsupported bitmap conversion " + pixelMode + " to " + dest.format;
		}
	}
	#end
}
