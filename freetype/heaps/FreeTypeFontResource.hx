package freetype.heaps;

#if heaps
import freetype.heaps.types.FontTypes.FreeTypeFontAtlas;
import freetype.heaps.types.FontTypes.FreeTypeFontOptions;
import h2d.Font;
import hxd.res.Resource;

class FreeTypeFontResource extends Resource {
	public function toFont(size:Int, ?options:FreeTypeFontOptions):Font {
		return FreeTypeFont.fromBytes(entry.getBytes(), size, options, entry.path);
	}

	public function toDynamicFont(size:Int, ?options:FreeTypeFontOptions):DynamicFreeTypeFont {
		return FreeTypeFont.dynamicFromBytes(entry.getBytes(), size, options, entry.path);
	}

	public function buildAtlas(size:Int, ?options:FreeTypeFontOptions):FreeTypeFontAtlas {
		return FreeTypeFont.buildAtlas(entry.getBytes(), size, options, entry.path);
	}
}
#else
class FreeTypeFontResource {}
#end
