class_name PlaceholderFactory
extends RefCounted

const COLORS: Dictionary = {
	&"box_blue": Color("#3b82f6"), &"box_red": Color("#ef4444"), &"box_orange": Color("#f97316"),
	&"box_brown": Color("#92400e"), &"box_gray": Color("#6b7280"), &"box_white": Color("#f3f4f6"),
	&"box_pink": Color("#ec4899"), &"box_green": Color("#22c55e"), &"box_purple": Color("#a855f7"),
	&"MISSING": Color("#ff00ff"), &"INVALID": Color("#dc2626")
}

static func texture(size: Vector2i, color_name: StringName, frame_index: int = 0) -> Texture2D:
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var base: Color = COLORS.get(color_name, COLORS[&"MISSING"])
	image.fill(base)
	var edge: Color = base.darkened(0.35)
	for x: int in range(size.x):
		image.set_pixel(x, 0, edge); image.set_pixel(x, size.y - 1, edge)
	for y: int in range(size.y):
		image.set_pixel(0, y, edge); image.set_pixel(size.x - 1, y, edge)
	if frame_index % 2 == 1 and size.x > 2 and size.y > 2:
		image.set_pixel(1, 1, base.lightened(0.2))
	return ImageTexture.create_from_image(image)

static func frames(size: Vector2i, color_name: StringName, frame_count: int = 1) -> SpriteFrames:
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	result.add_animation(&"default")
	result.set_animation_loop(&"default", true)
	for index: int in range(maxi(frame_count, 1)):
		result.add_frame(&"default", texture(size, color_name, index))
	return result

static func audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 8000
	stream.stereo = false
	stream.data = PackedByteArray([128, 180, 220, 180, 128, 80, 40, 80])
	return stream
