import freetype.heaps.FreeTypeFont;
import freetype.heaps.DynamicFreeTypeFont;
import h2d.Text;
import hxd.Key;
import sys.FileSystem;

class TestHeapsWindow extends hxd.App {
	static final footerText = "Space: add dynamic line. Wheel: resize. A: antialiasing. Escape: close.";
	static final initialText = [
		"FreeType dynamic glyph generation",
		"",
		"The font starts with only '?' preloaded.",
		"Each Space press appends text whose glyphs are rendered into the atlas on demand.",
		"",
		"Cut test: LIST: LIST: LIST:"
	].join("\n");
	static final dynamicLines = [
		"Cut test dynamic: LIST: LIST: LIST:",
		"",
		"ASCII: The quick brown fox jumps over 0123456789.",
		"Latin: ÀÁÂÃÄÅ Æ Ç ÈÉÊË ÌÍÎÏ Ñ ÒÓÔÕÖ Ø ÙÚÛÜ Ý Þ ß",
		"Greek: Ελληνικά ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ",
		"Cyrillic: Кириллица Привет мир ЁЖЗИЙ ФЦЧШЩ ЮЯ",
		"Hebrew: אבגדהוזחטיכלמנסעפצקרשת",
		"Arabic: العربية ابتثجحخدذرزسشصضطظعغفقكلمنهوي",
		"Devanagari: देवनागरी हिन्दी संस्कृत",
		"Thai: ภาษาไทย กขฃคฅฆงจฉชซฌญฎฏฐฑฒณ",
		"CJK: 中文 日本語 한국어 漢字 かな カナ 한글",
		"Symbols: © ® ™ § ¶ • … – — ← ↑ → ↓ ★ ☆ ♫ ✓ ✗ ∞ ≠ ≤ ≥",
		"Math: ∑ ∏ √ ∫ ≈ ÷ × ± ∂ ∆ Ω μ π λ",
		"Emoji fallback test: ☺ ☻ ♥ ♦ ♣ ♠"
	];

	var label:Text;
	var footer:Text;
	var font:DynamicFreeTypeFont;
	var fontPaths:Array<String>;
	var fontSize = 24;
	var antiAliasing = true;
	var visibleLines = 0;

	static function main() {
		new TestHeapsWindow();
	}

	override function init() {
		engine.backgroundColor = 0x202225;

		fontPaths = findFontFallbacks();
		font = createFont();

		label = new Text(font, s2d);
		label.textColor = 0xF2F2F2;
		label.x = 24;
		label.y = 20;
		label.maxWidth = 1100;

		footer = new Text(font, s2d);
		footer.textColor = 0x9AA0A6;
		footer.x = 24;
		footer.y = 600;
		footer.maxWidth = 1100;
		updateText();
	}

	private function createFont():DynamicFreeTypeFont {
		return FreeTypeFont.dynamicFromFiles(fontPaths, fontSize, {
			chars: "?",
			antiAliasing: antiAliasing,
			padding: 2,
			kerning: true,
		});
	}

	override function update(dt:Float) {
		if (Key.isPressed(Key.SPACE) && visibleLines < dynamicLines.length) {
			visibleLines++;
			updateText();
		}

		if (Key.isPressed(Key.MOUSE_WHEEL_UP))
			resizeFont(1);
		if (Key.isPressed(Key.MOUSE_WHEEL_DOWN))
			resizeFont(-1);
		if (Key.isPressed(Key.A))
			toggleAntiAliasing();

		if (Key.isPressed(Key.ESCAPE))
			Sys.exit(0);
	}

	private function toggleAntiAliasing():Void {
		antiAliasing = !antiAliasing;
		rebuildFont();
	}

	private function resizeFont(delta:Int):Void {
		final nextSize = Std.int(Math.max(8, Math.min(96, fontSize + delta)));
		if (nextSize == fontSize)
			return;

		final previous = font;
		fontSize = nextSize;
		rebuildFont(previous);
	}

	private function rebuildFont(?previous:DynamicFreeTypeFont):Void {
		if (previous == null)
			previous = font;
		font = createFont();
		label.font = font;
		footer.font = font;
		updateText();
		previous.dispose();
	}

	private function updateText():Void {
		label.text = initialText + "\n" + dynamicLines.slice(0, visibleLines).join("\n");
		updateFooter();
	}

	private function updateFooter():Void {
		final buf = new StringBuf();
		buf.add('$footerText\n');
		buf.add('Size: $fontSize. ');
		buf.add('Lines: $visibleLines/${dynamicLines.length}. ');
		buf.add('Atlas: ${font.pixels.width}x${font.pixels.height}. ');
		buf.add('AA: ${(antiAliasing ? "on" : "off")}.');
		footer.text = buf.toString();
	}

	static function findFontFallbacks():Array<String> {
		final explicitPath = Sys.getEnv("HLFREETYPE_TEST_FONT");
		final paths = [];
		if (explicitPath != null && explicitPath.length > 0 && FileSystem.exists(explicitPath))
			paths.push(explicitPath);

		addLocalFonts(paths, "fonts");

		for (path in [
			"C:/Windows/Fonts/segoeui.ttf",
			"C:/Windows/Fonts/seguisym.ttf",
			"C:/Windows/Fonts/arial.ttf",
			"C:/Windows/Fonts/arialuni.ttf",
			"C:/Windows/Fonts/Nirmala.ttf",
			"C:/Windows/Fonts/NirmalaUI.ttf",
			"C:/Windows/Fonts/msyh.ttc",
			"C:/Windows/Fonts/simsun.ttc",
			"C:/Windows/Fonts/meiryo.ttc",
			"C:/Windows/Fonts/msgothic.ttc",
			"C:/Windows/Fonts/malgun.ttf",
			"C:/Windows/Fonts/tahoma.ttf"
		])
			if (FileSystem.exists(path) && paths.indexOf(path) == -1)
				paths.push(path);

		if (paths.length == 0)
			throw "No TTF fallback fonts found";
		return paths;
	}

	static function addLocalFonts(paths:Array<String>, dir:String):Void {
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return;

		final names = FileSystem.readDirectory(dir);
		names.sort(Reflect.compare);
		for (name in names) {
			final path = dir + "/" + name;
			if (!FileSystem.isDirectory(path) && isFontPath(path) && paths.indexOf(path) == -1)
				paths.push(path);
		}
	}

	static function isFontPath(path:String):Bool {
		final lower = path.toLowerCase();
		return StringTools.endsWith(lower, ".ttf") || StringTools.endsWith(lower, ".otf") || StringTools.endsWith(lower, ".ttc");
	}
}
