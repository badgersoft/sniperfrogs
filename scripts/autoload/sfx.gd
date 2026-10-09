extends Node
## Procedural sound effects. Every sound in the game is synthesised at start-up
## into an AudioStreamWAV, so the project ships with zero audio assets and the
## sounds are identical on every platform.

const RATE := 22050
const POOL_SIZE := 14
## Gunshots play through their own bus so snow can muffle just them.
const GUNSHOT_BUS := "Gunshots"
const GUNSHOTS := ["rifle", "bunny_shot"]

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _rain_player: AudioStreamPlayer
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _next_2d := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 2006
	_make_world_bus()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_rain_player = AudioStreamPlayer.new()
	add_child(_rain_player)
	for i in 6:
		var p2 := AudioStreamPlayer2D.new()
		p2.max_distance = 5000.0
		p2.attenuation = 0.6
		p2.panning_strength = 1.6
		add_child(p2)
		_pool_2d.append(p2)
	_build_all()


## Plays a named sound. Returns the player so callers may tweak / stop it.
func play(sound: String, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	if not _streams.has(sound):
		return null
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[sound]
	p.bus = _bus_for(sound)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()
	return p


## Positional variant: pans/attenuates relative to the current Camera2D, so
## an off-screen sniper is heard from the correct side.
func play_at(sound: String, world_pos: Vector2, volume_db := 0.0, pitch := 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _pool_2d[_next_2d]
	_next_2d = (_next_2d + 1) % _pool_2d.size()
	p.global_position = world_pos
	p.stream = _streams[sound]
	p.bus = _bus_for(sound)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func _bus_for(sound: String) -> StringName:
	return GUNSHOT_BUS if sound in GUNSHOTS else &"Master"


func play_varied(sound: String, volume_db := 0.0, spread := 0.06) -> AudioStreamPlayer:
	return play(sound, volume_db, 1.0 + _rng.randf_range(-spread, spread))


## Snow deadens sound: a low-pass on the Gunshots bus muffles every shot
## (yours and the bunnies'), leaving everything else untouched.
func set_muffled(on: bool) -> void:
	var bus := AudioServer.get_bus_index(GUNSHOT_BUS)
	if bus < 0:
		return
	AudioServer.set_bus_effect_enabled(bus, 0, on)
	AudioServer.set_bus_volume_db(bus, -3.0 if on else 0.0)


func start_wind(volume_db := -10.0) -> void:
	_rain_player.stream = _streams["wind"]
	_rain_player.volume_db = volume_db
	_rain_player.play()


func _make_world_bus() -> void:
	if AudioServer.get_bus_index(GUNSHOT_BUS) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, GUNSHOT_BUS)
	AudioServer.set_bus_send(idx, "Master")
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 750.0
	lp.resonance = 0.4
	AudioServer.add_bus_effect(idx, lp, 0)
	AudioServer.set_bus_effect_enabled(idx, 0, false)


func start_rain(volume_db := -9.0) -> void:
	_rain_player.stream = _streams["rain"]
	_rain_player.volume_db = volume_db
	if not _rain_player.playing:
		_rain_player.play()


func stop_rain() -> void:
	_rain_player.stop()


func stop_all() -> void:
	for p in _pool:
		p.stop()
	for p in _pool_2d:
		p.stop()
	_rain_player.stop()


# ------------------------------------------------------------- synthesis ---
func _build_all() -> void:
	_streams["rifle"] = _make(_synth_rifle())
	_streams["bunny_shot"] = _make(_synth_bunny_shot())
	_streams["dry_fire"] = _make(_synth_dry_fire())
	_streams["glass"] = _make(_synth_glass())
	_streams["splat"] = _make(_synth_splat())
	_streams["player_hit"] = _make(_synth_player_hit())
	_streams["thunder"] = _make(_synth_thunder())
	_streams["rain"] = _make(_synth_rain(), true)
	_streams["wind"] = _make(_synth_wind(), true)
	_streams["explosion"] = _make(_synth_explosion())
	_streams["type"] = _make(_synth_type())
	_streams["beep"] = _make(_synth_tone(880.0, 0.07, 0.25, true))
	_streams["tick"] = _make(_synth_tone(1560.0, 0.03, 0.22, true))
	_streams["accept"] = _make(_synth_accept())
	_streams["chirp"] = _make(_synth_chirp())
	_streams["fanfare"] = _make(_synth_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.13, 0.5))
	_streams["lose"] = _make(_synth_arpeggio([392.0, 349.23, 311.13, 233.08], 0.28, 0.9))
	_streams["engine"] = _make(_synth_engine())
	_streams["scream"] = _make(_synth_scream())
	_streams["whiz"] = _make(_synth_whiz())
	_streams["ping"] = _make(_synth_ping())
	_streams["wood"] = _make(_synth_wood())


