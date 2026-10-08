extends Node
## Global game state: tuning constants, round table, score and the
## "Honourable Roll Call" high-score table.

const VERSION := "0.11 (beta)"

# ---------------------------------------------------------------- tuning ---
## Scope diameter as a fraction of the visible screen width (1/25 + 50%).
const SCOPE_DIAMETER_FRACTION := 1.5 / 25.0
## Extra scope size multiplier used on touch screens (fingers are fat).
const SCOPE_TOUCH_MULTIPLIER := 1.6
## How much the scope magnifies the world behind it.
const SCOPE_MAGNIFICATION := 1.8

const ROUND_TIME := 90.0
const BULLETS_PER_ROUND := 15
const START_HEALTH := 100
const HIT_DAMAGE := [20, 25, 25, 30]          # "around 25%" per hit
const POINTS_PER_BUNNY := 10000
const CIVILIAN_PENALTY_MIN := 1000
const CIVILIAN_PENALTY_MAX := 5000
const TIME_BONUS_PER_SECOND := 500
## Base gap (seconds) between a bunny's shots, before the scaling below.
const BUNNY_SHOT_INTERVAL := Vector2(10.0, 20.0)
## Global tightening of that gap (20% shorter).
const SHOT_INTERVAL_SCALE := 0.8
## Health carries over between levels; after every level won a field medic
## adds a random 0..HEALTH_BOOST_MAX points (never above START_HEALTH).
const HEALTH_BOOST_MAX := 25

enum Training { LOW, MEDIUM, EXPERT }
enum Weather { CLEAR, STORM, SNOW }

## Probability that a bunny sniper MISSES the frog for each training level.
const MISS_CHANCE := {
	Training.LOW: 0.75,
	Training.MEDIUM: 0.5,
	Training.EXPERT: 0.25,
}

## Each training grade above LOW shortens the gap between shots by a further
## 15% (medium 15% shorter, expert 30% shorter).
const TRAINING_SHOT_SCALE := {
	Training.LOW: 1.0,
	Training.MEDIUM: 0.85,
	Training.EXPERT: 0.70,
}

## Briefing phrases so each level's forecast reads differently.
const WEATHER_PHRASES := {
	Weather.CLEAR: [
		"good. Clear skies.",
		"good. Blue skies and a light breeze.",
		"fine. Visibility excellent across the rooftops.",
		"bright. Watch for glare off the glass.",
		"fair. Warm and still - perfect shooting weather.",
		"good. A few fluffy clouds, nothing to worry about.",
	],
	Weather.STORM: [
		"bad. Storms and lightning.",
		"foul. Heavy rain with thunder rolling in.",
		"grim. Lightning over the skyline - they'll use the thunder.",
		"rough. Driving rain and gusting wind.",
		"poor. Low cloud and sheets of rain.",
	],
	Weather.SNOW: [
		"freezing. Snow is falling.",
		"bitter. Heavy snow is muffling every sound.",
		"icy. Snow flurries - visibility will come and go.",
		"arctic. The city is blanketed in snow.",
		"cold. Snow squalls blowing through the streets.",
	],
}
## The campaign: one entry per level. "shot_rate" (optional) scales the gap
## between shots further for that level.
const ROUNDS := [
	{"snipers": 1, "weather": Weather.CLEAR, "training": Training.LOW},       # 1
	# TEMP: level 2 is snowy for testing - set back to Weather.CLEAR.
	{"snipers": 2, "weather": Weather.SNOW, "training": Training.LOW},        # 2
	{"snipers": 3, "weather": Weather.CLEAR, "training": Training.LOW},       # 3
	{"snipers": 4, "weather": Weather.CLEAR, "training": Training.LOW},       # 4
	{"snipers": 1, "weather": Weather.CLEAR, "training": Training.MEDIUM},    # 5
	{"snipers": 2, "weather": Weather.CLEAR, "training": Training.MEDIUM},    # 6
	{"snipers": 3, "weather": Weather.STORM, "training": Training.MEDIUM},    # 7
	{"snipers": 4, "weather": Weather.SNOW, "training": Training.MEDIUM},     # 8
	{"snipers": 1, "weather": Weather.CLEAR, "training": Training.EXPERT},    # 9
	{"snipers": 2, "weather": Weather.STORM, "training": Training.EXPERT},    # 10
	{"snipers": 3, "weather": Weather.CLEAR, "training": Training.EXPERT},    # 11
	{"snipers": 4, "weather": Weather.SNOW, "training": Training.EXPERT},     # 12
	# Final level: McWhurter's elite, firing far more often.
	{"snipers": 6, "weather": Weather.STORM, "training": Training.EXPERT,
		"shot_rate": 0.75},                                                   # 13
]

