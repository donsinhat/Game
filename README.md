# Rogue Survivor Prototype

A lightweight survivor-like prototype inspired by the Vampire Survivors loop.
Move, auto-attack, collect gems, and pick upgrades every level.

## How to Run

Open `index.html` in a modern browser. If your browser blocks local scripts,
use a simple static server:

```
python -m http.server 8000
```

Then browse to `http://localhost:8000`.

## Controls

- Move: **WASD** or **Arrow keys**
- Pause: **P**
- Restart: **R**
- Choose upgrade: **1-3**

## Features Added

- Auto-aiming projectiles with scalable fire rate and multi-shot
- Enemy scaling (health + speed) over time
- XP gems and upgrade choices on level up
- HP + XP HUD, time survived, kill counter
- Pause and game-over overlay with restart
