extends Node
## Original, fully procedural waltz for Oddford. No external audio file, soundtrack
## licensing, network service or runtime AI. Streams 22.05 kHz stereo in-game.
## Playback is optional and volume is saved on the device.

const SAMPLE_RATE := 22050.0
const BPM := 104.0
const BEAT := 60.0 / BPM
const LOOP_BEATS := 48
const SETTING_PATH := "user://ministry_sound.cfg"
const CHORDS := [
	[60, 64, 67], [65, 69, 72], [57, 60, 64], [67, 71, 74],
	[60, 64, 67], [69, 72, 76], [62, 65, 69], [67, 71, 74],
	[60, 64, 67], [65, 69, 72], [57, 60, 64], [67, 71, 74],
	[65, 69, 72], [60, 64, 67], [67, 71, 74], [60, 64, 67]
]
# Entirely original 16-bar, six-eighth-notes-per-bar music-box theme.
const MELODY := [
	[76, 79, 81, 79, 76, 72], [77, 81, 84, 81, 79, 77],
	[76, 72, 69, 72, 76, 79], [74, 79, 83, 79, 77, 74],
	[76, 79, 84, 83, 79, 76], [81, 84, 88, 84, 81, 76],
	[77, 81, 86, 81, 77, 74], [79, 83, 86, 83, 79, 74],
	[72, 76, 79, 84, 79, 76], [77, 81, 84, 89, 84, 81],
	[76, 79, 84, 81, 76, 72], [74, 79, 83, 86, 83, 79],
	[77, 81, 84, 81, 77, 72], [76, 79, 84, 79, 76, 72],
	[74, 79, 83, 86, 83, 74], [72, 76, 79, 84, 79, 72]
]

var music_enabled: bool = true
var music_volume: float = 0.42
var player: AudioStreamPlayer
var stamp_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var generated_frames: int = 0
var _is_ready: bool = false

func _ready() -> void:
	_load_settings()
	player = AudioStreamPlayer.new()
	player.name = "OriginalOddfordWaltz"
	player.bus = "Master"
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.45
	player.stream = generator
	add_child(player)
	stamp_player = AudioStreamPlayer.new()
	stamp_player.name = "RubberStampFoley"
	stamp_player.stream = _stamp_sample()
	stamp_player.volume_db = -11.0
	add_child(stamp_player)
	_update_volume()
	_is_ready = true
	if music_enabled:
		_start()

func _start() -> void:
	if not _is_ready or not music_enabled:
		return
	if not player.playing:
		player.play()
		playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	if not music_enabled:
		return
	if not player.playing or playback == null:
		_start()
	if playback == null:
		return
	# A bounded amount of synthesis per frame; no unbounded sample queue.
	var count: int = mini(playback.get_frames_available(), 12000)
	for i in range(count):
		var t: float = fposmod(float(generated_frames) / SAMPLE_RATE, BEAT * LOOP_BEATS)
		var sample: float = _music_sample(t)
		playback.push_frame(Vector2(sample * 0.94, sample))
		generated_frames += 1

func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)

func _music_sample(t: float) -> float:
	var absolute_beat: float = t / BEAT
	var beat_index: int = floori(absolute_beat)
	var bar_index: int = (beat_index / 3) % CHORDS.size()
	var beat_phase: float = fposmod(t, BEAT)
	var eighth: float = BEAT / 2.0
	var step: int = mini(5, int(floor(fposmod(t, BEAT * 3.0) / eighth)))
	var note_time: float = fposmod(t, eighth)
	var root: int = int(CHORDS[bar_index][0]) - 24
	var melody_note: int = int(MELODY[bar_index][step])
	# Soft, round accordion pad under the melody.
	var chord := 0.0
	for note in CHORDS[bar_index]:
		var freq: float = _hz(int(note) - 12)
		chord += sin(TAU * freq * t) * 0.035
		chord += sin(TAU * freq * 1.004 * t) * 0.012
	var pluck: float = (sin(TAU * _hz(melody_note) * note_time) * 0.15 + sin(TAU * _hz(melody_note) * 2.01 * note_time) * 0.038)
	pluck *= minf(1.0, note_time * 90.0) * exp(-note_time * 7.0)
	# Waltz: oom-pah-pah, with a very small music-box tick on each beat.
	var bass := 0.0
	if beat_index % 3 == 0:
		bass = sin(TAU * _hz(root) * beat_phase) * exp(-beat_phase * 7.0) * minf(1.0, beat_phase * 70.0) * 0.23
	else:
		for note in CHORDS[bar_index]:
			bass += sin(TAU * _hz(int(note)) * beat_phase) * exp(-beat_phase * 15.0) * 0.04
	var tick: float = sin(TAU * 1200.0 * beat_phase) * exp(-beat_phase * 95.0) * 0.015
	# Small silent seams at loop boundaries prevent clicks on Steam Deck.
	var loop_seconds: float = BEAT * LOOP_BEATS
	var seam: float = clampf(minf(t, loop_seconds - t) / 0.09, 0.0, 1.0)
	return clampf((chord + pluck + bass + tick) * seam, -0.8, 0.8)

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not _is_ready:
		return
	if music_enabled:
		_start()
	else:
		player.stop()
		playback = null
	_save_settings()

func set_music_volume(level: float) -> void:
	music_volume = clampf(level, 0.0, 1.0)
	if not _is_ready:
		return
	_update_volume()
	_save_settings()

func _update_volume() -> void:
	if player != null:
		player.volume_db = linear_to_db(maxf(0.0001, music_volume))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("sound", "music_enabled", music_enabled)
	config.set_value("sound", "volume", music_volume)
	config.save(SETTING_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTING_PATH) == OK:
		music_enabled = bool(config.get_value("sound", "music_enabled", true))
		music_volume = clampf(float(config.get_value("sound", "volume", 0.42)), 0.0, 1.0)

func _stamp_sample() -> AudioStreamWAV:
	# An original dry rubber-and-brass impact, synthesized locally at startup.
	var count: int = 4600
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var knock: float = sin(TAU * (125.0 - t * 160.0) * t) * exp(-t * 29.0)
		var brass: float = sin(TAU * 820.0 * t) * exp(-t * 23.0)
		var ink: float = sin(TAU * 1800.0 * t) * exp(-t * 105.0)
		var sample: int = clampi(roundi((knock * 0.69 + brass * 0.21 + ink * 0.12) * 22000.0), -32768, 32767)
		bytes[i * 2] = sample & 255
		bytes[i * 2 + 1] = (sample >> 8) & 255
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = int(SAMPLE_RATE)
	result.stereo = false
	result.data = bytes
	return result

func play_stamp_effect() -> void:
	if stamp_player != null:
		stamp_player.stop()
		stamp_player.play()
