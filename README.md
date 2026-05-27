# hlfreetype

> This library was inspired by [Motion Twin's original HashLink FreeType binding](https://github.com/motion-twin/hlfreetype)

Native FreeType support for HashLink, with optional Heaps font integration.

## What it does

- adds `freetype.Library` for plain HashLink projects
- loads TTF/OTF fonts from memory
- renders glyphs through FreeType into HashLink bytes
- adds `freetype.heaps.FreeTypeFont` for creating `h2d.Font` from one or more TTF files

## Supported formats

- `ttf`
- `ttc` **(WIP)**
- `otf`

## Plain HashLink usage

```haxe
final library = new freetype.Library();
final face = library.loadFace(sys.io.File.getBytes("font.ttf"));

face.setPixelSize(0, 32);

final glyph = face.renderCodepoint("A".code);
trace(face.familyName);
trace(glyph.bitmap.width + "x" + glyph.bitmap.height);

face.dispose();
library.dispose();
```

Useful API:

- `Library.loadFace(bytes, ?index)`
- `Library.describeLastError()`
- `Face.setPixelSize(width, height)`
- `Face.setSize(points, ?dpi)`
- `Face.glyphIndex(codepoint)`
- `Face.hasGlyph(codepoint)`
- `Face.kerning(leftGlyph, rightGlyph)`
- `Face.renderCodepoint(codepoint, ?loadFlags, ?renderMode, ?out)`

Public data and enum types live in `freetype.types`, for example:

- `freetype.types.Bitmap`
- `freetype.types.Glyph`
- `freetype.types.FaceMetrics`
- `freetype.types.LoadFlags`
- `freetype.types.RenderMode`
- `freetype.types.PixelMode`

## Heaps usage

Create an `h2d.Font` directly from a TTF file:

```haxe
final font = freetype.heaps.FreeTypeFont.fromFile("font.ttf", 24, {
	chars: "Hello Привет こんにちは",
	kerning: true,
});

final text = new h2d.Text(font, s2d);
text.text = "Hello Привет こんにちは";
```

Use multiple font files when your text spans scripts that one font does not cover:

```haxe
final font = freetype.heaps.FreeTypeFont.fromFiles([
	"C:/Windows/Fonts/segoeui.ttf",
	"C:/Windows/Fonts/Nirmala.ttf",
	"C:/Windows/Fonts/msyh.ttc",
	"C:/Windows/Fonts/meiryo.ttc",
	"C:/Windows/Fonts/malgun.ttf",
], 24, {
	chars: "Hello Привет हिन्दी 中文 日本語 한국어",
	kerning: true,
});
```

`fromFiles()` bakes one atlas and chooses the first font that contains each requested character.
It does not magically cover all Unicode; the provided font files must contain the glyphs you want to render.

Use `dynamicFromFiles()` when text can contain characters that were not known up front.
Characters listed in `chars` are preloaded, and later missing glyphs are rendered into the atlas on demand.

Create from bytes:

```haxe
final bytes = sys.io.File.getBytes("font.ttf");
final font = freetype.heaps.FreeTypeFont.fromBytes(bytes, 24);
```

If you need access to the generated atlas pixels:

```haxe
final atlas = freetype.heaps.FreeTypeFont.buildAtlas(bytes, 24, {
	chars: hxd.Charset.DEFAULT_CHARS,
	uploadTexture: true,
});

final font = atlas.font;
final pixels = atlas.pixels;
```

For multi-font atlases:

```haxe
final atlas = freetype.heaps.FreeTypeFont.buildAtlasFromFiles(paths, 24, {
	chars: textToRender,
});
```

Options:

- `chars`: characters to bake into the atlas
- `antiAliasing`: render grayscale glyphs when enabled
- `kerning`: add FreeType kerning pairs
- `padding`: glyph padding in the atlas
- `atlasWidth`: fixed atlas width, or auto when omitted
- `uploadTexture`: create a real Heaps texture when enabled

## Build

FreeType Windows binaries are fetched automatically by CMake.

Requirements:

- CMake 3.10+
- Ninja for the provided preset
- MSVC build tools
- `HASHLINK` environment variable pointing to your HashLink folder

Build:

```sh
cmake --preset release
cmake --build --preset release
```

Outputs:

- `freetype.hdll`
- `freetype.lib` on Windows

FreeType is linked statically, so no separate `freetype.dll` is required.

Place `freetype.hdll` next to your `.hl` output, or otherwise make sure HashLink can load it.

## Tests

Test launchers:

- `tests\test-hl.bat`
- `tests\test-heaps.bat`
- `tests\test-heaps-window.bat`

`test-hl` checks plain FreeType loading, metrics, kerning, glyph rendering, and invalid input.

`test-heaps` checks deterministic `h2d.Font` atlas creation without opening a window.

`test-heaps-window` opens a Heaps window and renders multilingual Unicode sample text from multiple TTF fallback fonts. Press Escape to close.

By default tests use common Windows fonts. You can override the font with:

```sh
set HLFREETYPE_TEST_FONT=C:\Path\To\font.ttf
```

## GitHub Actions

The Windows workflow builds the native library, runs tests, uploads an artifact, and updates the nightly release on pushes to `main`.

The artifact contains:

- `freetype.hdll`
- `freetype.lib`

## TODO

- Linux support
- macOS support
