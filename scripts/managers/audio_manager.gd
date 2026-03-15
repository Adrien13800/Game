extends Node
## Gestionnaire audio - génère et joue des SFX synthétisés.

const SAMPLE_RATE := 22050

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer

var _snd_shoot: AudioStreamWAV
var _snd_hit: AudioStreamWAV
var _snd_enemy_death: AudioStreamWAV
var _snd_hurt: AudioStreamWAV
var _snd_xp: AudioStreamWAV
var _snd_level_up: AudioStreamWAV
var _snd_game_over: AudioStreamWAV


func _ready() -> void:
	# Pool de players SFX
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

	# Player musique
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -12.0
	add_child(_music_player)

	# Générer les sons
	_snd_shoot = _tone(700, 0.06, 0.25)
	_snd_hit = _tone(250, 0.08, 0.3)
	_snd_enemy_death = _noise(0.12, 0.25)
	_snd_hurt = _noise(0.15, 0.4)
	_snd_xp = _tone(1200, 0.05, 0.2)
	_snd_level_up = _arpeggio([523, 659, 784], 0.08, 0.35)
	_snd_game_over = _arpeggio([392, 330, 262, 196], 0.18, 0.4)

	# Lancer la musique ambient
	_music_player.stream = _generate_chill_music()
	_music_player.play()


# --- API publique ---

func play_shoot() -> void:
	_play(_snd_shoot, -6.0)

func play_hit() -> void:
	_play(_snd_hit, -4.0)

func play_enemy_death() -> void:
	_play(_snd_enemy_death, -3.0)

func play_hurt() -> void:
	_play(_snd_hurt, 0.0)

func play_xp() -> void:
	_play(_snd_xp, -8.0)

func play_level_up() -> void:
	_play(_snd_level_up, 2.0)

func play_game_over() -> void:
	_play(_snd_game_over, 2.0)


# --- Lecture ---

func _play(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return


# --- Génération de sons ---

func _tone(freq: float, duration: float, volume: float = 0.4) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in num_samples:
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0 - float(i) / num_samples
		var value := sin(TAU * freq * t) * volume * envelope
		data[i] = int((value + 1.0) * 0.5 * 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _noise(duration: float, volume: float = 0.3) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in num_samples:
		var envelope := 1.0 - float(i) / num_samples
		var value := (randf() * 2.0 - 1.0) * volume * envelope
		data[i] = int((value + 1.0) * 0.5 * 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _arpeggio(freqs: Array, note_dur: float, volume: float = 0.35) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * note_dur)
	var total := samples_per_note * freqs.size()
	var data := PackedByteArray()
	data.resize(total)
	for n in freqs.size():
		for i in samples_per_note:
			var idx := n * samples_per_note + i
			if idx >= total:
				break
			var t := float(i) / SAMPLE_RATE
			var envelope := 1.0 - float(i) / samples_per_note * 0.6
			var value := sin(TAU * freqs[n] * t) * volume * envelope
			data[idx] = int((value + 1.0) * 0.5 * 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _generate_chill_music() -> AudioStreamWAV:
	var duration := 8.0
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	# Mélodie pentatonique douce (temps en secondes, fréquence)
	var melody := [
		[0.0, 523.25],  # C5
		[1.0, 440.0],   # A4
		[2.0, 392.0],   # G4
		[3.0, 329.63],  # E4
		[4.0, 440.0],   # A4
		[5.0, 523.25],  # C5
		[6.0, 392.0],   # G4
		[7.0, 329.63],  # E4
	]

	for i in num_samples:
		var t := float(i) / SAMPLE_RATE
		var value := 0.0

		# Pad d'accords Cmaj7 avec léger chorus
		value += sin(TAU * 130.81 * t) * 0.035
		value += sin(TAU * 164.81 * t + sin(t * 0.2) * 0.4) * 0.025
		value += sin(TAU * 196.0 * t + sin(t * 0.15) * 0.4) * 0.02
		value += sin(TAU * 246.94 * t + sin(t * 0.25) * 0.4) * 0.012

		# Respiration douce du pad
		var swell := 0.75 + 0.25 * sin(t * 0.4)
		value *= swell

		# Notes de mélodie
		var beat := fmod(t, 8.0)
		for note in melody:
			var note_start: float = note[0]
			var note_freq: float = note[1]
			var note_t := beat - note_start
			if note_t >= 0.0 and note_t < 0.85:
				var fade_in := minf(1.0, note_t / 0.03)
				var fade_out := maxf(0.0, 1.0 - note_t / 0.85)
				var env := fade_in * fade_out
				value += sin(TAU * note_freq * t) * 0.018 * env

		data[i] = clampi(int((value + 1.0) * 0.5 * 255), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	stream.data = data
	return stream
