package freetype.types;

enum abstract RenderMode(Int) to Int {
	final Normal = 0;
	final Light = 1;
	final Mono = 2;
	final LCD = 3;
	final LCDV = 4;
}
