extends Node
## Global game state: tuning constants, round table, score and the
## "Honourable Roll Call" high-score table.

# ---------------------------------------------------------------- tuning ---
## Scope diameter as a fraction of the visible screen width (spec: ~1/25).
const SCOPE_DIAMETER_FRACTION := 1.0 / 25.0
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
const BUNNY_SHOT_INTERVAL := Vector2(10.0, 20.0)

enum Training { LOW, MEDIUM, HIGH }
enum Weather { CLEAR, STORM }

## Probability that a bunny sniper MISSES the frog for each training level.
const MISS_CHANCE := {
	Training.LOW: 0.75,
	Training.MEDIUM: 0.5,
	Training.HIGH: 0.25,
}

## The campaign, exactly as briefed.
const ROUNDS := [
	{"snipers": 1, "weather": Weather.CLEAR, "training": Training.LOW},
	{"snipers": 2, "weather": Weather.CLEAR, "training": Training.LOW},
	{"snipers": 3, "weather": Weather.CLEAR, "training": Training.LOW},
	{"snipers": 1, "weather": Weather.CLEAR, "training": Training.MEDIUM},
	{"snipers": 2, "weather": Weather.CLEAR, "training": Training.MEDIUM},
	{"snipers": 3, "weather": Weather.STORM, "training": Training.LOW},
	{"snipers": 1, "weather": Weather.STORM, "training": Training.HIGH},
	{"snipers": 2, "weather": Weather.CLEAR, "training": Training.HIGH},
	{"snipers": 3, "weather": Weather.STORM, "training": Training.HIGH},
]

const HIGHSCORE_PATH := "user://honourable_roll_call.cfg"
const MAX_HIGHSCORES := 10
const DEFAULT_HIGHSCORES := [
	["Agent Ribbit", 240000],
	["Lily Pad Lou", 205000],
	["Bullfrog Bill", 180000],
	["Croaky McCroak", 150000],
	["Tadpole Tess", 120000],
	["Hopkins 007", 95000],
	["Swampy Sue", 70000],
	["Leapy Leo", 50000],
	["Toady Ted", 30000],
	["Puddle Pete", 10000],
]

# ----------------------------------------------------------------- state ---
var round_index := 0              # 0-based index into ROUNDS
var score := 0                    # running total for the campaign
var round_start_score := 0

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
	last_round = {}
	game_over_reason = ""


func current_round() -> Dictionary:
	return ROUNDS[clampi(round_index, 0, ROUNDS.size() - 1)]


func is_last_round() -> bool:
	return round_index >= ROUNDS.size() - 1


## Civilian penalties can push the running score below zero.
func add_score(amount: int) -> void:
	score += amount


func training_name(t: int) -> String:
	match t:
		Training.LOW: return "low"
		Training.MEDIUM: return "medium"
		_: return "high"


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
