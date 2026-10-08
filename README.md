# Sniper Frogs (2027)

**Version 0.11 (beta)**

A Godot 4.7 remake of the 2006 Badger-soft arcade sniper game. It runs on PC and mobile in 2D.

> The year is 2027, and the Bunnies are back. Bunny McWhurter has come out of hiding, and his snipers are after the world's last good leaders. As a Sniper Frog, your job is to take out the Bunny snipers before they get the President.

## Running

1. Open the folder in **Godot 4.7** (Project Manager → Import → `project.godot`).
2. Press **F5**.

The game ships with **no asset files**. All graphics are drawn at runtime with `CanvasItem._draw()`, and every sound (the Kar98k shot and bolt cycle, the muffled bunny rifles, thunder, rain, the explosion, glass, UI blips) is synthesised into `AudioStreamWAV` when the game starts. The project stays tiny and builds the same way on every export target.

### Exporting

- **Windows / macOS / Linux**: Project → Export, add a desktop preset, and export.
- **Android / iOS**: add the mobile preset. The project already uses the *GL Compatibility* renderer and sensor-landscape orientation, and touch controls switch on automatically.
- **Web**: works with the Web preset (the Quit button is hidden there).

## Controls

| | PC | Mobile |
|---|---|---|
| Aim | Move the mouse (the scope is your cursor) | Drag anywhere. The scope follows your finger's motion like a trackpad, so your finger never covers the target |
| Fire | Left click / Space | **FIRE** button (bottom right) |
| Scroll | Push the scope to the screen edge, use A/D or ←/→, or the mouse wheel | Steer the scope to the screen edge |
| Pause | Esc / P / the pause button | The pause button (top right) |
| Skip briefing | Click / Space at any point (N aborts at the prompt) | Tap |

## How it plays

- The street is about 3 screens wide and scrolls left and right only. It has 15 high-rises (5 small with 2 windows per floor, 5 medium with 4, 5 large with 6), each 4–10 floors high with a ground floor, door and an optional shop sign.
- Bunny snipers hide behind ordinary-looking windows. **They only show up through the scope.** The scope is a `SubViewport` that shares the game's `World2D` and renders an extra visibility layer that the main view culls.
- Each level lasts 90 s and gives you 15 bullets. You start the campaign on 100% health and it **carries over between levels**. After every 3rd level a field medic restores 25% of your current health (rounded down, capped at 100%). A bunny kill is worth **10,000** points. Hitting a civilian costs **1,000–5,000** points.
- Bunnies fire every 10–20 s. You'll see a muzzle flash at their window and hear a muffled, positional shot, and an orange glow marks the screen edge when the shooter is off-screen. Their chance of missing depends on training: low 3/4, medium 2/4, expert 1/4. Each hit costs about 25% health.
- In storms, a bunny may time its shot with the lightning, which hides the flash and drowns out the report.
- Each briefing opens with a coded "...Level x clearance granted." message that decrypts on screen.
- Clear every sniper to win the level. Each second left on the clock then adds **500** points, counted up on the results screen.
- If the clock runs out, the presidential limousine arrives and stops mid-screen, and then it's game over.

| Level | Snipers | Weather | Training |
|---|---|---|---|
| 1 | 1 | Clear | Low |
| 2 | 2 | Clear | Low |
| 3 | 3 | Clear | Low |
| 4 | 4 | Clear | Low |
| 5 | 1 | Clear | Medium |
| 6 | 2 | Clear | Medium |
| 7 | 3 | Storm | Medium |
| 8 | 4 | Storm | Medium |
| 9 | 1 | Clear | Expert |
| 10 | 2 | Storm | Expert |
| 11 | 3 | Clear | Expert |
| 12 | 4 | Storm | Expert |
| 13 (final) | 6 | Storm | Expert, rapid fire (every 6–11 s) |

## Tuning

All the gameplay numbers live at the top of `scripts/autoload/game_state.gd`:

- `SCOPE_DIAMETER_FRACTION`: scope diameter as a fraction of screen width (default `1.5/25`)
- `SCOPE_TOUCH_MULTIPLIER`: makes the scope bigger on touch screens
- `SCOPE_MAGNIFICATION`: zoom through the scope
- Round time, bullets, damage, points, miss chances, shot interval, and the `ROUNDS` table

World geometry (building, window and street sizes, world width) is in `scripts/game/layout.gd`.

## Project layout

```
scenes/main.tscn            entry scene (screen manager)
scripts/main.gd             screen switching + fades
scripts/autoload/           GameState (rules, score, roll call), Sfx (synth audio)
scripts/ui/ui_kit.gd        theme, fonts, widget helpers, frog logo
scripts/screens/            menu, spy-room backdrop, instructions, terminal briefing,
                            round results, game over / victory
scripts/game/               game controller, buildings, bunny, pedestrians, cars/limo,
                            backdrop layers, street, FX, weather, scope, HUD, overlay
shaders/                    scope lens mask, CRT terminal overlay
```

High scores (the "Honourable Roll Call", top 5) are saved to `user://honourable_roll_call.cfg`.

The version string lives in `GameState.VERSION` (and `application/config/version` in `project.godot`).
