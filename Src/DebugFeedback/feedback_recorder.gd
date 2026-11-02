extends RefCounted
## Opt-in game-viewport recording, 10 fps / 960px wide / 20 seconds maximum.
## JPEGs are persisted as captured; an interrupted recording remains inspectable.

const FPS := 10
const MAX_SECONDS := 20.0
const MAX_BYTES := 32 * 1024 * 1024
var frames: Array[Dictionary] = []
var directory := ""
var size := Vector2i.ZERO
var bytes_written := 0
var failure := ""
var _started := 0
var _last_frame := -1000

func start(path: String) -> void:
	directory = path
	_started = Time.get_ticks_msec()

func elapsed() -> float:
	return (Time.get_ticks_msec() - _started) / 1000.0

func due() -> bool:
	return Time.get_ticks_msec() - _last_frame >= 1000 / FPS

func full() -> bool:
	return elapsed() >= MAX_SECONDS or bytes_written >= MAX_BYTES or not failure.is_empty()

func capture(image: Image) -> void:
	_last_frame = Time.get_ticks_msec()
	if image == null or image.is_empty():
		failure = "The game viewport could not be captured."
		return
	if size == Vector2i.ZERO:
		var width := mini(960, image.get_width())
		size = Vector2i(width, maxi(2, roundi(image.get_height() * float(width) / image.get_width())))
	image.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	var buffer := image.save_jpg_to_buffer(0.78)
	var filename := "frame_%04d.jpg" % frames.size()
	var file := FileAccess.open(directory.path_join(filename), FileAccess.WRITE)
	if file == null:
		failure = "Could not write recording frame: " + error_string(FileAccess.get_open_error())
		return
	file.store_buffer(buffer)
	var error := file.get_error()
	file.close()
	if error != OK:
		failure = "Could not finish recording frame: " + error_string(error)
		return
	bytes_written += buffer.size()
	frames.append({"file": filename, "seconds": elapsed()})

func finish() -> Dictionary:
	var duration := minf(elapsed(), MAX_SECONDS)
	var metadata := {"duration_seconds": duration, "captured_frames": frames.size(),
		"width": size.x, "height": size.y, "target_fps": FPS, "audio": false,
		"capture_error": failure, "frames": frames.duplicate(true)}
	if not frames.is_empty():
		var error := _write_avi(duration)
		metadata["avi_error"] = error_string(error)
		if error == OK:
			metadata["file"] = "recording.avi"
	return metadata

func _fourcc(file: FileAccess, text: String) -> void:
	file.store_buffer(text.to_ascii_buffer())

func _words(file: FileAccess, words: Array) -> void:
	for word in words:
		file.store_32(int(word))

func _write_avi(duration: float) -> Error:
	# Standard RIFF AVI with one MJPEG stream; no external encoder or install.
	var file := FileAccess.open(directory.path_join("recording.avi"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var count := maxi(1, ceili(duration * FPS))
	_fourcc(file, "RIFF")
	file.store_32(0)
	_fourcc(file, "AVI LIST")
	file.store_32(192)
	_fourcc(file, "hdrlavih")
	file.store_32(56)
	_words(file, [1000000 / FPS, size.x * size.y * 3 * FPS, 0, 16, count, 0, 1,
		size.x * size.y * 3, size.x, size.y, 0, 0, 0, 0])
	_fourcc(file, "LIST")
	file.store_32(116)
	_fourcc(file, "strlstrh")
	file.store_32(56)
	_fourcc(file, "vidsMJPG")
	_words(file, [0, 0, 0, 1, FPS, 0, count, size.x * size.y * 3, 0xFFFFFFFF, 0])
	for word in [0, 0, size.x, size.y]:
		file.store_16(word)
	_fourcc(file, "strf")
	file.store_32(40)
	_words(file, [40, size.x, size.y])
	file.store_16(1)
	file.store_16(24)
	_fourcc(file, "MJPG")
	_words(file, [size.x * size.y * 3, 0, 0, 0, 0])
	_fourcc(file, "LIST")
	var movi_size_position := file.get_position()
	file.store_32(0)
	var movi_start := file.get_position()
	_fourcc(file, "movi")
	var index: Array[Vector2i] = []
	var source := 0
	for frame in count:
		# Duplicate the previous frame across capture stalls to preserve elapsed time.
		while source + 1 < frames.size() and frames[source + 1].seconds <= float(frame) / FPS:
			source += 1
		var buffer := FileAccess.get_file_as_bytes(directory.path_join(frames[source].file))
		if buffer.is_empty():
			file.close()
			return ERR_FILE_CORRUPT
		index.append(Vector2i(file.get_position() - movi_start, buffer.size()))
		_fourcc(file, "00dc")
		file.store_32(buffer.size())
		file.store_buffer(buffer)
		if buffer.size() % 2:
			file.store_8(0)
	var movi_end := file.get_position()
	_fourcc(file, "idx1")
	file.store_32(index.size() * 16)
	for entry in index:
		_fourcc(file, "00dc")
		_words(file, [16, entry.x, entry.y])
	var end := file.get_position()
	var error := file.get_error()
	file.seek(movi_size_position)
	file.store_32(movi_end - movi_start)
	file.seek(4)
	file.store_32(end - 8)
	if file.get_error() != OK:
		error = file.get_error()
	file.close()
	return error
