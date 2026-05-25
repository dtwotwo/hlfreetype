package freetype.types;

enum abstract LoadFlags(Int) to Int {
	final Default = 0x0;
	final NoScale = 1 << 0;
	final NoHinting = 1 << 1;
	final Render = 1 << 2;
	final NoBitmap = 1 << 3;
	final VerticalLayout = 1 << 4;
	final ForceAutohint = 1 << 5;
	final CropBitmap = 1 << 6;
	final Pedantic = 1 << 7;
	final IgnoreGlobalAdvanceWidth = 1 << 9;
	final NoRecurse = 1 << 10;
	final IgnoreTransform = 1 << 11;
	final Monochrome = 1 << 12;
	final LinearDesign = 1 << 13;
	final NoAutohint = 1 << 15;
	final TargetNormal = RenderMode.Normal << 16;
	final TargetLight = RenderMode.Light << 16;
	final TargetMono = RenderMode.Mono << 16;
	final TargetLCD = RenderMode.LCD << 16;
	final TargetLCDV = RenderMode.LCDV << 16;
	final Color = 1 << 20;
	final ComputeMetrics = 1 << 21;
	final BitmapMetricsOnly = 1 << 22;

	@:op(a | b) static function or(a:LoadFlags, b:LoadFlags):LoadFlags;

	@:op(a & b) static function and(a:LoadFlags, b:LoadFlags):LoadFlags;
}
