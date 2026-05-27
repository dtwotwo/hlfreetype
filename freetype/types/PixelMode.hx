package freetype.types;

enum abstract PixelMode(Int) to Int {
	private function new(value:Int) {
		this = value;
	}

	final None = 0;
	final Mono = 1;
	final Gray = 2;
	final Gray2 = 3;
	final Gray4 = 4;
	final LCD = 5;
	final LCDV = 6;
	final BGRA = 7;
}