func _make(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.95 / peak
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


static func _lp_coeff(fc: float) -> float:
	return 1.0 - exp(-TAU * fc / RATE)


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Short sharp transient used for the crack of a high velocity round.
func _add_crack(buf: PackedFloat32Array, start: float, amp: float, decay: float, hp := true) -> void:
	var i0 := int(start * RATE)
	var lp := 0.0
	var a := _lp_coeff(1800.0)
	var n := int(decay * 8.0 * RATE)
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp += a * (x - lp)
		var v := (x - lp) if hp else lp
		buf[idx] += v * amp * exp(-t / decay)


func _synth_rifle() -> PackedFloat32Array:
	var b := _buf(1.45)
	# Supersonic crack.
	_add_crack(b, 0.0, 1.0, 0.010)
	var lp1 := 0.0
	var lp2 := 0.0
	var a1 := _lp_coeff(900.0)
	var a2 := _lp_coeff(380.0)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp1 += a1 * (x - lp1)
		lp2 += a2 * (x - lp2)
		# Muzzle blast body.
		var body := lp1 * 2.2 * exp(-t / 0.05)
		# Low concussive boom with a falling pitch.
		var f := 50.0 + 110.0 * exp(-t / 0.05)
		phase += TAU * f / RATE
		var boom := sin(phase) * 0.9 * exp(-t / 0.10)
		# Reverberant tail bouncing off buildings.
		var tail := lp2 * 2.6 * exp(-t / 0.38) * clampf(t / 0.03, 0.0, 1.0)
		b[i] += body + boom + tail
	# A discrete slap-back echo off the far buildings.
	_add_crack(b, 0.21, 0.25, 0.03, false)
	# Kar98k bolt cycle: lift, back, forward, down.
	for c in [[0.78, 0.35], [0.88, 0.5], [1.06, 0.55], [1.16, 0.4]]:
		_add_click(b, c[0], c[1], 2400.0 + _rng.randf_range(-300, 300))
	return b


func _add_click(buf: PackedFloat32Array, start: float, amp: float, ring_hz: float) -> void:
	var i0 := int(start * RATE)
	var n := int(0.05 * RATE)
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var noise := _rng.randf_range(-1.0, 1.0) * exp(-t / 0.002)
		var ring := sin(TAU * ring_hz * t) * exp(-t / 0.012) * 0.6
		var ring2 := sin(TAU * ring_hz * 1.53 * t) * exp(-t / 0.007) * 0.3
		buf[idx] += (noise + ring + ring2) * amp


func _synth_bunny_shot() -> PackedFloat32Array:
	# Distant, through glass: no crack, heavily low passed, long dull tail.
	var b := _buf(1.3)
	var lp := 0.0
	var lp_b := 0.0
	var a := _lp_coeff(420.0)
	var ab := _lp_coeff(160.0)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp += a * (x - lp)
		lp_b += ab * (x - lp_b)
		var att := clampf(t / 0.006, 0.0, 1.0)
		phase += TAU * (45.0 + 40.0 * exp(-t / 0.08)) / RATE
		var thump := sin(phase) * 0.7 * exp(-t / 0.13)
		var body := lp * 3.0 * exp(-t / 0.07)
		var tail := lp_b * 4.0 * exp(-t / 0.42)
		b[i] = (thump + body + tail) * att
	# Faint glassy rattle from the window pane.
	for i in int(0.12 * RATE):
		var t := float(i) / RATE
		b[i + int(0.01 * RATE)] += sin(TAU * 1300.0 * t) * 0.04 * exp(-t / 0.03)
	return b


func _synth_dry_fire() -> PackedFloat32Array:
	var b := _buf(0.12)
	_add_click(b, 0.0, 1.0, 3100.0)
	_add_click(b, 0.045, 0.5, 2200.0)
	return b


func _synth_glass() -> PackedFloat32Array:
	var b := _buf(0.9)
	_add_crack(b, 0.0, 0.8, 0.02)
	for k in 46:
		var start := pow(_rng.randf(), 2.0) * 0.6
		var f := _rng.randf_range(2200.0, 6800.0)
		var dec := _rng.randf_range(0.015, 0.07)
		var amp := _rng.randf_range(0.08, 0.3) * (1.0 - start)
		var i0 := int(start * RATE)
		for i in int(dec * 6.0 * RATE):
			var idx := i0 + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			b[idx] += sin(TAU * f * t) * amp * exp(-t / dec)
	return b


func _synth_splat() -> PackedFloat32Array:
	var b := _buf(0.35)
	var lp := 0.0
	var a := _lp_coeff(600.0)
	for i in b.size():
		var t := float(i) / RATE
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		b[i] = lp * 3.0 * exp(-t / 0.06) + sin(TAU * (120.0 - 150.0 * t) * t) * 0.6 * exp(-t / 0.08)
	return b


func _synth_player_hit() -> PackedFloat32Array:
	var b := _buf(1.5)
	var lp := 0.0
	var a := _lp_coeff(500.0)
	for i in b.size():
		var t := float(i) / RATE
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		var thwack := lp * 3.5 * exp(-t / 0.05)
		var thud := sin(TAU * 90.0 * t) * exp(-t / 0.12)
		var ring := sin(TAU * 3100.0 * t) * 0.07 * exp(-t / 0.7) * clampf(t / 0.05, 0.0, 1.0)
		b[i] = thwack + thud + ring
	_add_crack(b, 0.0, 0.6, 0.008)
	return b


func _synth_thunder() -> PackedFloat32Array:
	var b := _buf(4.2)
	var brown := 0.0
	var lp := 0.0
	var a := _lp_coeff(260.0)
	# Random rumble swells.
	var swells := []
	for k in 7:
		swells.append([_rng.randf_range(0.15, 3.2), _rng.randf_range(0.2, 0.9), _rng.randf_range(0.3, 1.0)])
	for i in b.size():
		var t := float(i) / RATE
		brown = clampf(brown + _rng.randf_range(-0.08, 0.08), -1.0, 1.0) * 0.998
		lp += a * (brown - lp)
		var env := 1.1 * exp(-t / 0.25) * clampf(t / 0.01, 0.0, 1.0)
		for s in swells:
			var d: float = (t - s[0]) / s[1]
			env += s[2] * exp(-d * d)
		env *= clampf((4.2 - t) / 0.8, 0.0, 1.0)
		b[i] = lp * env
	# Initial crackle of a close strike.
	_add_crack(b, 0.0, 0.25, 0.05)
	return b


func _synth_rain() -> PackedFloat32Array:
	var length := 2.0
	var b := _buf(length)
	var lp := 0.0
	var lp2 := 0.0
	var a := _lp_coeff(3200.0)
	var a2 := _lp_coeff(500.0)
	for i in b.size():
		var x := _rng.randf_range(-1.0, 1.0)
		lp += a * (x - lp)
		lp2 += a2 * (x - lp2)
		b[i] = (lp - lp2) * 0.6 + lp2 * 0.3
	# Individual droplet ticks.
	for k in 120:
		_add_click(b, _rng.randf_range(0.0, length - 0.06), _rng.randf_range(0.02, 0.08), _rng.randf_range(1800.0, 5000.0))
	# Crossfade the ends so the loop is seamless.
	var fade := int(0.08 * RATE)
	for i in fade:
		var w := float(i) / fade
		var j := b.size() - fade + i
		b[i] = b[i] * w + b[j] * (1.0 - w)
	b.resize(b.size() - fade)
	return b


func _synth_explosion() -> PackedFloat32Array:
	var b := _buf(3.6)
	var brown := 0.0
	var lp := 0.0
	var a := _lp_coeff(500.0)
	for i in b.size():
		var t := float(i) / RATE
		brown = clampf(brown + _rng.randf_range(-0.1, 0.1), -1.0, 1.0) * 0.997
		lp += a * (brown - lp)
		var boom := sin(TAU * (32.0 + 60.0 * exp(-t / 0.2)) * t) * 1.2 * exp(-t / 0.5)
		var roar := lp * 3.0 * exp(-t / 0.9) + _rng.randf_range(-1.0, 1.0) * 0.4 * exp(-t / 0.12)
		b[i] = boom + roar
	_add_crack(b, 0.0, 1.2, 0.02)
	# Burning crackles and falling debris.
	for k in 70:
		var at := _rng.randf_range(0.2, 3.3)
		_add_click(b, at, _rng.randf_range(0.05, 0.25) * (1.0 - at / 3.6), _rng.randf_range(600.0, 3000.0))
	return b


func _synth_type() -> PackedFloat32Array:
	var b := _buf(0.04)
	_add_click(b, 0.0, 1.0, 4200.0)
	return b


func _synth_tone(freq: float, length: float, amp: float, square := false) -> PackedFloat32Array:
	var b := _buf(length)
	for i in b.size():
		var t := float(i) / RATE
		var s := sin(TAU * freq * t)
		if square:
			s = s + sin(TAU * freq * 3.0 * t) / 3.0 + sin(TAU * freq * 5.0 * t) / 5.0
		var env := clampf(t / 0.004, 0.0, 1.0) * clampf((length - t) / 0.02, 0.0, 1.0)
		b[i] = s * amp * env
	return b


func _synth_accept() -> PackedFloat32Array:
	var b := _buf(0.32)
	for i in b.size():
		var t := float(i) / RATE
		var f := 660.0 if t < 0.12 else 990.0
		var env := clampf(t / 0.005, 0.0, 1.0) * exp(-fmod(t, 0.12) / 0.15)
		b[i] = (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env
	return b


func _synth_chirp() -> PackedFloat32Array:
	var b := _buf(0.5)
	for n in 3:
		var start := n * 0.14
		var phase := 0.0
		for i in int(0.09 * RATE):
			var t := float(i) / RATE
			var f := 3200.0 + 2600.0 * sin(PI * t / 0.09)
			phase += TAU * f / RATE
			b[int(start * RATE) + i] += sin(phase) * sin(PI * t / 0.09) * 0.5
	return b


func _synth_arpeggio(freqs: Array, step: float, tail: float) -> PackedFloat32Array:
	var total := step * freqs.size() + tail
	var b := _buf(total)
	for n in freqs.size():
		var f: float = freqs[n]
		var i0 := int(n * step * RATE)
		for i in int((total - n * step) * RATE):
			var idx := i0 + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			var s := sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) + 0.15 * sin(TAU * f * 3.0 * t)
			b[idx] += s * clampf(t / 0.01, 0.0, 1.0) * exp(-t / 0.35) * 0.4
	return b


func _synth_engine() -> PackedFloat32Array:
	var b := _buf(2.5)
	var lp := 0.0
	var a := _lp_coeff(300.0)
	for i in b.size():
		var t := float(i) / RATE
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		var f := 38.0 + 6.0 * sin(t * 3.0)
		var hum := sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.0 * t) * 0.3
		var env := clampf(t / 0.5, 0.0, 1.0) * clampf((2.5 - t) / 0.6, 0.0, 1.0)
		b[i] = (hum + lp * 2.0) * env
	return b


