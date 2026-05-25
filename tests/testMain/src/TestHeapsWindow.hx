import freetype.heaps.FreeTypeFont;
import h2d.Text;
import hxd.Key;
import sys.FileSystem;

class TestHeapsWindow extends hxd.App {
	static final footerText = "Press Escape to close. Glyphs are loaded from multiple TTF fallback fonts.";
	static final unicodeSample = [
		"FreeType TTF Unicode rendering",
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
	].join("\n");

	var label:Text;

	static function main() {
		new TestHeapsWindow();
	}

	override function init() {
		engine.backgroundColor = 0x202225;

		final fontPaths = findFontFallbacks();
		final font = FreeTypeFont.fromFiles(fontPaths, 24, {
			chars: unicodeSample + footerText + "?",
			padding: 2,
			kerning: true,
		});

		label = new Text(font, s2d);
		label.text = unicodeSample;
		label.textColor = 0xF2F2F2;
		label.x = 24;
		label.y = 20;
		label.maxWidth = 1100;

		final footer = new Text(font, s2d);
		footer.text = footerText;
		footer.textColor = 0x9AA0A6;
		footer.x = 24;
		footer.y = 700;
		footer.maxWidth = 1100;
	}

	override function update(dt:Float) {
		if (Key.isPressed(Key.ESCAPE))
			Sys.exit(0);
	}

	static function findFontFallbacks():Array<String> {
		final explicitPath = Sys.getEnv("HLFREETYPE_TEST_FONT");
		final paths = [];
		if (explicitPath != null && explicitPath.length > 0 && FileSystem.exists(explicitPath))
			paths.push(explicitPath);

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
}