const HIGHSCORE_PATH := "user://honourable_roll_call.cfg"
const MAX_HIGHSCORES := 5
const DEFAULT_HIGHSCORES := [
	["Agent Ribbit", 240000],
	["Lily Pad Lou", 205000],
	["Bullfrog Bill", 180000],
	["Croaky McCroak", 150000],
	["Tadpole Tess", 120000],
]

# ----------------------------------------------------------------- state ---
var round_index := 0              # 0-based index into ROUNDS
var score := 0                    # running total for the campaign
var round_start_score := 0
var health := START_HEALTH        # carried from level to level

## Result of the most recently played round, filled in by the game screen.
var last_round := {}
## Why the game ended: "limo", "frog", or "victory".
var game_over_reason := ""

var highscores: Array = []


func _ready() -> void:
	randomize()
	load_highscores()


func new_game() -> void:
	round_index = 0
	score = 0
	round_start_score = 0
	health = START_HEALTH
	last_round = {}
	game_over_reason = ""


func current_round() -> Dictionary:
	return ROUNDS[clampi(round_index, 0, ROUNDS.size() - 1)]


func is_last_round() -> bool:
	return round_index >= ROUNDS.size() - 1


## Min/max seconds between one bunny's shots on the current level.
func shot_interval() -> Vector2:
	var cfg := current_round()
	return BUNNY_SHOT_INTERVAL * SHOT_INTERVAL_SCALE * float(TRAINING_SHOT_SCALE[cfg.training]) \
		* float(cfg.get("shot_rate", 1.0))


func weather_phrase(w: int) -> String:
	var pool: Array = WEATHER_PHRASES[w]
	return pool[randi() % pool.size()]


func weather_name(w: int) -> String:
	match w:
		Weather.STORM: return "STORMY"
		Weather.SNOW: return "SNOWY"
		_: return "SUNNY"


func weather_short(w: int) -> String:
	match w:
		Weather.STORM: return "STORM"
		Weather.SNOW: return "SNOW"
		_: return "CLEAR"


## Call once when the current level is won: the field medic patches the
## frog up by a random 0..HEALTH_BOOST_MAX points, capped at START_HEALTH.
## Returns the amount actually added.
func apply_health_boost() -> int:
	if is_last_round():
		return 0
	var boost := mini(randi_range(0, HEALTH_BOOST_MAX), START_HEALTH - health)
	health += boost
	return boost


## Civilian penalties can push the running score below zero.
func add_score(amount: int) -> void:
	score += amount


func training_name(t: int) -> String:
	match t:
		Training.LOW: return "low"
		Training.MEDIUM: return "medium"
		_: return "expert"


func training_adverb(t: int) -> String:
	match t:
		Training.LOW: return "poorly"
		Training.MEDIUM: return "moderately"
		_: return "highly"


func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available()


# ------------------------------------------------------------ highscores ---
func load_highscores() -> void:
	highscores.clear()
	var cfg := ConfigFile.new()
	if cfg.load(HIGHSCORE_PATH) == OK:
		var data = cfg.get_value("roll_call", "entries", [])
		if data is Array:
			for e in data:
				if e is Array and e.size() == 2:
					highscores.append([str(e[0]), int(e[1])])
	if highscores.is_empty():
		for e in DEFAULT_HIGHSCORES:
			highscores.append([e[0], e[1]])
	_sort_scores()
	highscores.resize(mini(highscores.size(), MAX_HIGHSCORES))


func save_highscores() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("roll_call", "entries", highscores)
	cfg.save(HIGHSCORE_PATH)


func qualifies_for_roll_call(value: int) -> bool:
	if value <= 0:
		return false
	if highscores.size() < MAX_HIGHSCORES:
		return true
	return value > int(highscores[-1][1])


## Inserts a score and returns its rank (0-based), or -1 if it didn't place.
func submit_highscore(player_name: String, value: int) -> int:
	if not qualifies_for_roll_call(value):
		return -1
	player_name = player_name.strip_edges().substr(0, 16)
	if player_name.is_empty():
		player_name = "Agent Frog"
	var entry := [player_name, value]
	highscores.append(entry)
	_sort_scores()
	while highscores.size() > MAX_HIGHSCORES:
		highscores.pop_back()
	save_highscores()
	return highscores.find(entry)


func _sort_scores() -> void:
	highscores.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