func _synth_scream() -> PackedFloat32Array:
	# A short cartoon "eek!" for unlucky pedestrians.
	var b := _buf(0.45)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 900.0 + 500.0 * sin(t * 9.0) - 600.0 * t
		phase += TAU * f / RATE
		var env := clampf(t / 0.02, 0.0, 1.0) * clampf((0.45 - t) / 0.15, 0.0, 1.0)
		b[i] = (sin(phase) + 0.4 * sin(phase * 2.0) + 0.2 * sin(phase * 3.0)) * env * 0.5
	return b


func _synth_whiz() -> PackedFloat32Array:
	# A near miss zipping past: band of noise sweeping down in pitch.
	var b := _buf(0.32)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var fc := 4200.0 - 3200.0 * (t / 0.32)
		var a := _lp_coeff(fc)
		var a2 := _lp_coeff(fc * 0.5)
		var x := _rng.randf_range(-1.0, 1.0)
		lp += a * (x - lp)
		lp2 += a2 * (x - lp2)
		var env := sin(PI * clampf(t / 0.32, 0.0, 1.0))
		env = env * env * env
		b[i] = (lp - lp2) * env
	return b


func _synth_ping() -> PackedFloat32Array:
	# Ricochet off car metal.
	var b := _buf(0.6)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 2600.0 - 1400.0 * minf(t / 0.5, 1.0)
		phase += TAU * f / RATE
		b[i] = sin(phase) * exp(-t / 0.18) * 0.5
	_add_crack(b, 0.0, 0.7, 0.006)
	return b


