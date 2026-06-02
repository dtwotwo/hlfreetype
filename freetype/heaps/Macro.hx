package freetype.heaps;

/**
	Initialization macro for Heaps integration.
**/
class Macro {
	/**
		Registers freetype extensions in Heaps resource manager.
	**/
	public static macro function main() {
		#if heaps
		final p = "freetype.heaps.FreeTypeFontResource";
		hxd.res.Config.addExtension("ttf", p);
		hxd.res.Config.addExtension("ttc", p);
		hxd.res.Config.addExtension("otf", p);
		#end

		return macro null;
	}
}
