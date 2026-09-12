# Henry's Boats

<!-- aidevops:badges:start -->
<!-- managed by aidevops badges; edit the template, not this block -->
<!-- Build & Quality Status -->

<!-- License & Legal -->
[![License](https://img.shields.io/badge/license-see%20file-yellow.svg)](https://github.com/superdav42/henrys-boats/blob/main/LICENSE)

<!-- Repository Metrics -->
[![Lines of code](docs/metrics/badges/loc.svg)](docs/metrics/repo-metrics.md)
[![Languages by lines of code](docs/metrics/badges/languages.svg)](docs/metrics/repo-metrics.md)
[![Dependencies](docs/metrics/badges/dependencies.svg)](docs/metrics/repo-metrics.md)

<!-- Project Links -->
[![GitHub repository](https://img.shields.io/badge/github-repository-181717.svg?logo=github)](https://github.com/superdav42/henrys-boats)
<!-- aidevops:badges:end -->

A Godot 4.7 2D mobile prototype for a turn-based boat combat game on a water grid.

## Current gameplay

- Tap one of your blue boats to select it.
- Win by capturing the enemy port or destroying every enemy unit.
- Tap an empty water square to move within that unit's movement range. Mountains are land tiles that only air units can enter.
- Tap a red enemy unit while one of your units is selected to attack.
- Coral reefs give water units 1 defense, reducing incoming damage by 1. Air units only receive defense on mountains, which give 2 defense.
- Your corner port can build Patrol Boats, Destroyers, Aircraft Carriers, and Anti-Air Boats.
- The Aircraft Carrier, or AC, can launch Jets, Fighters, and Bombers when selected.
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
- Anti-Air Boat/AAB: long-range air defense; it cannot attack boats and deals 4 damage to aircraft.
- Jet/JET: fast air unit that can attack any unit.
- Fighter/FIG: air unit that can only attack aircraft.
- Bomber/BMB: hard-hitting air unit that cannot attack aircraft.

## Project layout

- project.godot: mobile-oriented project settings.
- scenes/main.tscn: main game scene.
- scripts/main.gd: grid, units, movement, combat, building, turns, and income.
- docs/mobile-notes.md: next steps for Android/iOS export setup.

<!-- aidevops:managed-readme:start -->
<!-- managed by aidevops; refresh with managed-readme-helper.sh sync -->
## Star History

![superdav42/henrys-boats stars over time](docs/assets/star-history.svg)

## Built with aidevops

This project was created and is maintained with
[aidevops.sh](https://aidevops.sh).

[View superdav42 on GitHub](https://github.com/superdav42) ·
[aidevops repository](https://github.com/marcusquinn/aidevops)
<!-- aidevops:managed-readme:end -->