func _synth_wind() -> PackedFloat32Array:
	# Cold wind for snow levels: slowly swelling low-passed noise.
	var length := 4.0
	var b := _buf(length)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		var fc := 500.0 + 350.0 * sin(TAU * t / length) + 150.0 * sin(TAU * 3.0 * t / length)
		lp += _lp_coeff(fc) * (x - lp)
		lp2 += _lp_coeff(120.0) * (x - lp2)
		var swell := 0.6 + 0.4 * sin(TAU * 2.0 * t / length + 1.0)
		b[i] = (lp - lp2 * 0.5) * swell
	# Crossfade the ends so the loop is seamless.
	var fade := int(0.2 * RATE)
	for i in fade:
		var w := float(i) / fade
		var j := b.size() - fade + i
		b[i] = b[i] * w + b[j] * (1.0 - w)
	b.resize(b.size() - fade)
	return b


func _synth_wood() -> PackedFloat32Array:
	# Hollow plywood "thock" with a splintering crackle.
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		var knock := sin(TAU * 210.0 * t) * exp(-t / 0.05) + 0.6 * sin(TAU * 470.0 * t) * exp(-t / 0.03)
		b[i] = knock * 0.9
	_add_crack(b, 0.0, 0.5, 0.012)
	for k in 14:
		_add_click(b, _rng.randf_range(0.01, 0.25), _rng.randf_range(0.05, 0.2), _rng.randf_range(900.0, 2200.0))
	return b
