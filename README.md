# Henry's Boats

A Godot 4.7 2D mobile prototype for a turn-based boat combat game on a water grid.

## Current gameplay

- Tap one of your blue boats to select it.
- Tap an empty water square to move within that unit's movement range.
- Tap a red enemy unit while one of your units is selected to attack.
- Your corner port can build Patrol Boats, Destroyers, and Aircraft Carriers.
- The Aircraft Carrier, or AC, can launch Jet air units when selected.
- End your turn to let the enemy move or attack.
- Income each turn is based on fleet size and total kills, with a bounty when you sink an enemy.

## Requirements

- Godot 4.7.x

## Run locally

Run: godot --path .

Headless smoke check: godot --headless --path . --quit-after 1

## Play in a browser

Pushes to `main` export the Web preset and deploy it to GitHub Pages. The
workflow publishes the generated `site/` directory; it is not committed.

## Unit roles

- Patrol Boat/PT: cheap, fast close-range boat.
- Destroyer/DD: tougher boat with longer attack range.
- Aircraft Carrier/AC: expensive boat that can make Jet air units.
- Jet/AIR: fast air unit launched from an AC.

## Project layout

- project.godot: mobile-oriented project settings.
- scenes/main.tscn: main game scene.
- scripts/main.gd: grid, units, movement, combat, building, turns, and income.
- docs/mobile-notes.md: next steps for Android/iOS export setup.
