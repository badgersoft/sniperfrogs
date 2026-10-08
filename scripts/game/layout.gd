extends RefCounted
## World geometry shared by every game-world script. The design resolution is
## 1280x720; the play area is ~3 screens wide and scrolls horizontally only.

const VIEW_H := 720.0
const HUD_H := 72.0                 # bottom 10% status board
const PLAY_H := VIEW_H - HUD_H      # 648
const WORLD_W := 3840.0             # ~3 screens

const BASE_Y := 528.0               # where buildings meet the pavement
const SIDEWALK_TOP := BASE_Y
const SIDEWALK_BOTTOM := 574.0
const ROAD_TOP := SIDEWALK_BOTTOM
const ROAD_BOTTOM := PLAY_H
const LANE_FAR_Y := 598.0           # wheels touching y for cars heading right
const LANE_NEAR_Y := 634.0          # wheels touching y for cars heading left

const GROUND_H := 60.0
const FLOOR_H := 44.0
const WIN_W := 28.0
const WIN_H := 32.0
const WIN_GAP := 14.0
const SIDE_MARGIN := 16.0
const ROOF_H := 10.0

## Visibility layer bits: the main view renders LAYER_WORLD only; the scope's
## SubViewport renders both, which is how hidden snipers appear only in the
## scope.
const LAYER_WORLD := 1
const LAYER_SCOPE_ONLY := 2

## Parallax factors (0 = glued to the screen, 1 = moves with the world).
const PARALLAX_CLOUDS := 0.08
const PARALLAX_SKYLINE := 0.3
const PARALLAX_TREES := 0.65
